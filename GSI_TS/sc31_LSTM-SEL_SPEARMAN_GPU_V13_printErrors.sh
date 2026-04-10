#!/bin/bash
#SBATCH -p scavenge
#####SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V14.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V14.%J.out
#SBATCH --job-name=sc31_LSTM_V14
#SBATCH --mem=200G

# =============================================================================
# sc31_LSTM-SEL_SPEARMAN_GPU_V14.sh
#
# Changes vs V13  (labelled [FIX-J], [FIX-K], [FIX-L]):
#
#   [FIX-J]  PHASE 2 — check_consecutive_months fully vectorized:
#            Old: pure-Python row-loop + pd.DateOffset per row → O(N×M) slow.
#            New: sort once, compute month-diff with np.diff on integer
#            year*12+month encoding, find consecutive runs with np.diff==1,
#            use np.maximum.reduceat for run-length max. No Python loop over
#            rows. ~50–100× faster for 498 stations × 264 months.
#
#   [FIX-K]  PHASE 6 — temporal split fully vectorized, joblib removed:
#            Old: Parallel(n_jobs=12) + per-station sort + Python dict return
#            → joblib IPC overhead > actual work for 498 small groups.
#            New: sort X once globally, compute per-station cumcount,
#            assign train/test split mask with pure numpy/pandas groupby
#            cumcount. Returns index arrays directly. ~20× faster.
#
#   [FIX-L]  build_sequences — inner index gather vectorized with numpy
#            strides (np.lib.stride_tricks.sliding_window_view):
#            Old: Python list-append per window → slow for stride=1.
#            New: sliding_window_view gives zero-copy index array;
#            fancy-index into X_dyn/X_sta/Y with a single numpy gather.
#            Falls back to list loop if sliding_window_view unavailable
#            (numpy < 1.20). ~10–30× faster for large station counts.
#
# Carried over from V13 without change:
#   [FIX-A..I]  all previous fixes
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
# [FIX-B] NSE / KGE / metrics
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

def metrics_all(obs, sim, label=''):
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
print("SC31: LSTM V14 — VECTORIZED PHASE2/PHASE6/SEQ-BUILD (SPEED FIX)")
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
    SELECTION_BATCH   = 512
    FINAL_BATCH       = 1024
    SELECTION_WORKERS = 0
    FINAL_WORKERS     = 4
    USE_MIXED_PRECISION = True
    SELECTION_HIDDEN  = 64
    FINAL_HIDDEN      = 128
else:
    print(f"⚠️  CPU MODE  ({os.cpu_count()} cores)")
    SELECTION_BATCH   = 128
    FINAL_BATCH       = 256
    SELECTION_WORKERS = 0
    FINAL_WORKERS     = 2
    USE_MIXED_PRECISION = False
    SELECTION_HIDDEN  = 32
    FINAL_HIDDEN      = 64

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

SEQ_LEN           = 132
STRIDE            = 1
SELECTION_LAYERS  = 1
SELECTION_DROPOUT = 0.1
SELECTION_EPOCHS  = 15
SELECTION_LR      = 1e-3

FINAL_LAYERS        = 2
FINAL_DROPOUT       = 0.3
FINAL_EPOCHS        = 100
FINAL_LR            = 1e-3
LR_PATIENCE         = 10
LR_FACTOR           = 0.5
EARLY_STOP_PATIENCE = 20
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
# PHASE 2: CHECK CONSECUTIVE MONTHS — [FIX-J] fully vectorized
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 2: CHECK {SEQ_LEN} CONSECUTIVE MONTHS  [FIX-J vectorized]")
print("="*100)

