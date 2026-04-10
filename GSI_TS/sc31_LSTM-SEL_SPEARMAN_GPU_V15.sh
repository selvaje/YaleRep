#!/bin/bash
#SBATCH -p scavenge
####SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V15.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V15.err
#SBATCH --job-name=sc31_LSTM_V15
#SBATCH --mem=20G

# =============================================================================
# sc31_LSTM-SEL_SPEARMAN_GPU_V15.sh
#
# Changes vs V14  (labelled [FIX-M] … [FIX-T] in the code):
#
#   [FIX-M]  GPU partition enabled: -p gpu, --gpus=rtx_5000_ada:1, -t 6:00:00,
#            --mem=80G, log names updated to V15.
#
#   [FIX-N]  SEQ_LEN reduced 132 → 60 (5 years).  With TRAIN_YEARS=11 (132 mo)
#            and SEQ_LEN=60, each station contributes 132-60+1 = 73 sliding
#            windows instead of 1, giving ~350k training sequences vs 4,796.
#            STRIDE kept at 1.
#
#   [FIX-O]  build_sequences FIX: the FIX-L sliding_window_view path produced
#            only one window per station.  Completely rewritten using a clean
#            per-station loop with np.stack; sliding_window_view used where
#            available as an optimised path.  Now correctly returns all
#            floor((T-seq_len)/stride)+1 windows per station.
#
#   [FIX-P]  Model capacity increased now that sequences are plentiful:
#            Selection phase: SELECTION_HIDDEN 32→64 (CPU) / 64→128 (GPU),
#                             SELECTION_EPOCHS 15→20.
#            Final phase:     FINAL_HIDDEN 64→128 (CPU) / 128→256 (GPU),
#                             FINAL_EPOCHS 100→150,
#                             EARLY_STOP_PATIENCE 20→25.
#
#   [FIX-Q]  Metrics computed on back-transformed (expm1) values so that KGE β
#            reflects real discharge units, not log-space.  metrics_all now
#            applies expm1 before computing all metrics (log_transform=True).
#
#   [FIX-R]  Per-station NSE / KGE added to the final report:
#              - median, mean, 10th/90th percentile across stations
#              - count of stations with NSE > 0, > 0.3, > 0.5
#
#   [FIX-S]  PHASE 7 diagnostic table: after build_sequences print
#            sequences-per-station distribution (min/median/max/total).
#
#   [FIX-T]  Banner and file names updated to V15.
#
# Carried over from V14 without change:
#   [FIX-A..L]  all previous fixes
#   [#1..#7]    all preserved features
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
from scipy.stats import pearsonr as _pearsonr
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
    """Compute metrics; if log_transform=True apply expm1 first."""
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
print("SC31: LSTM V15 — SEQ60 + SLIDING-FIX + GPU + BACK-TRANSFORM-METRICS")  # [FIX-T]
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
    SELECTION_HIDDEN    = 128   # [FIX-P]
    FINAL_HIDDEN        = 256   # [FIX-P]
else:
    print(f"⚠️  CPU MODE  ({os.cpu_count()} cores)")
    SELECTION_BATCH     = 128
    FINAL_BATCH         = 256
    SELECTION_WORKERS   = 0
    FINAL_WORKERS       = 2
    USE_MIXED_PRECISION = False
    SELECTION_HIDDEN    = 64    # [FIX-P]
    FINAL_HIDDEN        = 128   # [FIX-P]

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

SEQ_LEN           = 60     # [FIX-N] 5 yr; 132-60+1=73 windows/station
STRIDE            = 1
SELECTION_LAYERS  = 1
SELECTION_DROPOUT = 0.1
SELECTION_EPOCHS  = 20     # [FIX-P]
SELECTION_LR      = 1e-3

FINAL_LAYERS        = 2
FINAL_DROPOUT       = 0.3
FINAL_EPOCHS        = 150   # [FIX-P]
FINAL_LR            = 1e-3
LR_PATIENCE         = 10
LR_FACTOR           = 0.5
EARLY_STOP_PATIENCE = 25    # [FIX-P]
WARMUP_MONTHS       = 12

print(f"\n{'='*100}")
print("CONFIGURATION")
print(f"{'='*100}")
print(f"  SEQ_LEN={SEQ_LEN}  STRIDE={STRIDE}  WARMUP={WARMUP_MONTHS}")
print(f"  TRAIN={TRAIN_YEARS}yr  TEST={TEST_YEARS}yr")
print(f"  Selection: hidden={SELECTION_HIDDEN} layers={SELECTION_LAYERS} epochs={SELECTION_EPOCHS}")
print(f"  Final:     hidden={FINAL_HIDDEN} layers={FINAL_LAYERS} epochs={FINAL_EPOCHS}")
print(f"{'='*100}")

DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

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
# PHASE 2: CHECK CONSECUTIVE MONTHS  [FIX-J vectorized]
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 2: CHECK {SEQ_LEN} CONSECUTIVE MONTHS  [FIX-J vectorized]")
print("="*100)

def check_consecutive_months_fast(df, min_length):
    t0 = datetime.now()
    tmp = df[['StationID','YYYY','MM']].copy()
    tmp['t'] = tmp['YYYY'].astype(int) * 12 + tmp['MM'].astype(int)
    tmp = tmp.sort_values(['StationID', 't']).reset_index(drop=True)
    tmp['dt']      = tmp.groupby('StationID')['t'].diff().fillna(1)
    tmp['new_run'] = (tmp['dt'] != 1).astype(int)
    tmp['run_id']  = tmp.groupby('StationID')['new_run'].cumsum()
    run_len = (tmp.groupby(['StationID','run_id'])
                  .size().reset_index(name='run_len'))
    max_consec = (run_len.groupby('StationID')['run_len'].max().to_dict())
    print(f"  Consecutive-month check completed in {(datetime.now()-t0).total_seconds():.2f}s")
    return max_consec

t0 = datetime.now()
print(f"Analyzing {X['StationID'].nunique()} stations...")
station_months   = check_consecutive_months_fast(X, SEQ_LEN)
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

accumulated_vars = [
    'ppt0','ppt1','ppt2','ppt3',
    'tmin0','tmin1','tmin2','tmin3',
    'tmax1','tmax2','tmax3',
    'swe0','swe1','swe2','swe3',
    'soil0','soil1','soil2','soil3'
]

derived_count = 0
for v in accumulated_vars:
    if v in X.columns:
        col = f'{v}_area'
        X[col] = (X[v].astype('float32').values / acc).astype('float32')
        dynamic_present.append(col)
        derived_count += 1

print(f"✓ Created {derived_count} derived features")

# =========================================================================
# PHASE 4: SPECIFIC DISCHARGE TARGETS  [#4]
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: SPECIFIC DISCHARGE TARGETS")
print("="*100)

q_specific = []
for q in q_cols:
    col = f'{q}_specific'
    Y[col] = np.log1p(
        (Y[q].astype('float32').values / (acc + 1e-12)).clip(0)
    )
    q_specific.append(col)

print(f"✓ {len(q_specific)} specific discharge targets (log1p applied)")
q_cols_use = q_specific

# =========================================================================
# PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)")
print("="*100)

from scipy.stats import spearmanr

static_features = [v for v in static_present if v in X.columns]
print(f"  Input: {len(static_features)} features, threshold={SPEARMAN_STATION_THRESHOLD}")

# Aggregate to station level (median per station)
station_static = (X.groupby('StationID')[static_features]
                    .median().reset_index())
S = station_static[static_features].values.astype('float32')
print(f"  Aggregated to {len(station_static)} stations")

def decorrelate_by_spearman_fast(mat, feat_names, threshold):
    """[FIX-D] return kept outside the for-loop."""
    n = mat.shape[1]
    kept = list(range(n))
    i = 0
    while i < len(kept):
        to_remove = []
        for j in range(i+1, len(kept)):
            xi = mat[:, kept[i]]
            xj = mat[:, kept[j]]
            mask = ~(np.isnan(xi) | np.isnan(xj))
            if mask.sum() < 10:
                continue
            rho, _ = spearmanr(xi[mask], xj[mask])
            if abs(rho) >= threshold:
                to_remove.append(kept[j])
        kept = [k for k in kept if k not in to_remove]
        i += 1
    return [feat_names[k] for k in kept]   # [FIX-D] outside loop

kept_static = decorrelate_by_spearman_fast(S, static_features, SPEARMAN_STATION_THRESHOLD)
discarded   = [f for f in static_features if f not in kept_static]
print(f"  Output: {len(kept_static)} KEPT, {len(discarded)} DISCARDED")
print(f"✓ Spearman: {len(static_features)} → {len(kept_static)} features")

# =========================================================================
# PHASE 6: TEMPORAL SPLIT (PER-STATION)  [FIX-K vectorized]
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: TEMPORAL SPLIT (PER-STATION)  [FIX-K vectorized]")
print("="*100)

