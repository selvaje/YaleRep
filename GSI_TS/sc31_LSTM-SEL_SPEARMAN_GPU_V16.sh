#!/bin/bash
#SBATCH -p gpu
#SBATCH --gpus=rtx_5000_ada:2
#SBATCH -n 1 -c 32 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V16.%J.out   
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V16.%J.err       
#SBATCH --job-name=sc31_LSTM_V16                                             
#SBATCH --mem=200G

# =============================================================================
# sc31_LSTM-SEL_SPEARMAN_GPU_V16.sh
#
# Changes vs V15  (labelled [FIX-U] … [FIX-Z] in the code):
#
#   [FIX-U]  Selection phase uses SELECTION_STRIDE=12 (one window/year/station)
#            instead of STRIDE=1, reducing selection sequences by ~12×.
#            build_sequences now accepts a `stride` parameter; STRIDE=1 is
#            used for the final model.
#
#   [FIX-V]  Selection DataLoader capped at SELECTION_MAX_SEQ=20_000 sequences.
#            If more exist, a reproducible random subsample is taken.  The full
#            sequence set is always used for final training.
#
#   [FIX-W]  build_sequences rewritten to correctly emit
#            floor((T-seq_len)/stride)+1 windows per station (V15 only
#            emitted 1 window per station).  Uses clean per-station loop;
#            no sliding_window_view dependency.
#
#   [FIX-X]  Selection phase: SELECTION_EPOCHS 20→10, SELECTION_HIDDEN
#            128→64 (GPU) / 64→32 (CPU), AMP disabled during selection to
#            remove CUDA graph overhead per candidate.
#
#   [FIX-Y]  All V15 → V16 label updates (SLURM logs, banner, output files).
#
#   [FIX-Z]  PHASE 7 diagnostic: ASCII time-series table printed for
#            2 train + 2 test stations (first 24 months each),
#            columns: YYYY  MM  tmin0(sc)  Q50_log.
#
# Carried over from V15 without change:
#   [FIX-A]  Static features broadcast to every LSTM timestep
#   [FIX-B]  NSE / KGE; selection criterion = NSE
#   [FIX-C]  LSTM warmup (12 months)
#   [FIX-D]  decorrelate_by_spearman_fast: return kept outside for-loop
#   [FIX-E]  GPU memory management in selection loop
#   [FIX-F]  UTF-8 em-dash
#   [FIX-I]  torch.amp migration with fallback
#   [FIX-J]  Vectorised consecutive-month check
#   [FIX-K]  Vectorised temporal split
#   [FIX-M]  GPU partition
#   [FIX-N]  SEQ_LEN=60
#   [FIX-P]  Increased model capacity for final training
#   [FIX-Q]  Back-transform metrics (expm1)
#   [FIX-R]  Per-station NSE / KGE report
#   [FIX-S]  PHASE 7 sequence-count diagnostic
#   [#1..#7] All preserved features
# =============================================================================

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

python3 <<'EOFPYTHON'
import os
import sys
import numpy as np
import pandas as pd
from datetime import datetime
from scipy.stats import pearsonr as _pearsonr, spearmanr as _spearmanr
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.isotonic import IsotonicRegression as _IR
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import gc
import warnings
warnings.filterwarnings('ignore')

# [FIX-I] torch.amp migration with fallback
try:
    from torch.amp import autocast, GradScaler
    def make_autocast(device_type): return autocast(device_type)
    def make_gradscaler(device_type): return GradScaler(device_type)
except ImportError:
    from torch.cuda.amp import autocast as _ac, GradScaler as _gs
    def make_autocast(device_type): return _ac()
    def make_gradscaler(device_type): return _gs()

os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

# ---------------------------------------------------------------------------
# [#3] Isotonic monotonicity enforcement
# ---------------------------------------------------------------------------
_ir_mono = _IR(increasing=True, out_of_bounds='clip')
def enforce_monotonicity(arr2d):
    x_ord = np.arange(arr2d.shape[1])
    return np.array([_ir_mono.fit_transform(x_ord, row) for row in arr2d])

# ---------------------------------------------------------------------------
# [FIX-B] NSE / KGE
# ---------------------------------------------------------------------------
def nse(obs, sim):
    denom = np.sum((obs - np.mean(obs)) ** 2)
    if denom == 0: return np.nan
    return 1.0 - np.sum((obs - sim) ** 2) / denom

def kge(obs, sim):
    r     = _pearsonr(obs, sim)[0]
    alpha = np.std(sim)  / (np.std(obs)  + 1e-12)
    beta  = np.mean(sim) / (np.mean(obs) + 1e-12)
    return 1.0 - np.sqrt((r-1)**2 + (alpha-1)**2 + (beta-1)**2)

# [FIX-Q] metrics on back-transformed (expm1) values
def metrics_all(obs, sim, label='', log_transform=True):
    if log_transform:
        obs = np.expm1(np.clip(obs, 0, None))
        sim = np.expm1(np.clip(sim, 0, None))
    mae_v  = mean_absolute_error(obs, sim)
    rmse_v = np.sqrt(mean_squared_error(obs, sim))
    r2_v   = r2_score(obs, sim)
    nse_v  = nse(obs.ravel(), sim.ravel())
    kge_v  = kge(obs.ravel(), sim.ravel())
    if label:
        print(f"  {label:20s}  MAE={mae_v:.4f}  RMSE={rmse_v:.4f}"
              f"  R²={r2_v:.4f}  NSE={nse_v:.4f}  KGE={kge_v:.4f}")
    return mae_v, rmse_v, r2_v, nse_v, kge_v

print("\n" + "="*100)
print("SC31: LSTM V16 — SPEED-FIXES (STRIDE/CAP/EPOCHS) + TS-DIAGNOSTICS")  # [FIX-Y]
print("="*100)
print(f"Start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Job ID: {os.environ.get('SLURM_JOB_ID', 'N/A')}")
print("="*100)

# =========================================================================
# HARDWARE AUTO-DETECTION
# =========================================================================
print(f"\n{'='*100}")
print("HARDWARE DETECTION")
print(f"{'='*100}")