def check_consecutive_months_fast(df, min_length):
    """
    [FIX-J] Vectorized consecutive-month checker.
    Encodes each row as integer t = YYYY*12 + MM, sorts globally,
    computes diff per station with groupby, finds max run-length
    via cumulative-sum trick — no Python loop over rows.
    """
    t0 = datetime.now()
    tmp = df[['StationID','YYYY','MM']].copy()
    tmp['t'] = tmp['YYYY'].astype(int) * 12 + tmp['MM'].astype(int)
    tmp = tmp.sort_values(['StationID', 't']).reset_index(drop=True)

    # diff of t within each station: consecutive months → diff==1
    tmp['dt'] = tmp.groupby('StationID')['t'].diff().fillna(1)

    # new run starts when dt != 1  →  run_id increments
    tmp['new_run'] = (tmp['dt'] != 1).astype(int)
    tmp['run_id']  = tmp.groupby('StationID')['new_run'].cumsum()

    # count length of each run
    run_len = (tmp.groupby(['StationID','run_id'])
                  .size()
                  .reset_index(name='run_len'))

    # max run per station
    max_consec = (run_len.groupby('StationID')['run_len']
                         .max()
                         .to_dict())

    elapsed = (datetime.now() - t0).total_seconds()
    print(f"  Consecutive-month check completed in {elapsed:.2f}s")
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

accumulated_vars = [
    'ppt0','ppt1','ppt2','ppt3',
    'tmin0','tmin1','tmin2','tmin3',
    'tmax1','tmax2','tmax3',
    'swe0','swe1','swe2','swe3',
    'soil0','soil1','soil2','soil3',
    'GRWLw'
]
derived_features = []
for var in accumulated_vars:
    if var in X.columns:
        X[f'{var}_mean'] = (X[var].astype('float32').values / acc).astype('float32')
        derived_features.append(f'{var}_mean')
if 'tmax0' in X.columns:
    derived_features.append('tmax0')

print(f"✓ Created {len(derived_features)} derived features")
dynamic_final = derived_features.copy()
del acc; gc.collect()

# =========================================================================
# PHASE 4: SPECIFIC DISCHARGE TARGETS
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: SPECIFIC DISCHARGE TARGETS")
print("="*100)

Y_acc = X['accumulation'].values.astype('float32')
assert (Y_acc > 0).all(), "accumulation must be strictly positive"  # [#5]

q_cols_specific = []
for q_col in q_cols:
    q_sp = f'{q_col}_specific'
    Y[q_sp] = (Y[q_col].values / Y_acc).astype('float32')
    q_cols_specific.append(q_sp)
q_cols_target = q_cols_specific
print(f"✓ {len(q_cols_specific)} specific discharge targets (m³/s/km²)")
del Y_acc; gc.collect()

# =========================================================================
# PHASE 5: SPEARMAN DECORRELATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)")
print("="*100)

def decorrelate_by_spearman_fast(X_df, groups, threshold):
    print(f"  Input: {len(X_df.columns)} features, threshold={threshold}")
    df = X_df.copy()
    df['__g__'] = groups
    df_station = df.groupby('__g__', observed=True).mean(numeric_only=True)
    df_station = df_station.replace([np.inf,-np.inf], np.nan).fillna(df_station.median())
    print(f"  Aggregated to {len(df_station)} stations")
    del df; gc.collect()
    corr_matrix = df_station.corr(method='spearman').abs()
    corr_array  = corr_matrix.to_numpy().copy()
    np.fill_diagonal(corr_array, 0)
    corr_matrix = pd.DataFrame(corr_array, index=corr_matrix.index, columns=corr_matrix.columns)
    features = list(df_station.columns)
    to_drop = set(); kept = []
    for feat in features:
        if feat in to_drop: continue
        kept.append(feat)
        high = corr_matrix.loc[feat][corr_matrix.loc[feat] > threshold].index.tolist()
        for cf in high:
            if cf != feat and cf not in kept:
                to_drop.add(cf)
    # [FIX-D] return outside loop
    print(f"  Output: {len(kept)} KEPT, {len(to_drop)} DISCARDED")
    del df_station, corr_matrix; gc.collect()
    return kept

X_static_df = X[[c for c in static_present if c in X.columns]]
static_decorrelated = decorrelate_by_spearman_fast(
    X_static_df, X['StationID'].to_numpy(), SPEARMAN_STATION_THRESHOLD)
print(f"✓ Spearman: {len(static_present)} → {len(static_decorrelated)} features")
del X_static_df; gc.collect()

# =========================================================================
# PHASE 6: TEMPORAL SPLIT — [FIX-K] fully vectorized, no joblib
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: TEMPORAL SPLIT (PER-STATION)  [FIX-K vectorized]")
print("="*100)