def temporal_split_vectorized(df, train_years, test_years):
    t0 = datetime.now()
    df2 = df.sort_values(['StationID','YYYY','MM']).reset_index(drop=True)
    train_mo = train_years * 12
    test_mo  = test_years  * 12
    required = train_mo + test_mo

    df2['_cumcount'] = df2.groupby('StationID').cumcount()
    df2['_n']        = df2.groupby('StationID')['StationID'].transform('count')

    valid_mask    = df2['_n'] >= required
    train_mask    = valid_mask & (df2['_cumcount'] < train_mo)
    test_mask     = valid_mask & (df2['_cumcount'] >= train_mo) & \
                                 (df2['_cumcount'] <  train_mo + test_mo)

    n_valid   = df2.loc[valid_mask, 'StationID'].nunique()
    n_skipped = df2['StationID'].nunique() - n_valid
    elapsed   = (datetime.now()-t0).total_seconds()
    print(f"  Vectorized split completed in {elapsed:.2f}s")
    print(f"  Valid stations:   {n_valid}")
    print(f"  Skipped stations: {n_skipped}")
    return df2.index[train_mask].tolist(), df2.index[test_mask].tolist(), df2

t_split = datetime.now()
print(f"Splitting {X['StationID'].nunique()} stations ...")
tr_idx, te_idx, X_sorted = temporal_split_vectorized(X, TRAIN_YEARS, TEST_YEARS)
_, _,         Y_sorted = temporal_split_vectorized(Y, TRAIN_YEARS, TEST_YEARS)

X_tr = X_sorted.iloc[tr_idx].reset_index(drop=True)
X_te = X_sorted.iloc[te_idx].reset_index(drop=True)
Y_tr = Y_sorted.iloc[tr_idx].reset_index(drop=True)
Y_te = Y_sorted.iloc[te_idx].reset_index(drop=True)

print(f"  Train: {len(X_tr):,} rows, {X_tr['StationID'].nunique()} stations")
print(f"  Test:  {len(X_te):,} rows, {X_te['StationID'].nunique()} stations")
if len(X_tr) > 0:
    print(f"  Train range: {X_tr['YYYY'].min()}-{X_tr['MM'].min():02d} → "
          f"{X_tr['YYYY'].max()}-{X_tr['MM'].max():02d}")
if len(X_te) > 0:
    print(f"  Test  range: {X_te['YYYY'].min()}-{X_te['MM'].min():02d} → "
          f"{X_te['YYYY'].max()}-{X_te['MM'].max():02d}")
print(f"  Phase 6 total: {(datetime.now()-t_split).total_seconds():.1f}s")

# =========================================================================
# PHASE 7: DATA PREPARATION FOR LSTM
# =========================================================================
print("\n" + "="*100)
print("PHASE 7: DATA PREPARATION FOR LSTM")
print("="*100)

all_dyn_feats = [v for v in (dynamic_present) if v in X_tr.columns]
all_dyn_feats = list(dict.fromkeys(all_dyn_feats))  # deduplicate, preserve order

print("Scaling ...")
sc_dyn = StandardScaler()
sc_sta = StandardScaler()
sc_y   = StandardScaler()

Xtr_dyn_sc = sc_dyn.fit_transform(
    X_tr[all_dyn_feats].fillna(0).clip(-1e6, 1e6).values.astype('float32'))
Xte_dyn_sc = sc_dyn.transform(
    X_te[all_dyn_feats].fillna(0).clip(-1e6, 1e6).values.astype('float32'))

# static: use kept_static features
Xtr_sta_sc = sc_sta.fit_transform(
    X_tr[kept_static].fillna(0).clip(-1e6, 1e6).values.astype('float32'))
Xte_sta_sc = sc_sta.transform(
    X_te[kept_static].fillna(0).clip(-1e6, 1e6).values.astype('float32'))

Ytr_sc = sc_y.fit_transform(
    Y_tr[q_cols_use].fillna(0).values.astype('float32'))
Yte_sc = sc_y.transform(
    Y_te[q_cols_use].fillna(0).values.astype('float32'))

print("✓ Scaling complete (log1p applied)")