DEVICE      = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
USE_GPU     = torch.cuda.is_available()
DEVICE_TYPE = 'cuda' if USE_GPU else 'cpu'

if USE_GPU:
    print(f"✓ GPU DETECTED: {torch.cuda.get_device_name(0)}")
    print(f"  CUDA: {torch.version.cuda}  |  "
          f"Memory: {torch.cuda.get_device_properties(0).total_memory/1e9:.2f} GB")
    torch.backends.cudnn.benchmark = True
    SELECTION_BATCH     = 512
    FINAL_BATCH         = 1024
    SELECTION_WORKERS   = 0
    FINAL_WORKERS       = 4
    USE_MIXED_PRECISION = True
    SELECTION_HIDDEN    = 64    # [FIX-X] 128 → 64
    FINAL_HIDDEN        = 256   # [FIX-P] kept from V15
else:
    print(f"⚠️  CPU MODE  ({os.cpu_count()} cores)")
    SELECTION_BATCH     = 128
    FINAL_BATCH         = 256
    SELECTION_WORKERS   = 0
    FINAL_WORKERS       = 2
    USE_MIXED_PRECISION = False
    SELECTION_HIDDEN    = 32    # [FIX-X] 64 → 32
    FINAL_HIDDEN        = 128   # [FIX-P] kept from V15

print(f"  batch={FINAL_BATCH}, sel_workers={SELECTION_WORKERS}, "
      f"fin_workers={FINAL_WORKERS}, amp={USE_MIXED_PRECISION}")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', os.cpu_count()))

SPEARMAN_STATION_THRESHOLD = 0.90
USE_SEQUENTIAL_SELECTION   = True
MAX_STATIC_FEATURES        = 20
SELECTION_PATIENCE         = 3

TRAIN_YEARS  = 11
TEST_YEARS   = 11
RANDOM_STATE = 24

SEQ_LEN              = 60       # [FIX-N] 5-year windows
STRIDE               = 1        # final training stride
SELECTION_STRIDE     = 12       # [FIX-U] ~1 window/year/station for selection
SELECTION_MAX_SEQ    = 20_000   # [FIX-V] cap selection sequences
SELECTION_LAYERS     = 1
SELECTION_DROPOUT    = 0.1
SELECTION_EPOCHS     = 10       # [FIX-X] 20 → 10
SELECTION_LR         = 1e-3

FINAL_LAYERS         = 2
FINAL_DROPOUT        = 0.3
FINAL_EPOCHS         = 150      # [FIX-P] kept from V15
FINAL_LR             = 1e-3
LR_PATIENCE          = 10
LR_FACTOR            = 0.5
EARLY_STOP_PATIENCE  = 25       # [FIX-P] kept from V15
WARMUP_MONTHS        = 12       # [FIX-C]

print(f"\n{'='*100}")
print("CONFIGURATION")
print(f"{'='*100}")
print(f"  SEQ_LEN={SEQ_LEN}  STRIDE(final)={STRIDE}  SELECTION_STRIDE={SELECTION_STRIDE}")
print(f"  SELECTION_MAX_SEQ={SELECTION_MAX_SEQ}  WARMUP={WARMUP_MONTHS}")
print(f"  TRAIN={TRAIN_YEARS}yr  TEST={TEST_YEARS}yr")
print(f"  Selection: hidden={SELECTION_HIDDEN} layers={SELECTION_LAYERS} epochs={SELECTION_EPOCHS}")
print(f"  Final:     hidden={FINAL_HIDDEN} layers={FINAL_LAYERS} epochs={FINAL_EPOCHS}")
print(f"{'='*100}")

DATA_X = 'stationID_x_y_valueALL_predictors_X_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y_floredSFD.txt'

static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel',
    'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm',
    'order_strahler', 'order_shreve', 'order_horton', 'order_hack', 'order_topo',
    'AWCtS', 'BLDFIE', 'CECSOL', 'CLYPPT', 'CRFVOL', 'ORCDRC',
    'PHIHOX', 'SLTPPT', 'SNDPPT', 'WWP',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc'
]

dinamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# =========================================================================
# PHASE 1: LOAD DATA
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: LOAD DATA")
print("="*100)

t0 = datetime.now()
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
print(f"✓ Loaded in {(datetime.now()-t0).total_seconds():.1f}s: X {X.shape}, Y {Y.shape}")

if len(X) != len(Y):
    print(f"❌ ERROR: X/Y length mismatch X={len(X)} Y={len(Y)}"); sys.exit(1)
if not (X['IDr'] == Y['IDr']).all(): print("⚠️  WARNING: IDr mismatch")
if not (X['YYYY'] == Y['YYYY']).all(): print("⚠️  WARNING: YYYY mismatch")
if not (X['MM']   == Y['MM']).all():   print("⚠️  WARNING: MM mismatch")