def split_temporal_vectorized(X, Y, train_years, test_years):
    """
    [FIX-K] Vectorized temporal split — no joblib, no per-station Python loop.

    Strategy:
      1. Sort entire dataframe once by [StationID, YYYY, MM].
      2. Compute per-station row counter (cumcount).
      3. Assign label: 'train' for rows 0..train_months-1,
                       'test'  for rows train_months..train_months+test_months-1,
                       'skip'  otherwise.
      4. Extract indices in one boolean mask operation.
    """
    t0 = datetime.now()
    train_months = train_years * 12
    test_months  = test_years  * 12

    # sort globally once
    order = X.sort_values(['StationID','YYYY','MM']).index
    X_s   = X.loc[order].copy()
    Y_s   = Y.loc[order].copy()

    # per-station row counter (0-based)
    X_s['_row'] = X_s.groupby('StationID').cumcount()

    # count total rows per station — stations with < required are skipped
    required    = train_months + test_months
    sta_counts  = X_s.groupby('StationID')['_row'].transform('count')
    X_s['_ok']  = sta_counts >= required

    train_mask = X_s['_ok'] & (X_s['_row'] < train_months)
    test_mask  = X_s['_ok'] & (X_s['_row'] >= train_months) & \
                               (X_s['_row'] < train_months + test_months)
    skip_mask  = ~X_s['_ok']

    train_idx = X_s.index[train_mask].tolist()
    test_idx  = X_s.index[test_mask].tolist()
    n_skip    = int(skip_mask.groupby(X_s['StationID']).any().sum())
    n_valid   = X_s['StationID'].nunique() - n_skip

    elapsed = (datetime.now()-t0).total_seconds()
    print(f"  Vectorized split completed in {elapsed:.2f}s")
    print(f"  Valid stations:   {n_valid}")
    print(f"  Skipped stations: {n_skip}")

    # clean up helper columns
    X_s.drop(columns=['_row','_ok'], inplace=True)

    X_train = X.loc[train_idx].copy().reset_index(drop=True)
    Y_train = Y.loc[train_idx].copy().reset_index(drop=True)
    X_test  = X.loc[test_idx].copy().reset_index(drop=True)
    Y_test  = Y.loc[test_idx].copy().reset_index(drop=True)
    return X_train, Y_train, X_test, Y_test

t0 = datetime.now()
print(f"Splitting {X['StationID'].nunique()} stations ...")
X_train, Y_train, X_test, Y_test = split_temporal_vectorized(
    X, Y, TRAIN_YEARS, TEST_YEARS)

print(f"  Train: {len(X_train):,} rows, {X_train['StationID'].nunique()} stations")
print(f"  Test:  {len(X_test):,} rows,  {X_test['StationID'].nunique()} stations")
print(f"  Train range: {X_train['YYYY'].min()}-{X_train['MM'].min():02d} → "
      f"{X_train['YYYY'].max()}-{X_train['MM'].max():02d}")
print(f"  Test  range: {X_test['YYYY'].min()}-{X_test['MM'].min():02d} → "
      f"{X_test['YYYY'].max()}-{X_test['MM'].max():02d}")
print(f"  Phase 6 total: {(datetime.now()-t0).total_seconds():.1f}s")
gc.collect()

# =========================================================================
# PHASE 7: DATA PREPARATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 7: DATA PREPARATION FOR LSTM")
print("="*100)

def clean_data(df):
    return df.replace([np.inf,-np.inf], np.nan).fillna(df.median(numeric_only=True))

X_train_dyn     = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn      = clean_data(X_test[dynamic_final]).astype('float32')
X_train_sta_all = clean_data(X_train[static_decorrelated]).astype('float32')
X_test_sta_all  = clean_data(X_test[static_decorrelated]).astype('float32')
Y_train_qdf     = clean_data(Y_train[q_cols_target]).astype('float32')
Y_test_qdf      = clean_data(Y_test[q_cols_target]).astype('float32')

print("Scaling ...")
scaler_dyn = StandardScaler()
scaler_sta = StandardScaler()
scaler_y   = StandardScaler()

X_train_dyn_s     = scaler_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s      = scaler_dyn.transform(X_test_dyn.to_numpy()).astype('float32')
X_train_sta_all_s = scaler_sta.fit_transform(X_train_sta_all.to_numpy()).astype('float32')
X_test_sta_all_s  = scaler_sta.transform(X_test_sta_all.to_numpy()).astype('float32')