# [FIX-O] build_sequences — completely rewritten to fix 1-window-per-station bug
def build_sequences(X_dyn, X_sta, Y_arr, station_ids, seq_len=SEQ_LEN, stride=STRIDE):
    """
    [FIX-O] Correct sliding-window builder.
    Returns X_dyn_seq (N, seq_len, n_dyn), X_sta_seq (N, n_sta), Y_seq (N, n_q),
            seq_station_ids (N,)  — station ID for each output window.
    Each station with T timesteps contributes floor((T-seq_len)/stride)+1 windows.
    """
    try:
        from numpy.lib.stride_tricks import sliding_window_view as _swv
        has_swv = True
    except ImportError:
        has_swv = False

    unique_stations = np.unique(station_ids)
    dyn_list, sta_list, y_list, sid_list = [], [], [], []

    for sid in unique_stations:
        idx = np.where(station_ids == sid)[0]   # already sorted (caller sorted)
        T   = len(idx)
        if T < seq_len:
            continue

        n_win  = (T - seq_len) // stride + 1
        starts = np.arange(0, n_win * stride, stride)   # (n_win,)

        dyn_s = X_dyn[idx]   # (T, n_dyn)

        if has_swv:
            try:
                # shape → (T-seq_len+1, n_dyn, seq_len)
                view = _swv(dyn_s, window_shape=(seq_len,), axis=0)
                # → (T-seq_len+1, seq_len, n_dyn)
                view = view.transpose(0, 2, 1)
                dyn_wins = view[starts]          # (n_win, seq_len, n_dyn)
            except Exception:
                dyn_wins = np.stack([dyn_s[s:s+seq_len] for s in starts])
        else:
            dyn_wins = np.stack([dyn_s[s:s+seq_len] for s in starts])

        # static / target: last timestep of each window
        last = starts + seq_len - 1             # (n_win,)
        sta_wins = X_sta[idx[last]]             # (n_win, n_sta)
        y_wins   = Y_arr[idx[last]]             # (n_win, n_q)

        dyn_list.append(dyn_wins.astype(np.float32))
        sta_list.append(sta_wins.astype(np.float32))
        y_list.append(y_wins.astype(np.float32))
        sid_list.extend([sid] * n_win)

    if len(dyn_list) == 0:
        nd, ns, nq = X_dyn.shape[1], X_sta.shape[1], Y_arr.shape[1]
        return (np.zeros((0, seq_len, nd), np.float32),
                np.zeros((0, ns), np.float32),
                np.zeros((0, nq), np.float32),
                np.array([], dtype=object))

    return (np.concatenate(dyn_list, 0),
            np.concatenate(sta_list, 0),
            np.concatenate(y_list,   0),
            np.array(sid_list))

print(f"\nBuilding sequences  [FIX-O corrected sliding window] ...")
t_seq = datetime.now()

tr_sids = X_tr['StationID'].values
te_sids = X_te['StationID'].values

Xtr_dyn_seq, Xtr_sta_seq, Ytr_seq, tr_seq_sids = build_sequences(
    Xtr_dyn_sc, Xtr_sta_sc, Ytr_sc, tr_sids)
Xte_dyn_seq, Xte_sta_seq, Yte_seq, te_seq_sids = build_sequences(
    Xte_dyn_sc, Xte_sta_sc, Yte_sc, te_sids)

print(f"  Train sequences: {len(Xtr_dyn_seq):,}  shape={Xtr_dyn_seq.shape}  (stride={STRIDE})")
print(f"  Test  sequences: {len(Xte_dyn_seq):,}  ({(datetime.now()-t_seq).total_seconds():.1f}s)")

# [FIX-S] Sequences-per-station diagnostic
print(f"\n  {'--- Sequences-per-station diagnostic ---':^60}")
def _seq_counts(seq_sids):
    sids_u, counts = np.unique(seq_sids, return_counts=True)
    return counts

if len(tr_seq_sids) > 0:
    tr_counts = _seq_counts(tr_seq_sids)
    print(f"  Train: {len(tr_counts)} stations | "
          f"min={tr_counts.min()}  median={int(np.median(tr_counts))}  "
          f"max={tr_counts.max()}  total={tr_counts.sum():,}")
if len(te_seq_sids) > 0:
    te_counts = _seq_counts(te_seq_sids)
    print(f"  Test:  {len(te_counts)} stations | "
          f"min={te_counts.min()}  median={int(np.median(te_counts))}  "
          f"max={te_counts.max()}  total={te_counts.sum():,}")

if len(Xtr_dyn_seq) == 0:
    print("❌ ERROR: No training sequences built."); sys.exit(1)

# =========================================================================
# LSTM DATASET / MODEL DEFINITION
# =========================================================================
class LSTMDataset(Dataset):
    def __init__(self, Xd, Xs, Y):
        self.Xd = torch.from_numpy(Xd)
        self.Xs = torch.from_numpy(Xs)
        self.Y  = torch.from_numpy(Y)
    def __len__(self): return len(self.Xd)
    def __getitem__(self, i): return self.Xd[i], self.Xs[i], self.Y[i]