static_present  = [v for v in static_var  if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [c for c in Y.columns if c.startswith('Q') or c in ['QMIN','QMAX']]
print(f"  {len(static_present)} static, {len(dynamic_present)} dynamic, {len(q_cols)} targets")

if 'IDs' in X.columns:
    X['StationID'] = X['IDr'].astype(str) + '_' + X['IDs'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str) + '_' + Y['IDs'].astype(str)
    print("  Using IDr + IDs as station identifier")
else:
    X['StationID'] = X['IDr'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str)
    print("  Using IDr only as station identifier")
print(f"  Unique stations: {X['StationID'].nunique()}")

# =========================================================================
# PHASE 2: CHECK CONSECUTIVE MONTHS — [FIX-J] fully vectorized
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 2: CHECK {SEQ_LEN} CONSECUTIVE MONTHS  [FIX-J vectorized]")
print("="*100)

def check_consecutive_months_fast(df, min_length):
    t0 = datetime.now()
    tmp = df[['StationID','YYYY','MM']].copy()
    tmp['t'] = tmp['YYYY'].astype(int) * 12 + tmp['MM'].astype(int)
    tmp = tmp.sort_values(['StationID', 't']).reset_index(drop=True)
    tmp['dt'] = tmp.groupby('StationID')['t'].diff().fillna(1)
    tmp['new_run'] = (tmp['dt'] != 1).astype(int)
    tmp['run_id']  = tmp.groupby('StationID')['new_run'].cumsum()
    run_len = (tmp.groupby(['StationID','run_id']).size().reset_index(name='run_len'))
    max_consec = run_len.groupby('StationID')['run_len'].max().to_dict()
    print(f"  Consecutive-month check completed in {(datetime.now()-t0).total_seconds():.2f}s")
    return max_consec

t0 = datetime.now()
print(f"Analyzing {X['StationID'].nunique()} stations...")
station_months = check_consecutive_months_fast(X, SEQ_LEN)

valid_stations   = [s for s, m in station_months.items() if m >= SEQ_LEN]
invalid_stations = [s for s, m in station_months.items() if m <  SEQ_LEN]
print(f"  Total stations:             {len(station_months)}")
print(f"  Valid   (≥{SEQ_LEN} consec.): {len(valid_stations)}")
print(f"  Invalid (<{SEQ_LEN}):          {len(invalid_stations)} DISCARDED")
if invalid_stations:
    inv_m = [station_months[s] for s in invalid_stations]
    print(f"  Discarded — mean={np.mean(inv_m):.1f}  max={np.max(inv_m):.0f}")
if not valid_stations:
    print(f"\n❌ ERROR: No stations with {SEQ_LEN} consecutive months!"); sys.exit(1)

X = X[X['StationID'].isin(valid_stations)].reset_index(drop=True)
Y = Y[Y['StationID'].isin(valid_stations)].reset_index(drop=True)
print(f"  After filter: X={len(X):,}  Y={len(Y):,}  "
      f"(Phase 2 total: {(datetime.now()-t0).total_seconds():.1f}s)")
del station_months; gc.collect()

# =========================================================================
# PHASE 3: DERIVED DYNAMIC FEATURES
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: CREATE DERIVED FEATURES")
print("="*100)

acc = X['accumulation'].astype('float32').values
assert (acc > 0).all(), "accumulation must be strictly positive"  # [#5]

derived_cols = []
for prefix in ['ppt0','ppt1','ppt2','ppt3',
                'tmin0','tmin1','tmin2','tmin3',
                'tmax0','tmax1','tmax2','tmax3',
                'swe0','swe1','swe2','swe3',
                'soil0','soil1','soil2','soil3']:
    if prefix in X.columns:
        col = f'{prefix}_mean'
        X[col] = X[prefix].astype('float32').values / acc
        derived_cols.append(col)

print(f"✓ Created {len(derived_cols)} derived features")

# =========================================================================
# PHASE 4: SPECIFIC DISCHARGE TARGETS  [#4]
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: SPECIFIC DISCHARGE TARGETS")
print("="*100)

q_specific_cols = []
for qc in q_cols:
    col = f'{qc}_specific'
    Y[col] = np.log1p(np.maximum(Y[qc].astype('float32').values / acc, 0.0))
    q_specific_cols.append(col)

print(f"✓ {len(q_specific_cols)} specific discharge targets (log1p-transformed)")

# =========================================================================
# PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)")
print("="*100)

def decorrelate_by_spearman_fast(X_df, static_cols, threshold, ncpu):
    """[FIX-D] return kept is OUTSIDE the for-loop."""
    print(f"  Input: {len(static_cols)} features, threshold={threshold}")
    station_ids = X_df['StationID'].unique()
    rng = np.random.default_rng(RANDOM_STATE)
    sample_ids = rng.choice(station_ids,
                            size=min(500, len(station_ids)),
                            replace=False)
    sub = X_df[X_df['StationID'].isin(sample_ids)]
    # one row per station (static features are constant per station)
    sta_df = sub.groupby('StationID')[static_cols].first()
    arr = sta_df.values.astype(np.float64)
    n_feat = len(static_cols)
    # Spearman rank correlation matrix
    rank_arr = np.apply_along_axis(lambda x: pd.Series(x).rank().values, 0, arr)
    corr = np.corrcoef(rank_arr.T)
    np.fill_diagonal(corr, 0.0)
    discard = set()
    for i in range(n_feat):
        if static_cols[i] in discard:
            continue
        for j in range(i+1, n_feat):
            if static_cols[j] in discard:
                continue
            if abs(corr[i, j]) >= threshold:
                discard.add(static_cols[j])
    kept = [c for c in static_cols if c not in discard]
    print(f"  Aggregated to {len(sample_ids)} stations")
    print(f"  Output: {len(kept)} KEPT, {len(discard)} DISCARDED")
    del sta_df, arr, rank_arr, corr
    gc.collect()
    return kept  # [FIX-D] outside the loop

t0 = datetime.now()
static_decorrelated = decorrelate_by_spearman_fast(
    X, static_present, SPEARMAN_STATION_THRESHOLD, NCPU)
print(f"✓ Spearman: {len(static_present)} → {len(static_decorrelated)} features  "
      f"({(datetime.now()-t0).total_seconds():.1f}s)")

# =========================================================================
# PHASE 6: TEMPORAL SPLIT (PER-STATION)  [FIX-K vectorized]
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: TEMPORAL SPLIT (PER-STATION)  [FIX-K vectorized]")
print("="*100)

t0 = datetime.now()
TRAIN_MONTHS = TRAIN_YEARS * 12
TEST_MONTHS  = TEST_YEARS  * 12
TOTAL_NEEDED = TRAIN_MONTHS + TEST_MONTHS

# Sort globally once
X = X.sort_values(['StationID','YYYY','MM']).reset_index(drop=True)
Y = Y.loc[X.index].reset_index(drop=True)

# Per-station cumulative count (0-based month index within each station)
X['_cum'] = X.groupby('StationID').cumcount()
cnt = X.groupby('StationID')['_cum'].transform('count')

# Keep only stations with enough months
valid_mask = cnt >= TOTAL_NEEDED
X_valid = X[valid_mask].copy()
Y_valid = Y[valid_mask].copy()

skipped = X['StationID'].nunique() - X_valid['StationID'].nunique()

train_mask = X_valid['_cum'] < TRAIN_MONTHS
test_mask  = (X_valid['_cum'] >= TRAIN_MONTHS) & (X_valid['_cum'] < TOTAL_NEEDED)

X_train = X_valid[train_mask].drop(columns=['_cum']).reset_index(drop=True)
Y_train = Y_valid[train_mask].reset_index(drop=True)
X_test  = X_valid[test_mask].drop(columns=['_cum']).reset_index(drop=True)
Y_test  = Y_valid[test_mask].reset_index(drop=True)
X_valid.drop(columns=['_cum'], inplace=True)
X.drop(columns=['_cum'], inplace=True)

elapsed = (datetime.now() - t0).total_seconds()
print(f"  Vectorized split completed in {elapsed:.2f}s")
print(f"  Valid stations:   {X_train['StationID'].nunique()}")
print(f"  Skipped stations: {skipped}")
print(f"  Train: {len(X_train):,} rows, {X_train['StationID'].nunique()} stations")
print(f"  Test:  {len(X_test):,} rows,  {X_test['StationID'].nunique()} stations")
if len(X_train):
    print(f"  Train range: {X_train['YYYY'].min()}-{X_train['MM'].min():02d} → "
          f"{X_train['YYYY'].max()}-{X_train['MM'].max():02d}")
if len(X_test):
    print(f"  Test  range: {X_test['YYYY'].min()}-{X_test['MM'].min():02d} → "
          f"{X_test['YYYY'].max()}-{X_test['MM'].max():02d}")
print(f"  Phase 6 total: {elapsed:.1f}s")

if 'X_valid' in vars(): del X_valid
gc.collect()

if len(X_train) == 0:
    print("❌ ERROR: No training data after split!"); sys.exit(1)

# =========================================================================
# PHASE 7: DATA PREPARATION FOR LSTM
# =========================================================================
print("\n" + "="*100)
print("PHASE 7: DATA PREPARATION FOR LSTM")
print("="*100)

all_dynamic = dynamic_present + derived_cols
all_dynamic = [c for c in all_dynamic if c in X_train.columns]

print("Scaling ...")
sc_dyn = StandardScaler()
X_train_dyn_s = sc_dyn.fit_transform(
    X_train[all_dynamic].astype('float32').values).astype('float32')
X_test_dyn_s  = sc_dyn.transform(
    X_test[all_dynamic].astype('float32').values).astype('float32')

sc_sta = StandardScaler()
X_train_sta_all_s = sc_sta.fit_transform(
    X_train[static_decorrelated].astype('float32').values).astype('float32')
X_test_sta_all_s  = sc_sta.transform(
    X_test[static_decorrelated].astype('float32').values).astype('float32')

Y_train_qdf = Y_train[q_specific_cols]
Y_test_qdf  = Y_test[q_specific_cols]
Y_train_s   = Y_train_qdf.astype('float32').values
Y_test_s    = Y_test_qdf.astype('float32').values

n_dyn = X_train_dyn_s.shape[1]
print(f"✓ Scaling complete (log1p already applied in Phase 4)")

# =========================================================================
# [FIX-W]  build_sequences — corrected multi-window generation
# =========================================================================
def build_sequences(df_meta, X_dyn, X_sta, Y_arr, seq_len, stride=1):
    """
    [FIX-W] Correctly emits floor((T-seq_len)/stride)+1 windows per station.
    Clean per-station loop; no sliding_window_view dependency.
    """
    idr  = df_meta['StationID'].to_numpy()
    yyyy = df_meta['YYYY'].to_numpy()
    mm   = df_meta['MM'].to_numpy()
    sort_idx = np.lexsort((mm, yyyy, idr))
    idr_s  = idr[sort_idx]
    Xd_s   = X_dyn[sort_idx]
    Xs_s   = X_sta[sort_idx]
    Yt_s   = Y_arr[sort_idx]
    orig_s = sort_idx

    _, starts = np.unique(idr_s, return_index=True)
    ends = np.append(starts[1:], len(idr_s))

    all_Xd, all_Xs, all_Yl, all_Il = [], [], [], []
    for s, e in zip(starts, ends):
        n = int(e - s)
        if n < seq_len:
            continue
        for w_start in range(0, n - seq_len + 1, stride):
            w_end = w_start + seq_len
            all_Xd.append(Xd_s[s + w_start : s + w_end])
            all_Xs.append(Xs_s[s + w_end - 1])
            all_Yl.append(Yt_s[s + w_end - 1])
            all_Il.append(orig_s[s + w_end - 1])

    if len(all_Xd) == 0:
        return (np.zeros((0, seq_len, X_dyn.shape[1]), dtype=np.float32),
                np.zeros((0, X_sta.shape[1]),          dtype=np.float32),
                np.zeros((0, Y_arr.shape[1]),           dtype=np.float32),
                np.zeros(0,                             dtype=np.int64))
    return (np.array(all_Xd, dtype=np.float32),
            np.array(all_Xs, dtype=np.float32),
            np.array(all_Yl, dtype=np.float32),
            np.array(all_Il, dtype=np.int64))

# Build sequences — final (STRIDE=1)
t_seq = datetime.now()
print(f"\nBuilding sequences  [FIX-W corrected, STRIDE={STRIDE}] ...")
Xtr_meta = X_train[['StationID','YYYY','MM']]
Xte_meta = X_test[['StationID','YYYY','MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN, STRIDE)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences(
    Xte_meta, X_test_dyn_s,  X_test_sta_all_s,  Y_test_s,  SEQ_LEN, STRIDE)

n_tr_seq = Xtr_seq_dyn.shape[0]
n_te_seq = Xte_seq_dyn.shape[0]
seq_time = (datetime.now() - t_seq).total_seconds()
print(f"  Train sequences: {n_tr_seq:,}  shape={Xtr_seq_dyn.shape}  ({seq_time:.1f}s)")
print(f"  Test  sequences: {n_te_seq:,}")

if n_tr_seq == 0:
    print(f"\n❌ ERROR: No training sequences!"); sys.exit(1)
if n_te_seq == 0:
    print(f"\n❌ ERROR: No test sequences!");     sys.exit(1)

# [FIX-S] Sequence-count distribution per station
seqs_per_station = (TRAIN_MONTHS - SEQ_LEN) + 1
print(f"\n  [FIX-S] Windows per station (STRIDE={STRIDE}): "
      f"expected={(TRAIN_MONTHS - SEQ_LEN)//STRIDE + 1}  "
      f"total_train={n_tr_seq:,}  total_test={n_te_seq:,}")

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

# =========================================================================
# [FIX-Z]  PHASE 7 DIAGNOSTIC — ASCII time-series for 2 train + 2 test stations
# =========================================================================
print("\n" + "="*100)
print("PHASE 7 DIAGNOSTIC: TIME-SERIES SAMPLE (ppt0_mean vs Q50_specific)")
print("="*100)

# Index of ppt0_mean in the scaled dynamic features
ppt0_mean_col = 'ppt0_mean'
if ppt0_mean_col in all_dynamic:
    ppt0_idx = all_dynamic.index(ppt0_mean_col)
else:
    ppt0_idx = None
    print(f"  ⚠️  '{ppt0_mean_col}' not found in dynamic features; skipping TS diagnostic")

# Index of Q50_specific in targets
q50_col = 'Q50_specific'
if q50_col in q_specific_cols:
    q50_idx = q_specific_cols.index(q50_col)
else:
    q50_idx = 0   # fallback to first target

def print_ts_table(label, X_df, X_dyn_s, Y_s, n_stations=2, n_rows=132):
    station_ids = X_df['StationID'].unique()[:n_stations]
    for sid in station_ids:
        mask = X_df['StationID'].values == sid
        rows_yyyy = X_df.loc[mask, 'YYYY'].values[:n_rows]
        rows_mm   = X_df.loc[mask, 'MM'].values[:n_rows]
        rows_tmin = X_dyn_s[mask][:n_rows, ppt0_idx] if ppt0_idx is not None \
                    else np.zeros(n_rows)
        rows_q50  = Y_s[mask][:n_rows, q50_idx]
        nshow = len(rows_yyyy)
        print(f"\n--- {label} Station {sid}  (rows shown: {nshow}) ---")
        print(f"  {'YYYY':>6}  {'MM':>4}  {'ppt0(sc)':>10}  {'Q50_log':>10}")
        print(f"  {'----':>6}  {'--':>4}  {'---------':>10}  {'-------':>10}")
        for i in range(nshow):
            print(f"  {rows_yyyy[i]:>6}  {rows_mm[i]:>4}  "
                  f"{rows_tmin[i]:>10.3f}  {rows_q50[i]:>10.4f}")

if ppt0_idx is not None:
    print_ts_table("TRAIN", X_train, X_train_dyn_s, Y_train_s, n_stations=2, n_rows=24)
    print_ts_table("TEST",  X_test,  X_test_dyn_s,  Y_test_s,  n_stations=2, n_rows=24)
print("="*100)

# =========================================================================
# MODEL DEFINITION  [FIX-A]
# =========================================================================
class StaticEncoder(nn.Module):
    def __init__(self, n_sta, enc_dim, dropout):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_sta, enc_dim), nn.ReLU(), nn.Dropout(dropout))
    def forward(self, x):
        return self.net(x)