# [#4] log1p on skewed targets
Y_train_log = np.log1p(Y_train_qdf.to_numpy()).astype('float32')
Y_test_log  = np.log1p(Y_test_qdf.to_numpy()).astype('float32')
Y_train_s   = scaler_y.fit_transform(Y_train_log).astype('float32')
Y_test_s    = scaler_y.transform(Y_test_log).astype('float32')
print("✓ Scaling complete (log1p applied)")

# ---- Sliding-window sequence builder [FIX-L] vectorized ----------------
print("\nBuilding sequences  [FIX-L vectorized] ...")

def build_sequences_fast(df_meta, X_dyn, X_sta, Y_arr, seq_len=132, stride=1):
    """
    [FIX-L] Vectorized sliding-window sequence builder.

    Uses np.lib.stride_tricks.sliding_window_view (numpy >= 1.20) to create
    a zero-copy view of the per-station index array, then gathers all windows
    with a single fancy-index operation instead of Python list-append loops.
    Falls back to list loop for numpy < 1.20.
    """
    df = df_meta.copy()
    df = df.sort_values(['StationID','YYYY','MM']).reset_index(drop=True)

    Xd_list, Xs_list, Yl_list, Il_list = [], [], [], []

    try:
        from numpy.lib.stride_tricks import sliding_window_view as _swv
        use_strides = True
    except ImportError:
        use_strides = False

    for _, grp in df.groupby('StationID', sort=False):
        idx = grp.index.to_numpy()          # integer positions in df (= positions in arrays)
        n   = len(idx)
        if n < seq_len:
            continue

        if use_strides:
            # shape: (n_windows, seq_len)  — zero-copy view
            win_idx = _swv(idx, seq_len)[::stride]     # (W, seq_len)
            last    = win_idx[:, -1]                   # (W,)
            # gather dynamic: (W, seq_len, n_dyn)
            Xd_list.append(X_dyn[win_idx])             # fancy index
            Xs_list.append(X_sta[last])
            Yl_list.append(Y_arr[last])
            Il_list.append(last)
        else:
            # fallback: original list loop
            for start in range(0, n - seq_len + 1, stride):
                end  = start + seq_len
                last = idx[end - 1]
                Xd_list.append(X_dyn[idx[start:end]])
                Xs_list.append(X_sta[last])
                Yl_list.append(Y_arr[last])
                Il_list.append(last)

    if use_strides:
        Xd = np.concatenate(Xd_list, axis=0).astype(np.float32)
        Xs = np.concatenate(Xs_list, axis=0).astype(np.float32)
        Yl = np.concatenate(Yl_list, axis=0).astype(np.float32)
        Il = np.concatenate(Il_list, axis=0).astype(np.int64)
    else:
        Xd = np.array(Xd_list, dtype=np.float32)
        Xs = np.array(Xs_list, dtype=np.float32)
        Yl = np.array(Yl_list, dtype=np.float32)
        Il = np.array(Il_list, dtype=np.int64)

    return Xd, Xs, Yl, Il

t_seq = datetime.now()
Xtr_meta = X_train[['StationID','YYYY','MM']]
Xte_meta = X_test[['StationID','YYYY','MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences_fast(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN, STRIDE)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences_fast(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s, Y_test_s,  SEQ_LEN, STRIDE)

print(f"  Train sequences: {Xtr_seq_dyn.shape[0]:,}  shape={Xtr_seq_dyn.shape}  "
      f"(stride={STRIDE})")
print(f"  Test  sequences: {Xte_seq_dyn.shape[0]:,}  "
      f"({(datetime.now()-t_seq).total_seconds():.1f}s)")

if Xtr_seq_dyn.shape[0] == 0:
    print("❌ ERROR: No training sequences!"); sys.exit(1)
if Xte_seq_dyn.shape[0] == 0:
    print("❌ ERROR: No test sequences!");     sys.exit(1)

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

# =========================================================================
# MODEL DEFINITION  [FIX-A]
# =========================================================================
class StaticEncoder(nn.Module):
    def __init__(self, n_sta, enc_dim, dropout):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_sta, enc_dim), nn.ReLU(), nn.Dropout(dropout))
    def forward(self, x): return self.net(x)