class LSTMWithContext(nn.Module):
    """[FIX-A] Static features broadcast to every LSTM timestep."""
    def __init__(self, n_dyn, n_sta, n_sta_enc=64, hidden=128,
                 num_layers=2, dropout=0.3, out_dim=11):
        super().__init__()
        self.sta_enc = nn.Sequential(
            nn.Linear(n_sta, n_sta_enc), nn.ReLU(), nn.Dropout(0.1)
        ) if n_sta > 0 else None
        lstm_in = n_dyn + (n_sta_enc if n_sta > 0 else 0)
        self.lstm = nn.LSTM(lstm_in, hidden, num_layers,
                            batch_first=True,
                            dropout=dropout if num_layers > 1 else 0.0)
        self.head = nn.Sequential(
            nn.Linear(hidden, hidden), nn.ReLU(), nn.Dropout(dropout),
            nn.Linear(hidden, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        if self.sta_enc is not None:
            enc = self.sta_enc(x_sta)                  # (B, n_sta_enc)
            enc = enc.unsqueeze(1).expand(-1, x_dyn.size(1), -1)  # (B, T, enc)
            x   = torch.cat([x_dyn, enc], dim=2)      # (B, T, dyn+enc)
        else:
            x = x_dyn
        out, _ = self.lstm(x)
        return self.head(out[:, -1, :])

def run_epoch_sel(model, loader, optimizer, scaler, train=True, warmup=0):
    model.train() if train else model.eval()
    losses = []
    with torch.set_grad_enabled(train):
        for Xd, Xs, Yb in loader:
            Xd = Xd.to(DEVICE, non_blocking=True)
            Xs = Xs.to(DEVICE, non_blocking=True)
            Yb = Yb.to(DEVICE, non_blocking=True)
            if train: optimizer.zero_grad(set_to_none=True)
            if USE_MIXED_PRECISION:
                with make_autocast(DEVICE_TYPE):
                    pred = model(Xd, Xs)
                    loss = nn.functional.mse_loss(pred, Yb)
                if train:
                    scaler.scale(loss).backward()
                    scaler.unscale_(optimizer)
                    nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                    scaler.step(optimizer); scaler.update()
            else:
                pred = model(Xd, Xs)
                loss = nn.functional.mse_loss(pred, Yb)
                if train:
                    loss.backward()
                    nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                    optimizer.step()
            losses.append(loss.item())
    return float(np.mean(losses)) if losses else np.nan

# =========================================================================
# SEQUENTIAL FORWARD SELECTION (STATIC FEATURES)
# =========================================================================
print("\n" + "="*100)
print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES) — selection metric: NSE")
print("="*100)

def eval_static_set(static_cols):
    """Train a lightweight LSTM and return NSE on the validation set."""
    n_sta = len(static_cols)
    n_dyn = Xtr_dyn_seq.shape[2]

    if n_sta > 0:
        sc_sel = StandardScaler()
        Xs_tr = sc_sel.fit_transform(
            X_tr[static_cols].fillna(0).values.astype('float32'))
        Xs_te = sc_sel.transform(
            X_te[static_cols].fillna(0).values.astype('float32'))
        # build static arrays aligned to sequences (last row of each window)
        # reuse the existing seq station-id mapping
        Xtr_s_seq = np.array([Xs_tr[np.where(tr_sids == s)[0][0]] 
                               for s in tr_seq_sids], dtype=np.float32)
        Xte_s_seq = np.array([Xs_te[np.where(te_sids == s)[0][0]]
                               for s in te_seq_sids], dtype=np.float32)
    else:
        Xtr_s_seq = np.zeros((len(Xtr_dyn_seq), 0), dtype=np.float32)
        Xte_s_seq = np.zeros((len(Xte_dyn_seq), 0), dtype=np.float32)

    ds_tr = LSTMDataset(Xtr_dyn_seq, Xtr_s_seq, Ytr_seq)
    ds_te = LSTMDataset(Xte_dyn_seq, Xte_s_seq, Yte_seq)
    ld_tr = DataLoader(ds_tr, SELECTION_BATCH, shuffle=True,
                       num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)
    ld_te = DataLoader(ds_te, SELECTION_BATCH, shuffle=False,
                       num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)

    model = LSTMWithContext(n_dyn, n_sta, 32, SELECTION_HIDDEN,
                            SELECTION_LAYERS, SELECTION_DROPOUT,
                            len(q_cols_use)).to(DEVICE)
    opt   = torch.optim.Adam(model.parameters(), lr=SELECTION_LR)
    scaler = make_gradscaler(DEVICE_TYPE)

    best_nse, best_state = -np.inf, None
    for ep in range(SELECTION_EPOCHS):
        run_epoch_sel(model, ld_tr, opt, scaler, train=True)
        # evaluate
        model.eval()
        preds, trues = [], []
        with torch.no_grad():
            for Xd, Xs, Yb in ld_te:
                Xd = Xd.to(DEVICE); Xs = Xs.to(DEVICE)
                p  = model(Xd, Xs).cpu().numpy()
                preds.append(p); trues.append(Yb.numpy())
        preds = np.concatenate(preds); trues = np.concatenate(trues)
        nse_v = nse(trues.ravel(), preds.ravel())
        if nse_v > best_nse:
            best_nse = nse_v
            best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}

    # cleanup [FIX-E]
    model.cpu(); del model, opt, scaler, ld_tr, ld_te, ds_tr, ds_te
    if USE_GPU: torch.cuda.synchronize(); torch.cuda.empty_cache()
    gc.collect()
    return best_nse