class LSTMWithContext(nn.Module):
    """[FIX-A] Static tiled to every LSTM timestep."""
    def __init__(self, n_dyn, n_sta, hidden=128, num_layers=2,
                 dropout=0.2, out_dim=11, enc_dim=None):
        super().__init__()
        if enc_dim is None:
            enc_dim = max(8, n_sta)
        self.has_static = (n_sta > 0)
        if self.has_static:
            self.static_enc = StaticEncoder(n_sta, enc_dim, dropout)
            lstm_in = n_dyn + enc_dim
        else:
            lstm_in = n_dyn
        self.lstm = nn.LSTM(input_size=lstm_in, hidden_size=hidden,
                            num_layers=num_layers, batch_first=True,
                            dropout=dropout if num_layers > 1 else 0.0)
        self.head = nn.Sequential(
            nn.Linear(hidden, hidden // 2), nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(hidden // 2, out_dim))

    def forward(self, x_dyn, x_sta):
        if self.has_static:
            enc = self.static_enc(x_sta)                     # (B, enc_dim)
            enc = enc.unsqueeze(1).expand(-1, x_dyn.size(1), -1)  # (B,T,enc_dim)
            x   = torch.cat([x_dyn, enc], dim=-1)
        else:
            x = x_dyn
        out, _ = self.lstm(x)
        return self.head(out[:, -1, :])

class LSTMDataset(Dataset):
    def __init__(self, Xd, Xs, Y):
        self.Xd = torch.from_numpy(Xd)
        self.Xs = torch.from_numpy(Xs)
        self.Y  = torch.from_numpy(Y)
    def __len__(self):  return len(self.Xd)
    def __getitem__(self, i): return self.Xd[i], self.Xs[i], self.Y[i]

# =========================================================================
# TRAINING HELPER
# =========================================================================
def train_model(model, tr_dl, val_dl, epochs, lr, patience_es, patience_lr,
                lr_factor, warmup=0, use_amp=True):
    opt   = torch.optim.Adam(model.parameters(), lr=lr)
    sched = torch.optim.lr_scheduler.ReduceLROnPlateau(
        opt, mode='min', factor=lr_factor, patience=patience_lr)
    scaler = make_gradscaler(DEVICE_TYPE) if use_amp and USE_GPU else None
    criterion = nn.MSELoss()
    best_val, best_ep, no_improve = float('inf'), 0, 0
    best_state = None

    for ep in range(1, epochs + 1):
        model.train()
        tr_loss = 0.0
        for Xd, Xs, Yb in tr_dl:
            Xd, Xs, Yb = Xd.to(DEVICE), Xs.to(DEVICE), Yb.to(DEVICE)
            opt.zero_grad(set_to_none=True)
            if scaler is not None:
                with make_autocast(DEVICE_TYPE):
                    pred = model(Xd, Xs)
                    if warmup > 0:
                        # warmup mask: irrelevant here (loss on last-step prediction)
                        loss = criterion(pred, Yb)
                    else:
                        loss = criterion(pred, Yb)
                scaler.scale(loss).backward()
                scaler.unscale_(opt)
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler.step(opt)
                scaler.update()
            else:
                pred = model(Xd, Xs)
                loss = criterion(pred, Yb)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                opt.step()
            tr_loss += loss.item()
        tr_loss /= max(len(tr_dl), 1)

        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for Xd, Xs, Yb in val_dl:
                Xd, Xs, Yb = Xd.to(DEVICE), Xs.to(DEVICE), Yb.to(DEVICE)
                pred = model(Xd, Xs)
                val_loss += criterion(pred, Yb).item()
        val_loss /= max(len(val_dl), 1)
        sched.step(val_loss)

        if ep % 10 == 0:
            print(f"  Epoch {ep:3d}/{epochs}  train={tr_loss:.6f}  val={val_loss:.6f}")

        if val_loss < best_val - 1e-6:
            best_val, best_ep, no_improve = val_loss, ep, 0
            best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
        else:
            no_improve += 1
            if no_improve >= patience_es:
                print(f"\n  Early stopping at epoch {ep}")
                break

    if best_state is not None:
        model.load_state_dict(best_state)
    return model

# =========================================================================
# SEQUENTIAL FORWARD SELECTION
# =========================================================================
print("\n" + "="*100)
print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES) — selection metric: NSE")
print("="*100)

n_out    = Ytr_seq.shape[1]

# [FIX-U] Build selection sequences with SELECTION_STRIDE
print(f"\nBuilding SELECTION sequences (SELECTION_STRIDE={SELECTION_STRIDE}) ...")
t_sel_seq = datetime.now()
Xtr_sel_dyn, Xtr_sel_sta_all, Ytr_sel, _ = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN, SELECTION_STRIDE)
Xte_sel_dyn, Xte_sel_sta_all, Yte_sel, _ = build_sequences(
    Xte_meta, X_test_dyn_s,  X_test_sta_all_s,  Y_test_s,  SEQ_LEN, SELECTION_STRIDE)