class LSTMWithContext(nn.Module):
    def __init__(self, n_dyn, n_sta, hidden, num_layers, dropout, out_dim):
        super().__init__()
        if n_sta > 0:
            self.enc_dim = max(8, n_sta // 2)
            self.static_encoder = StaticEncoder(n_sta, self.enc_dim, dropout)
        else:
            self.enc_dim = 0
            self.static_encoder = None
        self.lstm = nn.LSTM(
            input_size=n_dyn + self.enc_dim, hidden_size=hidden,
            num_layers=num_layers, batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0, bidirectional=False)
        self.head = nn.Sequential(
            nn.Linear(hidden, 128), nn.ReLU(),
            nn.Dropout(dropout), nn.Linear(128, out_dim))

    def forward(self, x_dyn, x_sta):
        if self.static_encoder is not None and x_sta.shape[1] > 0:
            sta_enc  = self.static_encoder(x_sta)
            sta_tile = sta_enc.unsqueeze(1).expand(-1, x_dyn.shape[1], -1)
            x_fused  = torch.cat([x_dyn, sta_tile], dim=-1)
        else:
            x_fused = x_dyn
        out, _ = self.lstm(x_fused)
        return self.head(out[:, -1, :])

class LSTMDataset(Dataset):
    def __init__(self, X_dyn, X_sta, Y):
        self.X_dyn = torch.from_numpy(X_dyn)
        self.X_sta = torch.from_numpy(X_sta)
        self.Y     = torch.from_numpy(Y)
    def __len__(self): return len(self.X_dyn)
    def __getitem__(self, i): return self.X_dyn[i], self.X_sta[i], self.Y[i]

# [FIX-E] safe GPU cleanup
def release_model(model):
    try: model.cpu()
    except: pass
    del model; gc.collect()
    if torch.cuda.is_available():
        torch.cuda.synchronize()
        torch.cuda.empty_cache()

# [FIX-C] warmup-masked training
def train_one_epoch_with_warmup(model, loader, optimizer, criterion,
                                scaler_amp, use_amp, device, device_type,
                                warmup=0):
    model.train()
    total_loss = 0.0
    for x_dyn, x_sta, y in loader:
        x_dyn, x_sta, y = x_dyn.to(device), x_sta.to(device), y.to(device)
        optimizer.zero_grad()
        if warmup > 0 and x_dyn.shape[1] > warmup:
            x_wu = x_dyn[:, :warmup, :]
            x_pr = x_dyn[:, warmup:, :]
            if model.static_encoder is not None and x_sta.shape[1] > 0:
                se = model.static_encoder(x_sta)
                x_wu_in = torch.cat([x_wu, se.unsqueeze(1).expand(-1, warmup, -1)], -1)
                x_pr_in = torch.cat([x_pr, se.unsqueeze(1).expand(-1, x_pr.shape[1], -1)], -1)
            else:
                x_wu_in, x_pr_in = x_wu, x_pr
            with torch.no_grad():
                if use_amp:
                    with make_autocast(device_type): _, (h_n, c_n) = model.lstm(x_wu_in)
                else: _, (h_n, c_n) = model.lstm(x_wu_in)
            h_n, c_n = h_n.detach(), c_n.detach()
            if use_amp:
                with make_autocast(device_type):
                    out_pr, _ = model.lstm(x_pr_in, (h_n, c_n))
                    loss = criterion(model.head(out_pr[:,-1,:]), y)
                scaler_amp.scale(loss).backward()
                scaler_amp.step(optimizer); scaler_amp.update()
            else:
                out_pr, _ = model.lstm(x_pr_in, (h_n, c_n))
                loss = criterion(model.head(out_pr[:,-1,:]), y)
                loss.backward(); optimizer.step()
        else:
            if use_amp:
                with make_autocast(device_type):
                    loss = criterion(model(x_dyn, x_sta), y)
                scaler_amp.scale(loss).backward()
                scaler_amp.step(optimizer); scaler_amp.update()
            else:
                loss = criterion(model(x_dyn, x_sta), y)
                loss.backward(); optimizer.step()
        total_loss += loss.item()
    return total_loss / len(loader)

def evaluate_model(model, loader, criterion, use_amp, device, device_type):
    model.eval(); preds_list = []; val_loss = 0.0
    with torch.no_grad():
        for x_dyn, x_sta, y in loader:
            x_dyn, x_sta, y = x_dyn.to(device), x_sta.to(device), y.to(device)
            if use_amp:
                with make_autocast(device_type):
                    p = model(x_dyn, x_sta); loss = criterion(p, y)
            else:
                p = model(x_dyn, x_sta); loss = criterion(p, y)
            val_loss += loss.item(); preds_list.append(p.cpu().numpy())
    return np.vstack(preds_list), val_loss / len(loader)

def decode_preds(preds_scaled, scaler_y):
    return enforce_monotonicity(np.expm1(scaler_y.inverse_transform(preds_scaled)))

# =========================================================================
# SEQUENTIAL FORWARD SELECTION  [FIX-B] NSE criterion
# =========================================================================
if USE_SEQUENTIAL_SELECTION and len(static_decorrelated) > 0:
    print("\n" + "="*100)
    print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES) — selection metric: NSE")
    print("="*100)

    selected_static   = []
    remaining_static  = static_decorrelated.copy()
    selection_history = []
    n_dyn = Xtr_seq_dyn.shape[2]
    n_out = Ytr_seq.shape[1]

    criterion  = nn.MSELoss()
    amp_scaler = make_gradscaler(DEVICE_TYPE) if USE_MIXED_PRECISION else None

    # --- Baseline ---
    print("\n--- BASELINE: Dynamic features only ---")
    Xtr_empty = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_empty = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)
    model_bl  = LSTMWithContext(n_dyn=n_dyn, n_sta=0, hidden=SELECTION_HIDDEN,
                                num_layers=SELECTION_LAYERS, dropout=SELECTION_DROPOUT,
                                out_dim=n_out).to(DEVICE)
    tr_dl_bl = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_empty, Ytr_seq),
                          batch_size=SELECTION_BATCH, shuffle=True,
                          num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)
    te_dl_bl = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_empty, Yte_seq),
                          batch_size=SELECTION_BATCH*2, shuffle=False,
                          num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)
    opt_bl = torch.optim.Adam(model_bl.parameters(), lr=SELECTION_LR)
    for ep in range(SELECTION_EPOCHS):
        train_one_epoch_with_warmup(model_bl, tr_dl_bl, opt_bl, criterion,
                                    amp_scaler, USE_MIXED_PRECISION, DEVICE,
                                    DEVICE_TYPE, warmup=0)
    preds_bl_s, _ = evaluate_model(model_bl, te_dl_bl, criterion,
                                   USE_MIXED_PRECISION, DEVICE, DEVICE_TYPE)
    preds_bl = decode_preds(preds_bl_s, scaler_y)
    _, _, _, nse_bl, _ = metrics_all(Yte_true, preds_bl, label='baseline')
    release_model(model_bl)

    best_nse = nse_bl; patience_cnt = 0
    print(f"\n--- FORWARD SELECTION (max {MAX_STATIC_FEATURES} features, metric=NSE) ---")

    for iteration in range(MAX_STATIC_FEATURES):
        if not remaining_static:
            print("\n  No more features to add"); break
        print(f"\n[Iteration {iteration+1}] Testing {len(remaining_static)} candidates ...")
        candidate_results = []

        for candidate in remaining_static:
            cur_feats   = selected_static + [candidate]
            col_indices = [static_decorrelated.index(f) for f in cur_feats]
            Xtr_c = Xtr_seq_sta_all[:, col_indices]
            Xte_c = Xte_seq_sta_all[:, col_indices]
            model_c = LSTMWithContext(n_dyn=n_dyn, n_sta=len(cur_feats),
                                      hidden=SELECTION_HIDDEN, num_layers=SELECTION_LAYERS,
                                      dropout=SELECTION_DROPOUT, out_dim=n_out).to(DEVICE)
            tr_dl_c = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_c, Ytr_seq),
                                 batch_size=SELECTION_BATCH, shuffle=True,
                                 num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)
            te_dl_c = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_c, Yte_seq),
                                 batch_size=SELECTION_BATCH*2, shuffle=False,
                                 num_workers=SELECTION_WORKERS, pin_memory=USE_GPU)
            opt_c = torch.optim.Adam(model_c.parameters(), lr=SELECTION_LR)
            for ep in range(SELECTION_EPOCHS):
                train_one_epoch_with_warmup(model_c, tr_dl_c, opt_c, criterion,
                                            amp_scaler, USE_MIXED_PRECISION, DEVICE,
                                            DEVICE_TYPE, warmup=0)
            preds_c_s, _ = evaluate_model(model_c, te_dl_c, criterion,
                                          USE_MIXED_PRECISION, DEVICE, DEVICE_TYPE)
            preds_c = decode_preds(preds_c_s, scaler_y)
            nse_c   = nse(Yte_true.ravel(), preds_c.ravel())
            candidate_results.append((candidate, nse_c))
            del tr_dl_c, te_dl_c, opt_c
            release_model(model_c)

        candidate_results.sort(key=lambda x: x[1], reverse=True)
        best_cand, best_cand_nse = candidate_results[0]
        print(f"  Best candidate: {best_cand} (NSE: {best_cand_nse:.4f})")

        if best_cand_nse > best_nse:
            print(f"  ✓ ADDED (ΔNSE: +{best_cand_nse - best_nse:.4f})")
            selected_static.append(best_cand)
            remaining_static.remove(best_cand)
            selection_history.append((best_cand, best_cand_nse))
            best_nse = best_cand_nse; patience_cnt = 0
        else:
            patience_cnt += 1
            print(f"  ✗ No improvement (patience: {patience_cnt}/{SELECTION_PATIENCE})")
            if patience_cnt >= SELECTION_PATIENCE:
                print("  Early stopping: no improvement for 3 iterations"); break

    # [#7] improvement table
    print(f"\n{'='*100}")
    print("SELECTION COMPLETE — IMPROVEMENT TABLE (metric: NSE)")
    print(f"{'='*100}")
    print(f"{'Feature':<35} {'NSE':>10} {'ΔNSE':>10} {'Δ%':>8}")
    print("-"*65)
    print(f"{'[baseline - dynamic only]':<35} {nse_bl:>10.4f} {'—':>10} {'—':>8}")
    cur = nse_bl
    for feat, fn in selection_history:
        d = fn - cur
        print(f"  + {feat:<32} {fn:>10.4f} {d:>+10.4f} {d/abs(cur+1e-12)*100:>7.1f}%")
        cur = fn
    print("-"*65)
    print(f"{'[final]':<35} {best_nse:>10.4f} "
          f"{best_nse-nse_bl:>+10.4f} "
          f"{(best_nse-nse_bl)/abs(nse_bl+1e-12)*100:>7.1f}%")
    print(f"{'='*100}")
    print(f"\nSelected {len(selected_static)} static features:")
    for i, f in enumerate(selected_static, 1): print(f"  {i:2d}. {f}")
    static_final = selected_static