# Baseline: dynamic only
print("\n--- BASELINE: Dynamic features only ---")
baseline_nse = eval_static_set([])
metrics_all(Yte_seq.ravel(), Yte_seq.ravel(), 'baseline', log_transform=False)
print(f"  Baseline NSE (dynamic only): {baseline_nse:.4f}")

best_nse    = baseline_nse
selected    = []
candidates  = list(kept_static)
patience    = 0
improvement_table = [("baseline - dynamic only", best_nse, None)]

print(f"\n--- FORWARD SELECTION (max {MAX_STATIC_FEATURES} features, metric=NSE) ---")

iteration = 0
while (len(selected) < MAX_STATIC_FEATURES and
       len(candidates) > 0 and
       patience < SELECTION_PATIENCE):
    iteration += 1
    print(f"\n[Iteration {iteration}] Testing {len(candidates)} candidates ...")

    best_cand, best_cand_nse = None, -np.inf
    for cand in candidates:
        trial_nse = eval_static_set(selected + [cand])
        if trial_nse > best_cand_nse:
            best_cand_nse = trial_nse
            best_cand = cand

    print(f"  Best candidate: {best_cand} (NSE: {best_cand_nse:.4f})")
    delta = best_cand_nse - best_nse
    if delta > 0:
        selected.append(best_cand)
        candidates.remove(best_cand)
        best_nse = best_cand_nse
        patience = 0
        improvement_table.append((best_cand, best_nse, delta))
        print(f"  ✓ ADDED (ΔNSE: +{delta:.4f})")
    else:
        patience += 1
        print(f"  ✗ No improvement (patience: {patience}/{SELECTION_PATIENCE})")

# Improvement table
print(f"\n{'='*100}")
print(f"SELECTION COMPLETE — IMPROVEMENT TABLE (metric: NSE)")
print(f"{'='*100}")
print(f"{'Feature':<40}  {'NSE':>8}  {'ΔNSE':>8}  {'Δ%':>8}")
print("-"*65)
base_nse_val = improvement_table[0][1]
print(f"  [{improvement_table[0][0]}]  {base_nse_val:>8.4f}  {'—':>8}  {'—':>8}")
for name, nse_v, delta in improvement_table[1:]:
    pct = (delta / (abs(base_nse_val) + 1e-12)) * 100
    print(f"  + {name:<38}  {nse_v:>8.4f}  {'+'+f'{delta:.4f}':>8}  {pct:>7.1f}%")
    base_nse_val = nse_v
final_delta = improvement_table[-1][1] - improvement_table[0][1]
final_pct   = (final_delta / (abs(improvement_table[0][1]) + 1e-12)) * 100
print("-"*65)
print(f"  [final]  {improvement_table[-1][1]:>8.4f}  {'+'+f'{final_delta:.4f}':>8}  {final_pct:>7.1f}%")
print(f"{'='*100}")

print(f"\nSelected {len(selected)} static features:")
for i, f in enumerate(selected, 1):
    print(f"   {i:2d}. {f}")

# =========================================================================
# FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)")
print("="*100)

n_dyn_final = Xtr_dyn_seq.shape[2]
n_sta_final = len(selected)

if n_sta_final > 0:
    sc_final = StandardScaler()
    Xtr_sta_final = sc_final.fit_transform(
        X_tr[selected].fillna(0).values.astype('float32'))
    Xte_sta_final = sc_final.transform(
        X_te[selected].fillna(0).values.astype('float32'))
    # align to sequences via station IDs
    Xtr_sta_seq_f = np.array([Xtr_sta_final[np.where(tr_sids == s)[0][0]]
                               for s in tr_seq_sids], dtype=np.float32)
    Xte_sta_seq_f = np.array([Xte_sta_final[np.where(te_sids == s)[0][0]]
                               for s in te_seq_sids], dtype=np.float32)
else:
    Xtr_sta_seq_f = np.zeros((len(Xtr_dyn_seq), 0), dtype=np.float32)
    Xte_sta_seq_f = np.zeros((len(Xte_dyn_seq), 0), dtype=np.float32)

print(f"  dynamic={n_dyn_final}  static={n_sta_final}  "
      f"total={n_dyn_final+n_sta_final}  warmup={WARMUP_MONTHS}mo")