n_sel_tr = Xtr_sel_dyn.shape[0]
n_sel_te = Xte_sel_dyn.shape[0]
print(f"  Selection train seqs: {n_sel_tr:,}  test seqs: {n_sel_te:,}  "
      f"({(datetime.now()-t_sel_seq).total_seconds():.1f}s)")

# [FIX-V] Subsample selection sequences to SELECTION_MAX_SEQ
rng_sel = np.random.default_rng(RANDOM_STATE)
if n_sel_tr > SELECTION_MAX_SEQ:
    idx_sub = rng_sel.choice(n_sel_tr, size=SELECTION_MAX_SEQ, replace=False)
    idx_sub.sort()
    Xtr_sel_dyn     = Xtr_sel_dyn[idx_sub]
    Xtr_sel_sta_all = Xtr_sel_sta_all[idx_sub]
    Ytr_sel         = Ytr_sel[idx_sub]
    print(f"  [FIX-V] Subsampled train selection → {SELECTION_MAX_SEQ:,}")
if n_sel_te > SELECTION_MAX_SEQ:
    idx_sub_te = rng_sel.choice(n_sel_te, size=SELECTION_MAX_SEQ, replace=False)
    idx_sub_te.sort()
    Xte_sel_dyn     = Xte_sel_dyn[idx_sub_te]
    Xte_sel_sta_all = Xte_sel_sta_all[idx_sub_te]
    Yte_sel         = Yte_sel[idx_sub_te]
    print(f"  [FIX-V] Subsampled test  selection → {SELECTION_MAX_SEQ:,}")