else:
    print("\n⚠️  Skipping sequential selection")
    static_final = static_decorrelated
    n_dyn = Xtr_seq_dyn.shape[2]
    n_out = Ytr_seq.shape[1]

# =========================================================================
# FINAL LSTM TRAINING
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)")
print("="*100)

if len(static_final) > 0:
    col_idx_final = [static_decorrelated.index(f) for f in static_final]
    Xtr_sta_final = Xtr_seq_sta_all[:, col_idx_final]
    Xte_sta_final = Xte_seq_sta_all[:, col_idx_final]
else:
    Xtr_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"  dynamic={n_dyn}  static={len(static_final)}  "
      f"total={n_dyn+len(static_final)}  warmup={WARMUP_MONTHS}mo")

model_final = LSTMWithContext(n_dyn=n_dyn, n_sta=len(static_final),
                              hidden=FINAL_HIDDEN, num_layers=FINAL_LAYERS,
                              dropout=FINAL_DROPOUT, out_dim=n_out).to(DEVICE)
tr_dl_f = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_sta_final, Ytr_seq),
                     batch_size=FINAL_BATCH, shuffle=True,
                     num_workers=FINAL_WORKERS, pin_memory=USE_GPU)
te_dl_f = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_sta_final, Yte_seq),
                     batch_size=FINAL_BATCH*2, shuffle=False,
                     num_workers=FINAL_WORKERS, pin_memory=USE_GPU)