ds_tr_f = LSTMDataset(Xtr_dyn_seq, Xtr_sta_seq_f, Ytr_seq)
ds_te_f = LSTMDataset(Xte_dyn_seq, Xte_sta_seq_f, Yte_seq)
ld_tr_f = DataLoader(ds_tr_f, FINAL_BATCH, shuffle=True,
                     num_workers=FINAL_WORKERS, pin_memory=USE_GPU)
ld_te_f = DataLoader(ds_te_f, FINAL_BATCH, shuffle=False,
                     num_workers=FINAL_WORKERS, pin_memory=USE_GPU)

model_f = LSTMWithContext(n_dyn_final, n_sta_final, 64, FINAL_HIDDEN,
                          FINAL_LAYERS, FINAL_DROPOUT,
                          len(q_cols_use)).to(DEVICE)
opt_f   = torch.optim.Adam(model_f.parameters(), lr=FINAL_LR)
sched_f = torch.optim.lr_scheduler.ReduceLROnPlateau(
              opt_f, factor=LR_FACTOR, patience=LR_PATIENCE, verbose=False)
scaler_f = make_gradscaler(DEVICE_TYPE)

best_val_loss = np.inf
best_state_f  = None
es_counter    = 0

print(f"\nTraining up to {FINAL_EPOCHS} epochs (ES patience={EARLY_STOP_PATIENCE}) ...")
for ep in range(1, FINAL_EPOCHS + 1):
    tr_loss = run_epoch_sel(model_f, ld_tr_f, opt_f, scaler_f,
                             train=True, warmup=WARMUP_MONTHS)
    val_loss = run_epoch_sel(model_f, ld_te_f, opt_f, scaler_f,
                              train=False)
    sched_f.step(val_loss)

    if val_loss < best_val_loss:
        best_val_loss = val_loss
        best_state_f  = {k: v.cpu().clone() for k, v in model_f.state_dict().items()}
        es_counter = 0
    else:
        es_counter += 1

    if ep % 10 == 0 or ep == 1:
        print(f"  Epoch {ep:3d}/{FINAL_EPOCHS}  train={tr_loss:.6f}  val={val_loss:.6f}")
    if es_counter >= EARLY_STOP_PATIENCE:
        print(f"\n  Early stopping at epoch {ep}")
        break

model_f.load_state_dict(best_state_f)
torch.save(best_state_f, '../predict_score_red/best_model_v15.pt')   # [FIX-T]

# =========================================================================
# FINAL EVALUATION
# =========================================================================
print("\n" + "="*100)
print("FINAL EVALUATION")
print("="*100)

model_f.eval()
preds_te, trues_te = [], []
with torch.no_grad():
    for Xd, Xs, Yb in ld_te_f:
        Xd = Xd.to(DEVICE); Xs = Xs.to(DEVICE)
        p  = model_f(Xd, Xs).cpu().numpy()
        preds_te.append(p); trues_te.append(Yb.numpy())
Ypte_seq = np.concatenate(preds_te)   # [FIX-T] renamed for clarity
Yte_true  = np.concatenate(trues_te)

# inverse-scale then back-transform (log → real)
Ypte_inv = sc_y.inverse_transform(Ypte_seq)
Yte_inv  = sc_y.inverse_transform(Yte_true)
# expm1 is applied inside metrics_all via log_transform=True

# Monotonicity enforcement  [#3]
viol_before = int(np.sum(np.diff(Ypte_inv, axis=1) < 0))
Ypte_mono   = enforce_monotonicity(Ypte_inv)
viol_after  = int(np.sum(np.diff(Ypte_mono, axis=1) < 0))
print(f"\n  Monotonicity violations: {viol_before} → {viol_after} (after isotonic)")

print(f"\nOverall metrics (all quantiles pooled, back-transformed):")
metrics_all(Yte_inv.ravel(), Ypte_mono.ravel(), 'all quantiles', log_transform=True)

print(f"\nPer-quantile metrics (back-transformed):")
print(f"  {'Quantile':<25}  {'MAE':>8}  {'RMSE':>8}  {'R²':>8}  {'NSE':>8}  {'KGE':>8}")
print("  " + "-"*65)
for i, qn in enumerate(q_cols_use):
    mae_v, rmse_v, r2_v, nse_v, kge_v = metrics_all(
        Yte_inv[:, i], Ypte_mono[:, i], log_transform=True)
    print(f"  {qn:<25}  {mae_v:>8.4f}  {rmse_v:>8.4f}  {r2_v:>8.4f}"
          f"  {nse_v:>8.4f}  {kge_v:>8.4f}")