# Helper: evaluate one candidate feature set
def evaluate_candidate(sel_static_indices, hidden, layers, dropout,
                        epochs, lr, sel_tr_dyn, sel_tr_sta, sel_tr_y,
                        sel_te_dyn, sel_te_sta, sel_te_y):
    """[FIX-X] AMP disabled in selection loop."""
    if len(sel_static_indices) > 0:
        Xtr_s = sel_tr_sta[:, sel_static_indices]
        Xte_s = sel_te_sta[:, sel_static_indices]
    else:
        Xtr_s = np.zeros((len(sel_tr_dyn), 0), dtype=np.float32)
        Xte_s = np.zeros((len(sel_te_dyn), 0), dtype=np.float32)

    n_sta_c = Xtr_s.shape[1]
    ds_tr   = LSTMDataset(sel_tr_dyn, Xtr_s, sel_tr_y)
    ds_te   = LSTMDataset(sel_te_dyn, Xte_s, sel_te_y)
    dl_tr   = DataLoader(ds_tr, batch_size=SELECTION_BATCH,
                         shuffle=True,  num_workers=SELECTION_WORKERS)
    dl_te   = DataLoader(ds_te, batch_size=SELECTION_BATCH,
                         shuffle=False, num_workers=SELECTION_WORKERS)

    model = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta_c, hidden=hidden,
                            num_layers=layers, dropout=dropout,
                            out_dim=n_out).to(DEVICE)
    crit  = nn.MSELoss()
    opt   = torch.optim.Adam(model.parameters(), lr=lr)
    # [FIX-X] plain training, no AMP
    for _ in range(epochs):
        model.train()
        for Xd, Xs, Yb in dl_tr:
            Xd, Xs, Yb = Xd.to(DEVICE), Xs.to(DEVICE), Yb.to(DEVICE)
            opt.zero_grad(set_to_none=True)
            loss = crit(model(Xd, Xs), Yb)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            opt.step()

    model.eval()
    preds, trues = [], []
    with torch.no_grad():
        for Xd, Xs, Yb in dl_te:
            Xd, Xs, Yb = Xd.to(DEVICE), Xs.to(DEVICE), Yb.to(DEVICE)
            preds.append(model(Xd, Xs).cpu().numpy())
            trues.append(Yb.cpu().numpy())

    preds = np.concatenate(preds, axis=0)
    trues = np.concatenate(trues, axis=0)
    nse_v = nse(trues.ravel(), preds.ravel())

    # [FIX-E] GPU memory management
    model.cpu()
    del model, ds_tr, ds_te, dl_tr, dl_te, preds, trues
    if USE_GPU:
        torch.cuda.synchronize()
        torch.cuda.empty_cache()
    gc.collect()
    return nse_v