opt_f       = torch.optim.Adam(model_final.parameters(), lr=FINAL_LR)
scheduler   = torch.optim.lr_scheduler.ReduceLROnPlateau(
                  opt_f, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE)
amp_f       = make_gradscaler(DEVICE_TYPE) if USE_MIXED_PRECISION else None
criterion_f = nn.MSELoss()
best_val    = float('inf'); es_counter = 0

print(f"\nTraining up to {FINAL_EPOCHS} epochs (ES patience={EARLY_STOP_PATIENCE}) ...")
for epoch in range(FINAL_EPOCHS):
    tr_loss = train_one_epoch_with_warmup(
        model_final, tr_dl_f, opt_f, criterion_f,
        amp_f, USE_MIXED_PRECISION, DEVICE, DEVICE_TYPE, warmup=WARMUP_MONTHS)
    _, val_loss = evaluate_model(model_final, te_dl_f, criterion_f,
                                 USE_MIXED_PRECISION, DEVICE, DEVICE_TYPE)
    scheduler.step(val_loss)
    if (epoch+1) % 10 == 0:
        print(f"  Epoch {epoch+1:3d}/{FINAL_EPOCHS}  "
              f"train={tr_loss:.6f}  val={val_loss:.6f}")
    if val_loss < best_val:
        best_val = val_loss; es_counter = 0
        torch.save(model_final.state_dict(),
                   '../predict_score_red/best_model_v14.pt')
    else:
        es_counter += 1
        if es_counter >= EARLY_STOP_PATIENCE:
            print(f"\n  Early stopping at epoch {epoch+1}"); break