# [FIX-R] Per-station NSE / KGE
print(f"\nPer-station NSE / KGE (back-transformed, test set, median quantile):")
mid = len(q_cols_use) // 2
obs_bt  = np.expm1(np.clip(Yte_inv[:, mid],  0, None))
sim_bt  = np.expm1(np.clip(Ypte_mono[:, mid], 0, None))

nse_per_stn, kge_per_stn = [], []
for sid in np.unique(te_seq_sids):
    m = te_seq_sids == sid
    if m.sum() < 2: continue
    nse_per_stn.append(nse(obs_bt[m], sim_bt[m]))
    kge_per_stn.append(kge(obs_bt[m], sim_bt[m]))

nse_arr = np.array([v for v in nse_per_stn if not np.isnan(v)])
kge_arr = np.array([v for v in kge_per_stn if not np.isnan(v)])

if len(nse_arr) > 0:
    print(f"  NSE across {len(nse_arr)} stations:")
    print(f"    median={np.median(nse_arr):.4f}  mean={np.mean(nse_arr):.4f}"
          f"  p10={np.percentile(nse_arr,10):.4f}  p90={np.percentile(nse_arr,90):.4f}")
    print(f"    NSE>0.0: {(nse_arr>0.0).sum()} ({100*(nse_arr>0.0).mean():.1f}%)")
    print(f"    NSE>0.3: {(nse_arr>0.3).sum()} ({100*(nse_arr>0.3).mean():.1f}%)")
    print(f"    NSE>0.5: {(nse_arr>0.5).sum()} ({100*(nse_arr>0.5).mean():.1f}%)")
if len(kge_arr) > 0:
    print(f"  KGE across {len(kge_arr)} stations:")
    print(f"    median={np.median(kge_arr):.4f}  mean={np.mean(kge_arr):.4f}"
          f"  p10={np.percentile(kge_arr,10):.4f}  p90={np.percentile(kge_arr,90):.4f}")
    print(f"    KGE>0.0: {(kge_arr>0.0).sum()} ({100*(kge_arr>0.0).mean():.1f}%)")
    print(f"    KGE>0.3: {(kge_arr>0.3).sum()} ({100*(kge_arr>0.3).mean():.1f}%)")

# Save outputs  [FIX-T]
with open('../predict_score_red/lstm_v15_selected_features.txt', 'w') as f:
    f.write('DYNAMIC_FEATURES\n')
    for v in all_dyn_feats: f.write(f'{v}\n')
    f.write('\nSTATIC_FEATURES\n')
    for v in selected: f.write(f'{v}\n')

with open('../predict_score_red/lstm_v15_results.txt', 'w') as f:
    f.write(f"SC31 LSTM V15 RESULTS\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"Job ID: {os.environ.get('SLURM_JOB_ID','N/A')}\n\n")
    f.write(f"SEQ_LEN={SEQ_LEN}  STRIDE={STRIDE}  WARMUP={WARMUP_MONTHS}\n")
    f.write(f"Train sequences: {len(Xtr_dyn_seq):,}\n")
    f.write(f"Test  sequences: {len(Xte_dyn_seq):,}\n\n")
    f.write(f"SELECTED STATIC FEATURES ({len(selected)}):\n")
    for v in selected: f.write(f"  {v}\n")
    f.write(f"\nOVERALL METRICS (back-transformed, pooled):\n")
    mae_v, rmse_v, r2_v, nse_v, kge_v = metrics_all(
        Yte_inv.ravel(), Ypte_mono.ravel(), log_transform=True)
    f.write(f"  MAE={mae_v:.4f}  RMSE={rmse_v:.4f}  R²={r2_v:.4f}"
            f"  NSE={nse_v:.4f}  KGE={kge_v:.4f}\n")
    if len(nse_arr) > 0:
        f.write(f"\nPER-STATION NSE ({len(nse_arr)} stations):\n")
        f.write(f"  median={np.median(nse_arr):.4f}  mean={np.mean(nse_arr):.4f}"
                f"  p10={np.percentile(nse_arr,10):.4f}  p90={np.percentile(nse_arr,90):.4f}\n")
        f.write(f"  NSE>0.0: {(nse_arr>0.0).sum()}  NSE>0.3: {(nse_arr>0.3).sum()}"
                f"  NSE>0.5: {(nse_arr>0.5).sum()}\n")

print(f"\n✓ Results  → ../predict_score_red/lstm_v15_results.txt")
print(f"✓ Features → ../predict_score_red/lstm_v15_selected_features.txt")
print(f"✓ Model    → ../predict_score_red/best_model_v15.pt")

print("\n" + "="*100)
print(f"COMPLETE — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)

EOFPYTHON