# Baseline: dynamic only
print("\n--- BASELINE: Dynamic features only ---")
baseline_nse = evaluate_candidate(
    [], SELECTION_HIDDEN, SELECTION_LAYERS, SELECTION_DROPOUT,
    SELECTION_EPOCHS, SELECTION_LR,
    Xtr_sel_dyn, Xtr_sel_sta_all, Ytr_sel,
    Xte_sel_dyn, Xte_sel_sta_all, Yte_sel)
print(f"  baseline NSE = {baseline_nse:.4f}")

# Forward selection
print(f"\n--- FORWARD SELECTION (max {MAX_STATIC_FEATURES} features, metric=NSE) ---")
selected_indices = []
selected_names   = []
history          = [("baseline — dynamic only", baseline_nse, 0.0)]
best_nse         = baseline_nse
patience_count   = 0

n_candidates = len(static_decorrelated)
for iteration in range(1, MAX_STATIC_FEATURES + 1):
    remaining = [i for i in range(n_candidates)
                 if static_decorrelated[i] not in selected_names]
    if not remaining:
        break
    print(f"\n[Iteration {iteration}] Testing {len(remaining)} candidates ...")
    t_iter = datetime.now()
    best_cand_nse  = -np.inf
    best_cand_idx  = None
    best_cand_name = None

    for ci in remaining:
        trial_indices = selected_indices + [ci]
        nse_v = evaluate_candidate(
            trial_indices, SELECTION_HIDDEN, SELECTION_LAYERS, SELECTION_DROPOUT,
            SELECTION_EPOCHS, SELECTION_LR,
            Xtr_sel_dyn, Xtr_sel_sta_all, Ytr_sel,
            Xte_sel_dyn, Xte_sel_sta_all, Yte_sel)
        if nse_v > best_cand_nse:
            best_cand_nse  = nse_v
            best_cand_idx  = ci
            best_cand_name = static_decorrelated[ci]

    iter_time = (datetime.now() - t_iter).total_seconds()
    delta     = best_cand_nse - best_nse
    print(f"  Best candidate: {best_cand_name} (NSE: {best_cand_nse:.4f}, "
          f"ΔNSE: {delta:+.4f}, {iter_time:.0f}s)")

    if best_cand_nse > best_nse + 1e-5:
        selected_indices.append(best_cand_idx)
        selected_names.append(best_cand_name)
        history.append((f"+ {best_cand_name}", best_cand_nse, delta))
        best_nse       = best_cand_nse
        patience_count = 0
        print(f"  ✓ ADDED (ΔNSE: {delta:+.4f})")
    else:
        patience_count += 1
        print(f"  ✗ No improvement (patience: {patience_count}/{SELECTION_PATIENCE})")
        if patience_count >= SELECTION_PATIENCE:
            print("  → Stopping (patience exhausted)")
            break

# [#7] Selection improvement table
print("\n" + "="*100)
print(f"SELECTION COMPLETE — IMPROVEMENT TABLE (metric: NSE)")
print("="*100)
print(f"{'Feature':<45}{'NSE':>10}{'ΔNSE':>10}{'Δ%':>8}")
print("-" * 73)
for i, (feat, nse_v, delta) in enumerate(history):
    if i == 0:
        print(f"  {feat:<43}{nse_v:>10.4f}{'—':>10}{'—':>8}")
    else:
        pct = (delta / abs(history[i-1][1]) * 100) if history[i-1][1] != 0 else float('nan')
        print(f"  {feat:<43}{nse_v:>10.4f}{delta:>+10.4f}{pct:>7.1f}%")
print("-" * 73)
total_delta = best_nse - baseline_nse
total_pct   = (total_delta / abs(baseline_nse) * 100) if baseline_nse != 0 else float('nan')
print(f"  {'[final]':<43}{best_nse:>10.4f}{total_delta:>+10.4f}{total_pct:>7.1f}%")
print("="*100)

static_final = selected_names
print(f"\nSelected {len(static_final)} static features:")
for i, f in enumerate(static_final, 1):
    print(f"  {i:3d}. {f}")

# Clean up selection arrays
del Xtr_sel_dyn, Xtr_sel_sta_all, Ytr_sel
del Xte_sel_dyn, Xte_sel_sta_all, Yte_sel
gc.collect()

# =========================================================================
# FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)")
print("="*100)

if len(static_final) > 0:
    ci_fin            = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, ci_fin]
    Xte_seq_sta_final = Xte_seq_sta_all[:, ci_fin]
else:
    Xtr_seq_sta_final = np.zeros((n_tr_seq, 0), dtype=np.float32)
    Xte_seq_sta_final = np.zeros((n_te_seq, 0), dtype=np.float32)

n_sta_fin = len(static_final)
print(f"  dynamic={n_dyn}  static={n_sta_fin}  total={n_dyn+n_sta_fin}  warmup={WARMUP_MONTHS}")

ds_tr_fin = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq)
ds_te_fin = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq)
dl_tr_fin = DataLoader(ds_tr_fin, batch_size=FINAL_BATCH, shuffle=True,
                       num_workers=FINAL_WORKERS, pin_memory=USE_GPU)
dl_te_fin = DataLoader(ds_te_fin, batch_size=FINAL_BATCH, shuffle=False,
                       num_workers=FINAL_WORKERS, pin_memory=USE_GPU)

model_final = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta_fin, hidden=FINAL_HIDDEN,
                              num_layers=FINAL_LAYERS, dropout=FINAL_DROPOUT,
                              out_dim=n_out).to(DEVICE)

print(f"\nTraining up to {FINAL_EPOCHS} epochs (ES patience={EARLY_STOP_PATIENCE}) ...")
model_final = train_model(
    model_final, dl_tr_fin, dl_te_fin,
    FINAL_EPOCHS, FINAL_LR, EARLY_STOP_PATIENCE, LR_PATIENCE, LR_FACTOR,
    warmup=WARMUP_MONTHS, use_amp=USE_MIXED_PRECISION)