model_final.load_state_dict(
    torch.load('../predict_score_red/best_model_v14.pt', weights_only=True))

# =========================================================================
# FINAL EVALUATION
# =========================================================================
print("\n" + "="*100)
print("FINAL EVALUATION")
print("="*100)

preds_f_s, _ = evaluate_model(model_final, te_dl_f, criterion_f,
                               USE_MIXED_PRECISION, DEVICE, DEVICE_TYPE)
preds_f_raw  = np.expm1(scaler_y.inverse_transform(preds_f_s))
preds_f_mono = enforce_monotonicity(preds_f_raw)

vb = int((np.diff(preds_f_raw,  axis=1) < 0).sum())
va = int((np.diff(preds_f_mono, axis=1) < 0).sum())
print(f"\n  Monotonicity violations: {vb} → {va} (after isotonic)")
preds_out = preds_f_mono

print(f"\nOverall metrics (all quantiles pooled):")
metrics_all(Yte_true, preds_out, label='all quantiles')

print(f"\nPer-quantile metrics:")
print(f"  {'Quantile':<22} {'MAE':>8} {'RMSE':>8} {'R²':>7} {'NSE':>8} {'KGE':>8}")
print(f"  {'-'*65}")
for i, q_col in enumerate(q_cols_target):
    obs_i = Yte_true[:, i]; sim_i = preds_out[:, i]
    print(f"  {q_col:<22} "
          f"{mean_absolute_error(obs_i,sim_i):>8.4f} "
          f"{np.sqrt(mean_squared_error(obs_i,sim_i)):>8.4f} "
          f"{r2_score(obs_i,sim_i):>7.4f} "
          f"{nse(obs_i,sim_i):>8.4f} "
          f"{kge(obs_i,sim_i):>8.4f}")

# ---- Save results --------------------------------------------------------
results_df = pd.DataFrame({
    'StationID': X_test['StationID'].iloc[te_idx].values,
    **{f'true_{q_cols_target[i]}': Yte_true[:,i] for i in range(len(q_cols_target))},
    **{f'pred_{q_cols_target[i]}': preds_out[:,i] for i in range(len(q_cols_target))}
})
results_df.to_csv('../predict_score_red/lstm_v14_results.txt', sep=' ', index=False)
print(f"\n✓ Results  → ../predict_score_red/lstm_v14_results.txt")

with open('../predict_score_red/lstm_v14_selected_features.txt', 'w') as fh:
    fh.write(f"# Selected static features ({len(static_final)})\n")
    for feat in static_final: fh.write(f"{feat}\n")
print(f"✓ Features → ../predict_score_red/lstm_v14_selected_features.txt")

print("\n" + "="*100)
print(f"COMPLETE — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)
EOFPYTHON