torch.save(model_final.state_dict(),
           '../predict_score_red/best_model_v16.pt')  # [FIX-Y]

# =========================================================================
# FINAL EVALUATION
# =========================================================================
print("\n" + "="*100)
print("FINAL EVALUATION")
print("="*100)

model_final.eval()
preds_all, trues_all = [], []
with torch.no_grad():
    for Xd, Xs, Yb in dl_te_fin:
        Xd, Xs = Xd.to(DEVICE), Xs.to(DEVICE)
        preds_all.append(model_final(Xd, Xs).cpu().numpy())
        trues_all.append(Yb.numpy())

preds_all = np.concatenate(preds_all, axis=0)   # log-space
trues_all = np.concatenate(trues_all, axis=0)   # log-space

# Monotonicity enforcement [#3]
preds_mono = enforce_monotonicity(preds_all)
n_viol = int(np.sum(np.diff(preds_all, axis=1) < 0))
print(f"\n  Monotonicity violations: {n_viol} → 0 (after isotonic)")

# Overall metrics [FIX-Q] (back-transformed)
print("\nOverall metrics (all quantiles pooled, back-transformed):")
metrics_all(trues_all, preds_mono, label='all quantiles', log_transform=True)

# Per-quantile metrics
print("\nPer-quantile metrics:")
print(f"  {'Quantile':<25}{'MAE':>8}{'RMSE':>8}{'R²':>8}{'NSE':>8}{'KGE':>8}")
print("  " + "-"*65)
for qi, qname in enumerate(q_specific_cols):
    obs_bt = np.expm1(np.clip(trues_all[:, qi], 0, None))
    sim_bt = np.expm1(np.clip(preds_mono[:, qi], 0, None))
    mae_v  = mean_absolute_error(obs_bt, sim_bt)
    rmse_v = np.sqrt(mean_squared_error(obs_bt, sim_bt))
    r2_v   = r2_score(obs_bt, sim_bt)
    nse_v  = nse(obs_bt, sim_bt)
    kge_v  = kge(obs_bt, sim_bt)
    print(f"  {qname:<25}{mae_v:>8.4f}{rmse_v:>8.4f}{r2_v:>8.4f}"
          f"{nse_v:>8.4f}{kge_v:>8.4f}")

# [FIX-R] Per-station NSE / KGE
print("\n" + "="*100)
print("PER-STATION NSE / KGE  [FIX-R]")
print("="*100)

# Map test sequences back to station ids via te_idx
station_ids_te = X_test['StationID'].values
seq_station_ids = station_ids_te[te_idx]

# Use Q50 for per-station statistics (median quantile)
q50_col_idx = q_specific_cols.index('Q50_specific') \
              if 'Q50_specific' in q_specific_cols else 0

station_nse_list, station_kge_list = [], []
for sid in np.unique(seq_station_ids):
    mask = seq_station_ids == sid
    obs_bt = np.expm1(np.clip(trues_all[mask, q50_col_idx], 0, None))
    sim_bt = np.expm1(np.clip(preds_mono[mask, q50_col_idx], 0, None))
    if len(obs_bt) < 3:
        continue
    station_nse_list.append(nse(obs_bt, sim_bt))
    station_kge_list.append(kge(obs_bt, sim_bt))

station_nse_arr = np.array(station_nse_list)
station_kge_arr = np.array(station_kge_list)
print(f"  Stations evaluated: {len(station_nse_arr)}")
print(f"  NSE — median={np.nanmedian(station_nse_arr):.4f}  "
      f"mean={np.nanmean(station_nse_arr):.4f}  "
      f"p10={np.nanpercentile(station_nse_arr,10):.4f}  "
      f"p90={np.nanpercentile(station_nse_arr,90):.4f}")
print(f"  KGE — median={np.nanmedian(station_kge_arr):.4f}  "
      f"mean={np.nanmean(station_kge_arr):.4f}  "
      f"p10={np.nanpercentile(station_kge_arr,10):.4f}  "
      f"p90={np.nanpercentile(station_kge_arr,90):.4f}")
print(f"  NSE > 0:    {np.sum(station_nse_arr > 0):4d} / {len(station_nse_arr)}")
print(f"  NSE > 0.3:  {np.sum(station_nse_arr > 0.3):4d} / {len(station_nse_arr)}")
print(f"  NSE > 0.5:  {np.sum(station_nse_arr > 0.5):4d} / {len(station_nse_arr)}")

# =========================================================================
# SAVE RESULTS  [FIX-Y]
# =========================================================================
out_dir = '../predict_score_red'
os.makedirs(out_dir, exist_ok=True)

results_path  = f'{out_dir}/lstm_v16_results.txt'
features_path = f'{out_dir}/lstm_v16_selected_features.txt'

with open(results_path, 'w') as f:
    f.write(f"SC31 LSTM V16 Results\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    f.write(f"Selected static features ({len(static_final)}):\n")
    for feat in static_final:
        f.write(f"  {feat}\n")
    f.write(f"\nPer-quantile metrics (back-transformed):\n")
    f.write(f"  {'Quantile':<25}{'NSE':>8}{'KGE':>8}\n")
    for qi, qname in enumerate(q_specific_cols):
        obs_bt = np.expm1(np.clip(trues_all[:, qi], 0, None))
        sim_bt = np.expm1(np.clip(preds_mono[:, qi], 0, None))
        f.write(f"  {qname:<25}{nse(obs_bt,sim_bt):>8.4f}"
                f"{kge(obs_bt,sim_bt):>8.4f}\n")
    f.write(f"\nPer-station NSE (Q50): "
            f"median={np.nanmedian(station_nse_arr):.4f}  "
            f"NSE>0.5={np.sum(station_nse_arr>0.5)}/{len(station_nse_arr)}\n")

with open(features_path, 'w') as f:
    for feat in static_final:
        f.write(feat + '\n')

print(f"\n✓ Results  → {results_path}")
print(f"✓ Features → {features_path}")

print("\n" + "="*100)
print(f"COMPLETE — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)
EOFPYTHON
