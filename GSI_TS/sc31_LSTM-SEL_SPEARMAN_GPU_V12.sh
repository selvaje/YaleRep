#!/bin/bash
#SBATCH -p day
######SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V12.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V12.err
#SBATCH --job-name=sc31_LSTM_V12
#SBATCH --mem=40G

# =============================================================================
# sc31_LSTM-SEL_SPEARMAN_GPU_V12.sh
#
# Changes vs V11  (labelled [FIX-A], [FIX-B], [FIX-C] in the code):
#
#   [FIX-A]  Static features broadcast to EVERY LSTM timestep.
#   [FIX-B]  NSE and KGE added; selection criterion changed from MAE to NSE.
#   [FIX-C]  LSTM warmup mask: first WARMUP_MONTHS excluded from loss.
#
# Preserved from V11:
#   [#1] Sliding-window sequences (STRIDE-controlled)
#   [#2] Y stores period-constant quantiles
#   [#3] Isotonic monotonicity enforcement (QMIN<=Q10<=...<=QMAX)
#   [#4] log1p/expm1 on skewed specific-discharge targets
#   [#5] assert(accumulation>0)
#   [#7] Selection improvement table
#   [#9] V12 banner and SLURM log names
#
# FIX-V12-PRINT: All f-string double-braces corrected so values print correctly.
# ============================================================================

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

python3 - <<'EOFPYTHON'
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
from torch.cuda.amp import autocast, GradScaler
from joblib import Parallel, delayed
import gc
import warnings
warnings.filterwarnings('ignore')

os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

# [#3] Monotonicity helper
_ir_mono = _IR(increasing=True, out_of_bounds='clip')
def enforce_monotonicity(arr2d):
    x_ord = np.arange(arr2d.shape[1])
    return np.array([_ir_mono.fit_transform(x_ord, row) for row in arr2d])

# [FIX-B] NSE and KGE
def nse(obs, sim):
    denom = np.sum((obs - np.mean(obs)) ** 2)
    if denom == 0:
        return np.nan
    return 1.0 - np.sum((obs - sim) ** 2) / denom

def kge(obs, sim):
    r     = _pearsonr(obs, sim)[0]
    alpha = np.std(sim)  / (np.std(obs)  + 1e-12)
    beta  = np.mean(sim) / (np.mean(obs) + 1e-12)
    return 1.0 - np.sqrt((r - 1) ** 2 + (alpha - 1) ** 2 + (beta - 1) ** 2)

def metrics_all(obs, sim, label=''):
    mae_v  = mean_absolute_error(obs, sim)
    rmse_v = np.sqrt(mean_squared_error(obs, sim))
    r2_v   = r2_score(obs, sim)
    nse_v  = nse(obs.ravel(), sim.ravel())
    kge_v  = kge(obs.ravel(), sim.ravel())
    if label:
        print(f"  {label:20s}  MAE={mae_v:.4f}  RMSE={rmse_v:.4f}  R2={r2_v:.4f}  NSE={nse_v:.4f}  KGE={kge_v:.4f}")
    return mae_v, rmse_v, r2_v, nse_v, kge_v

print("\n" + "="*100)
print("SC31: LSTM V12 - STATIC@EVERY-STEP + NSE/KGE + WARMUP-MASK")
print("="*100)
print(f"Start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Job ID: {os.environ.get('SLURM_JOB_ID', 'N/A')}")
print("="*100)

print(f"\n{'='*100}")
print("HARDWARE DETECTION")
print(f"{'='*100}")

DEVICE  = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
USE_GPU = torch.cuda.is_available()

if USE_GPU:
    print(f"  GPU DETECTED")
    print(f"  Device: {torch.cuda.get_device_name(0)}")
    print(f"  CUDA: {torch.version.cuda}")
    print(f"  Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    torch.backends.cudnn.benchmark = True
    SELECTION_BATCH     = 512
    FINAL_BATCH         = 1024
    NUM_WORKERS         = 4
    USE_MIXED_PRECISION = True
    SELECTION_HIDDEN    = 64
    FINAL_HIDDEN        = 128
else:
    print(f"  WARNING: CPU MODE (no GPU detected)")
    print(f"  Cores: {os.cpu_count()}")
    SELECTION_BATCH     = 128
    FINAL_BATCH         = 256
    NUM_WORKERS         = 2
    USE_MIXED_PRECISION = False
    SELECTION_HIDDEN    = 32
    FINAL_HIDDEN        = 64

print(f"\nSettings: batch={FINAL_BATCH}, workers={NUM_WORKERS}, amp={USE_MIXED_PRECISION}")

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
print(f"  Sequence length:        {SEQ_LEN} months (11 years)")
print(f"  Sliding-window stride:  {STRIDE}")
print(f"  Warmup months (loss):   {WARMUP_MONTHS}  [FIX-C]")
print(f"  Sequential selection:   {USE_SEQUENTIAL_SELECTION}")
print(f"  Max static features:    {MAX_STATIC_FEATURES}")
print(f"  Spearman threshold:     {SPEARMAN_STATION_THRESHOLD}")
print(f"\nSelection phase (lightweight):")
print(f"  Hidden={SELECTION_HIDDEN}, Layers={SELECTION_LAYERS}, Epochs={SELECTION_EPOCHS}")
print(f"\nFinal phase:")
print(f"  Hidden={FINAL_HIDDEN}, Layers={FINAL_LAYERS}, Epochs={FINAL_EPOCHS}")
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
print("PHASE 1: LOAD DATA (X AND Y ALREADY ALIGNED)")
print("="*100)

load_start = datetime.now()
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
load_time = (datetime.now() - load_start).total_seconds()

print(f"  Loaded in {load_time:.1f}s: X {X.shape}, Y {Y.shape}")
print(f"  X and Y are already aligned from sc29 script - preserving row order")

if len(X) != len(Y):
    print(f"  ERROR: X and Y have different lengths! X={len(X)}, Y={len(Y)}")
    sys.exit(1)

if not (X['IDr'] == Y['IDr']).all():
    print("  WARNING: IDr mismatch between X and Y")
if not (X['YYYY'] == Y['YYYY']).all():
    print("  WARNING: YYYY mismatch between X and Y")
if not (X['MM'] == Y['MM']).all():
    print("  WARNING: MM mismatch between X and Y")

static_present  = [v for v in static_var  if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]

print(f"  Variables: {len(static_present)} static, {len(dynamic_present)} dynamic, {len(q_cols)} targets")

if 'IDs' in X.columns:
    X['StationID'] = X['IDr'].astype(str) + '_' + X['IDs'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str) + '_' + Y['IDs'].astype(str)
    print("  Using IDr + IDs as unique station identifier")
else:
    X['StationID'] = X['IDr'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str)
    print("  Using IDr only as station identifier (IDs not found)")

n_unique = X['StationID'].nunique()
print(f"  Unique stations: {n_unique}")

# =========================================================================
# PHASE 2: CHECK CONSECUTIVE MONTHS
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 2: CHECK {SEQ_LEN} CONSECUTIVE MONTHS (FULL DATASET)")
print("="*100)

def check_consecutive_months(df, min_length):
    station_consecutive = {}
    for station, group in df.groupby('StationID'):
        group = group.sort_values(['YYYY', 'MM']).reset_index(drop=True)
        group['date'] = pd.to_datetime(
            group['YYYY'].astype(str) + '-' + group['MM'].astype(str).str.zfill(2) + '-01')
        max_consecutive     = 0
        current_consecutive = 1
        for i in range(1, len(group)):
            expected = group.loc[i-1, 'date'] + pd.DateOffset(months=1)
            if expected == group.loc[i, 'date']:
                current_consecutive += 1
                max_consecutive = max(max_consecutive, current_consecutive)
            else:
                current_consecutive = 1
        if len(group) == 1:
            max_consecutive = 1
        station_consecutive[station] = max_consecutive
    return station_consecutive

n_stations_before = X['StationID'].nunique()
print(f"Analyzing {n_stations_before} stations...")
station_months = check_consecutive_months(X, SEQ_LEN)

valid_stations   = [s for s, m in station_months.items() if m >= SEQ_LEN]
invalid_stations = [s for s, m in station_months.items() if m <  SEQ_LEN]

n_total   = len(station_months)
n_valid   = len(valid_stations)
n_invalid = len(invalid_stations)
print(f"\n  Total stations:                {n_total}")
print(f"  Valid   (>= {SEQ_LEN} consec.): {n_valid}")
print(f"  Invalid (<  {SEQ_LEN} consec.): {n_invalid} DISCARDED")

if n_invalid > 0:
    inv_m = [station_months[s] for s in invalid_stations]
    print(f"  Discarded - mean consec.: {np.mean(inv_m):.1f}, max: {np.max(inv_m):.0f}")

if n_valid == 0:
    print(f"\n  ERROR: No stations have {SEQ_LEN} consecutive months!")
    print(f"  Maximum available: {max(station_months.values())}")
    sys.exit(1)

print(f"\nFiltering to {n_valid} valid stations...")
X = X[X['StationID'].isin(valid_stations)].reset_index(drop=True)
Y = Y[Y['StationID'].isin(valid_stations)].reset_index(drop=True)
print(f"After filter: X={len(X)}, Y={len(Y)}")

# =========================================================================
# PHASE 3: DERIVED DYNAMIC FEATURES
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: CREATE DERIVED FEATURES")
print("="*100)

acc = X['accumulation'].astype('float32').values
assert (acc > 0).all(), "accumulation must be strictly positive in all rows"

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

n_derived = len(derived_features)
print(f"  Created {n_derived} derived features")
dynamic_final = derived_features.copy()
del acc
gc.collect()

# =========================================================================
# PHASE 4: SPECIFIC DISCHARGE TARGETS
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: CREATE SPECIFIC DISCHARGE")
print("="*100)

Y_acc = X['accumulation'].values.astype('float32')
assert (Y_acc > 0).all(), "accumulation must be strictly positive in all rows"

q_cols_specific = []
for q_col in q_cols:
    q_sp = f'{q_col}_specific'
    Y[q_sp] = (Y[q_col].values / Y_acc).astype('float32')
    q_cols_specific.append(q_sp)

q_cols_target = q_cols_specific
n_targets = len(q_cols_specific)
print(f"  Created {n_targets} specific discharge targets (m3/s/km2)")
del Y_acc
gc.collect()

# =========================================================================
# PHASE 5: SPEARMAN DECORRELATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL)")
print("="*100)

def decorrelate_by_spearman_fast(X_df, groups, threshold):
    n_input = len(X_df.columns)
    print(f"  Input: {n_input} features, threshold={threshold}")
    df = X_df.copy()
    df['__g__'] = groups
    df_station = df.groupby('__g__', observed=True).mean(numeric_only=True)
    df_station = df_station.replace([np.inf, -np.inf], np.nan).fillna(df_station.median())
    n_st = len(df_station)
    print(f"  Aggregated to {n_st} stations")
    del df
    gc.collect()
    corr_matrix = df_station.corr(method='spearman').abs()
    corr_array  = corr_matrix.to_numpy().copy()
    np.fill_diagonal(corr_array, 0)
    corr_matrix = pd.DataFrame(corr_array, index=corr_matrix.index, columns=corr_matrix.columns)
    features = list(df_station.columns)
    to_drop  = set()
    kept     = []
    for feat in features:
        if feat in to_drop:
            continue
        kept.append(feat)
        high_corr = corr_matrix.loc[feat][corr_matrix.loc[feat] > threshold].index.tolist()
        for cf in high_corr:
            if cf != feat and cf not in kept:
                to_drop.add(cf)
    n_kept = len(kept)
    n_drop = len(to_drop)
    print(f"  Output: {n_kept} KEPT, {n_drop} DISCARDED")
    del df_station, corr_matrix
gc.collect()
    return kept

X_static_df = X[[c for c in static_present if c in X.columns]]
static_decorrelated = decorrelate_by_spearman_fast(
    X_static_df, X['StationID'].to_numpy(), SPEARMAN_STATION_THRESHOLD)
n_sta_before = len(static_present)
n_sta_after  = len(static_decorrelated)
print(f"\n  Spearman complete: {n_sta_before} -> {n_sta_after} features")
del X_static_df
gc.collect()

# =========================================================================
# PHASE 6: TEMPORAL SPLIT
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: TEMPORAL SPLIT (PER-STATION, PARALLELISED)")
print("="*100)

def split_station_temporal(station_data, train_years=11, test_years=11):
    station_data = station_data.sort_values(['YYYY','MM']).reset_index(drop=True)
    total        = len(station_data)
    tr_m         = train_years * 12
    te_m         = test_years  * 12
    sid          = station_data['StationID'].iloc[0]
    if total < tr_m + te_m:
        return {'station_id': sid, 'train_idx': np.array([]), 'test_idx': np.array([]),
                'total_months': total, 'skipped': True, 'train_dates': None, 'test_dates': None}
    tr_idx = station_data.index[:tr_m].values
    te_idx = station_data.index[tr_m:tr_m + te_m].values
    tr_d   = (station_data.iloc[0]['YYYY'],      station_data.iloc[0]['MM'],
              station_data.iloc[tr_m-1]['YYYY'],  station_data.iloc[tr_m-1]['MM'])
    te_d   = (station_data.iloc[tr_m]['YYYY'],    station_data.iloc[tr_m]['MM'],
              station_data.iloc[tr_m+te_m-1]['YYYY'], station_data.iloc[tr_m+te_m-1]['MM'])
    return {'station_id': sid, 'train_idx': tr_idx, 'test_idx': te_idx,
            'total_months': total, 'skipped': False, 'train_dates': tr_d, 'test_dates': te_d}

n_split = X['StationID'].nunique()
print(f"Splitting {n_split} stations using {NCPU} cores...")
t0 = datetime.now()
results = Parallel(n_jobs=NCPU)(
    delayed(split_station_temporal)(g, TRAIN_YEARS, TEST_YEARS)
    for _, g in X.groupby('StationID'))
t_split = (datetime.now() - t0).total_seconds()
print(f"  Split completed in {t_split:.1f}s")

train_indices    = []
test_indices     = []
skipped_stations = []
for r in results:
    if r['skipped']:
        skipped_stations.append(r['station_id'])
    else:
        train_indices.extend(r['train_idx'].tolist())
        test_indices.extend(r['test_idx'].tolist())

n_proc    = len(results)
n_val_sp  = n_proc - len(skipped_stations)
n_skip_sp = len(skipped_stations)
print(f"  Processed: {n_proc}, Valid: {n_val_sp}, Skipped: {n_skip_sp}")

if not train_indices:
    print("\n  ERROR: No training data after temporal split!")
    sys.exit(1)
if not test_indices:
    print("\n  ERROR: No test data after temporal split!")
    sys.exit(1)

X_train = X.loc[train_indices].copy().reset_index(drop=True)
Y_train = Y.loc[train_indices].copy().reset_index(drop=True)
X_test  = X.loc[test_indices].copy().reset_index(drop=True)
Y_test  = Y.loc[test_indices].copy().reset_index(drop=True)

n_tr_rows  = len(X_train)
n_te_rows  = len(X_test)
n_tr_st    = X_train['StationID'].nunique()
n_te_st    = X_test['StationID'].nunique()
print(f"\nTemporal split summary:")
print(f"  Train: {n_tr_rows:,} rows, {n_tr_st} stations")
print(f"  Test:  {n_te_rows:,} rows, {n_te_st} stations")
print(f"  Train date range: {X_train['YYYY'].min()}-{X_train['MM'].min():02d} to "
      f"{X_train['YYYY'].max()}-{X_train['MM'].max():02d}")
print(f"  Test  date range: {X_test['YYYY'].min()}-{X_test['MM'].min():02d} to "
      f"{X_test['YYYY'].max()}-{X_test['MM'].max():02d}")

sr = [r for r in results if not r['skipped']][0]
print(f"\n  Sample station ({sr['station_id']}):")
print(f"    Train: {sr['train_dates'][0]}-{sr['train_dates'][1]:02d} to "
      f"{sr['train_dates'][2]}-{sr['train_dates'][3]:02d}")
print(f"    Test:  {sr['test_dates'][0]}-{sr['test_dates'][1]:02d} to "
      f"{sr['test_dates'][2]}-{sr['test_dates'][3]:02d}")

del results, train_indices, test_indices
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

Y_train_log = np.log1p(Y_train_qdf.to_numpy()).astype('float32')
Y_test_log  = np.log1p(Y_test_qdf.to_numpy()).astype('float32')
Y_train_s   = scaler_y.fit_transform(Y_train_log).astype('float32')
Y_test_s    = scaler_y.transform(Y_test_log).astype('float32')
print("  Scaling complete (log1p applied to discharge targets)")

print("\nBuilding sequences ...")

def build_sequences(df_meta, X_dyn, X_sta, Y_arr, seq_len=132, stride=1):
    """
    Sliding-window LSTM sequences.
    [#2] Y is period-constant per station.
    [FIX-A] x_sta broadcast inside model forward().
    """
    df = df_meta.copy().sort_values(['StationID','YYYY','MM']).reset_index(drop=True)
    Xd, Xs, Yl, Il = [], [], [], []
    for _, group in df.groupby('StationID'):
        indices = group.index.tolist()
        n = len(indices)
        if n < seq_len:
            continue
        for start in range(0, n - seq_len + 1, stride):
            end  = start + seq_len
            last = indices[end - 1]
            Xd.append(X_dyn[indices[start:end]])
            Xs.append(X_sta[last])
            Yl.append(Y_arr[last])
            Il.append(last)
    return (np.array(Xd,  dtype=np.float32), np.array(Xs,  dtype=np.float32),
            np.array(Yl,  dtype=np.float32), np.array(Il,  dtype=np.int64))

Xtr_meta = X_train[['StationID','YYYY','MM']]
Xte_meta = X_test[['StationID','YYYY','MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN, STRIDE)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s,  Y_test_s,  SEQ_LEN, STRIDE)

n_tr_seq = Xtr_seq_dyn.shape[0]
n_te_seq = Xte_seq_dyn.shape[0]
print(f"  Train sequences: {n_tr_seq:,}  (stride={STRIDE})")
print(f"  Test  sequences: {n_te_seq:,}  (stride={STRIDE})")
print(f"  Sequence shape:  {Xtr_seq_dyn.shape}")

if n_tr_seq == 0:
    print(f"\n  ERROR: No training sequences created!")
    print(f"  Check that stations have at least {SEQ_LEN} consecutive months")
    sys.exit(1)
if n_te_seq == 0:
    print("\n  ERROR: No test sequences created!")
    sys.exit(1)

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

# =========================================================================
# MODEL - [FIX-A] STATIC BROADCAST TO EVERY TIMESTEP
# =========================================================================
class StaticEncoder(nn.Module):
    def __init__(self, n_sta, enc_dim, dropout):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_sta, enc_dim),
            nn.ReLU(),
            nn.Dropout(dropout))
    def forward(self, x):
        return self.net(x)

class LSTMWithContext(nn.Module):
    """
    [FIX-A] Static tiled to every timestep before LSTM.
    x_sta -> encode -> tile -> cat(x_dyn) -> LSTM -> head -> Q*
    """
    def __init__(self, n_dyn, n_sta, hidden, num_layers, dropout, out_dim):
        super().__init__()
        if n_sta > 0:
            self.enc_dim        = max(8, n_sta // 2)
            self.static_encoder = StaticEncoder(n_sta, self.enc_dim, dropout)
        else:
            self.enc_dim        = 0
            self.static_encoder = None
        self.lstm = nn.LSTM(
            input_size    = n_dyn + self.enc_dim,
            hidden_size   = hidden,
            num_layers    = num_layers,
            batch_first   = True,
            dropout       = dropout if num_layers > 1 else 0.0,
            bidirectional = False)
        self.head = nn.Sequential(
            nn.Linear(hidden, 128),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(128, out_dim))

    def forward(self, x_dyn, x_sta):
        if self.static_encoder is not None and x_sta.shape[1] > 0:
            sta_enc  = self.static_encoder(x_sta)
            sta_tile = sta_enc.unsqueeze(1).expand(-1, x_dyn.shape[1], -1)
            x_in     = torch.cat([x_dyn, sta_tile], dim=-1)
        else:
            x_in = x_dyn
        out, _ = self.lstm(x_in)
        return self.head(out[:, -1, :])

class LSTMDataset(Dataset):
    def __init__(self, Xd, Xs, Y):
        self.Xd = torch.from_numpy(Xd)
        self.Xs = torch.from_numpy(Xs)
        self.Y  = torch.from_numpy(Y)
    def __len__(self):  return len(self.Xd)
    def __getitem__(self, i): return self.Xd[i], self.Xs[i], self.Y[i]

# [FIX-C] Warmup training step
def train_one_epoch_with_warmup(model, loader, optimizer, criterion,
                                scaler_amp, use_amp, device, warmup=0):
    model.train()
    total = 0.0
    for xd, xs, y in loader:
        xd, xs, y = xd.to(device), xs.to(device), y.to(device)
        optimizer.zero_grad()
        if warmup > 0 and xd.shape[1] > warmup:
            xw = xd[:, :warmup, :]
            xp = xd[:, warmup:, :]
            if model.static_encoder is not None and xs.shape[1] > 0:
                se  = model.static_encoder(xs)
                xw  = torch.cat([xw, se.unsqueeze(1).expand(-1, warmup,         -1)], dim=-1)
                xp  = torch.cat([xp, se.unsqueeze(1).expand(-1, xp.shape[1],    -1)], dim=-1)
            with torch.no_grad():
                if use_amp:
                    with autocast(): _, (h, c) = model.lstm(xw)
                else:              _, (h, c) = model.lstm(xw)
            h, c = h.detach(), c.detach()
            if use_amp:
                with autocast():
                    o,_ = model.lstm(xp,(h,c)); loss = criterion(model.head(o[:,-1,:]),y)
                scaler_amp.scale(loss).backward(); scaler_amp.step(optimizer); scaler_amp.update()
            else:
                o,_ = model.lstm(xp,(h,c)); loss = criterion(model.head(o[:,-1,:]),y)
                loss.backward(); optimizer.step()
        else:
            if use_amp:
                with autocast(): loss = criterion(model(xd,xs),y)
                scaler_amp.scale(loss).backward(); scaler_amp.step(optimizer); scaler_amp.update()
            else:
                loss = criterion(model(xd,xs),y); loss.backward(); optimizer.step()
        total += loss.item()
    return total / len(loader)

def evaluate_model(model, loader, criterion, use_amp, device):
    model.eval()
    preds, vl = [], 0.0
    with torch.no_grad():
        for xd, xs, y in loader:
            xd, xs, y = xd.to(device), xs.to(device), y.to(device)
            if use_amp:
                with autocast(): p = model(xd,xs); loss = criterion(p,y)
            else:              p = model(xd,xs); loss = criterion(p,y)
            vl += loss.item(); preds.append(p.cpu().numpy())
    return np.vstack(preds), vl / len(loader)

def decode_preds(ps, sy):
    return enforce_monotonicity(np.expm1(sy.inverse_transform(ps)))

# =========================================================================
# SEQUENTIAL FORWARD SELECTION - [FIX-B] NSE criterion
# =========================================================================
if USE_SEQUENTIAL_SELECTION and len(static_decorrelated) > 0:
    print("\n" + "="*100)
    print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES) - metric: NSE")
    print("="*100)

    selected_static   = []
    remaining_static  = static_decorrelated.copy()
    selection_history = []

    n_dyn = Xtr_seq_dyn.shape[2]
    n_out = Ytr_seq.shape[1]

    print("\n--- BASELINE: Dynamic features only ---")
    model_bl = LSTMWithContext(n_dyn=n_dyn, n_sta=0, hidden=SELECTION_HIDDEN,
                               num_layers=SELECTION_LAYERS, dropout=SELECTION_DROPOUT, out_dim=n_out).to(DEVICE)
    Xtr_e = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_e = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

    tr_dl_bl = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_e, Ytr_seq),
                          batch_size=SELECTION_BATCH, shuffle=True,  num_workers=NUM_WORKERS, pin_memory=USE_GPU)
    te_dl_bl = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_e, Yte_seq),
                          batch_size=SELECTION_BATCH*2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
    opt_bl    = torch.optim.Adam(model_bl.parameters(), lr=SELECTION_LR)
    criterion = nn.MSELoss()
    amp_sc    = GradScaler() if USE_MIXED_PRECISION else None

    for ep in range(SELECTION_EPOCHS):
        train_one_epoch_with_warmup(model_bl, tr_dl_bl, opt_bl, criterion, amp_sc, USE_MIXED_PRECISION, DEVICE, 0)

    ps_bl, _ = evaluate_model(model_bl, te_dl_bl, criterion, USE_MIXED_PRECISION, DEVICE)
    pb       = decode_preds(ps_bl, scaler_y)
    _, _, _, nse_bl, kge_bl = metrics_all(Yte_true, pb, label='baseline')

    best_nse  = nse_bl
    pat_cnt   = 0
    n_rem_init = len(remaining_static)
    print(f"\n--- FORWARD SELECTION (max {MAX_STATIC_FEATURES} features, metric=NSE) ---")
    print(f"  Starting pool: {n_rem_init} candidate features")

    for iteration in range(MAX_STATIC_FEATURES):
        if not remaining_static:
            print("\n  No more features to add")
            break
        n_rem = len(remaining_static)
        print(f"\n[Iteration {iteration+1}] Testing {n_rem} candidates ...")
        cand_res = []

        for cand in remaining_static:
            cur     = selected_static + [cand]
            ci      = [static_decorrelated.index(f) for f in cur]
            Xtr_c   = Xtr_seq_sta_all[:, ci]
            Xte_c   = Xte_seq_sta_all[:, ci]
            model_c = LSTMWithContext(n_dyn=n_dyn, n_sta=len(cur), hidden=SELECTION_HIDDEN,
                                     num_layers=SELECTION_LAYERS, dropout=SELECTION_DROPOUT, out_dim=n_out).to(DEVICE)
            tr_dl_c = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_c, Ytr_seq),
                                 batch_size=SELECTION_BATCH, shuffle=True, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
            te_dl_c = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_c, Yte_seq),
                                 batch_size=SELECTION_BATCH*2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
            opt_c = torch.optim.Adam(model_c.parameters(), lr=SELECTION_LR)
            for ep in range(SELECTION_EPOCHS):
                train_one_epoch_with_warmup(model_c, tr_dl_c, opt_c, criterion, amp_sc, USE_MIXED_PRECISION, DEVICE, 0)
            ps_c, _ = evaluate_model(model_c, te_dl_c, criterion, USE_MIXED_PRECISION, DEVICE)
            pc       = decode_preds(ps_c, scaler_y)
            nse_c    = nse(Yte_true.ravel(), pc.ravel())
            cand_res.append((cand, nse_c))
            del model_c
gc.collect()
            if USE_GPU: torch.cuda.empty_cache()

        cand_res.sort(key=lambda x: x[1], reverse=True)
        best_c, best_c_nse = cand_res[0]
        print(f"  Best candidate: {best_c} (NSE: {best_c_nse:.4f})")

        if best_c_nse > best_nse:
            imp = best_c_nse - best_nse
            print(f"  ADDED (delta_NSE: +{imp:.4f})")
            selected_static.append(best_c)
            remaining_static.remove(best_c)
            selection_history.append((best_c, best_c_nse))
            best_nse = best_c_nse
            pat_cnt  = 0
        else:
            pat_cnt += 1
            print(f"  No improvement (patience: {pat_cnt}/{SELECTION_PATIENCE})")
            if pat_cnt >= SELECTION_PATIENCE:
                print("\n  Early stopping: no improvement for 3 iterations")
                break

    print(f"\n{'='*100}")
    print("SELECTION COMPLETE - IMPROVEMENT TABLE (metric: NSE)")
    print(f"{'='*100}")
    print(f"{'Feature':<35} {'NSE':>10} {'delta_NSE':>12} {'delta_%':>9}")
    print("-" * 68)
    print(f"{'[baseline - dynamic only]':<35} {nse_bl:>10.4f} {'---':>12} {'---':>9}")
    cur_nse = nse_bl
    for feat, feat_nse in selection_history:
        d   = feat_nse - cur_nse
        dp  = d / (abs(cur_nse) + 1e-12) * 100
        print(f"  + {feat:<32} {feat_nse:>10.4f} {d:>+12.4f} {dp:>8.1f}%")
        cur_nse = feat_nse
    print("-" * 68)
    td   = best_nse - nse_bl
    tdp  = td / (abs(nse_bl) + 1e-12) * 100
    print(f"{'[final]':<35} {best_nse:>10.4f} {td:>+12.4f} {tdp:>8.1f}%")
    print(f"{'='*100}")

    n_sel = len(selected_static)
    print(f"\nSelected {n_sel} static features:")
    for i, feat in enumerate(selected_static, 1):
        print(f"  {i:2d}. {feat}")

else:
    print("\n  WARNING: Skipping sequential selection (disabled or no static features)")
    static_final = static_decorrelated

# =========================================================================
# FINAL TRAINING
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)")
print("="*100)

n_dyn = Xtr_seq_dyn.shape[2]
n_out = Ytr_seq.shape[1]
n_sta_fin = len(static_final)

if n_sta_fin > 0:
    ci_fin            = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, ci_fin]
    Xte_seq_sta_final = Xte_seq_sta_all[:, ci_fin]
else:
    Xtr_seq_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_seq_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"Final features: Dynamic={n_dyn}, Static={n_sta_fin}, Total={n_dyn+n_sta_fin}")

model_final = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta_fin, hidden=FINAL_HIDDEN,
                              num_layers=FINAL_LAYERS, dropout=FINAL_DROPOUT, out_dim=n_out).to(DEVICE)

tr_dl_fin = DataLoader(LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq),
                       batch_size=FINAL_BATCH,   shuffle=True,  num_workers=NUM_WORKERS, pin_memory=USE_GPU)
te_dl_fin = DataLoader(LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq),
                       batch_size=FINAL_BATCH*2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)

opt_fin   = torch.optim.Adam(model_final.parameters(), lr=FINAL_LR)
sched     = torch.optim.lr_scheduler.ReduceLROnPlateau(opt_fin, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE)
amp_fin   = GradScaler() if USE_MIXED_PRECISION else None
criterion = nn.MSELoss()

print(f"\nTraining for {FINAL_EPOCHS} epochs (warmup={WARMUP_MONTHS} months) ...")
print(f"  Early stopping patience: {EARLY_STOP_PATIENCE}")

best_vl = float('inf')
es_cnt  = 0

for epoch in range(FINAL_EPOCHS):
    tr_loss = train_one_epoch_with_warmup(
        model_final, tr_dl_fin, opt_fin, criterion, amp_fin, USE_MIXED_PRECISION, DEVICE, WARMUP_MONTHS)
    _, vl = evaluate_model(model_final, te_dl_fin, criterion, USE_MIXED_PRECISION, DEVICE)
    sched.step(vl)
    if (epoch + 1) % 10 == 0:
        print(f"  Epoch {epoch+1}/{FINAL_EPOCHS} - Train: {tr_loss:.6f}, Val: {vl:.6f}")
    if vl < best_vl:
        best_vl = vl; es_cnt = 0
        torch.save(model_final.state_dict(), '../predict_score_red/best_model_v12.pt')
    else:
        es_cnt += 1
        if es_cnt >= EARLY_STOP_PATIENCE:
            print(f"\n  Early stopping at epoch {epoch+1}")
            break

model_final.load_state_dict(torch.load('../predict_score_red/best_model_v12.pt', map_location=DEVICE))

# =========================================================================
# FINAL EVALUATION
# =========================================================================
print("\n" + "="*100)
print("FINAL EVALUATION")
print("="*100)

ps_fin, _ = evaluate_model(model_final, te_dl_fin, criterion, USE_MIXED_PRECISION, DEVICE)
praw      = np.expm1(scaler_y.inverse_transform(ps_fin))
pmono     = enforce_monotonicity(praw)

viol_bf  = int((np.diff(praw,  axis=1) < 0).sum())
viol_af  = int((np.diff(pmono, axis=1) < 0).sum())
print(f"\n  Monotonicity violations: {viol_bf} -> {viol_af} (after isotonic)")

mae_f, rmse_f, r2_f, nse_f, kge_f = metrics_all(Yte_true, pmono, label='Overall')

print(f"\n  Overall: MAE={mae_f:.4f}  RMSE={rmse_f:.4f}  R2={r2_f:.4f}  NSE={nse_f:.4f}  KGE={kge_f:.4f}")

print(f"\n  Per-quantile metrics:")
for i, qc in enumerate(q_cols_target):
    mae_q  = mean_absolute_error(Yte_true[:,i], pmono[:,i])
    rmse_q = np.sqrt(mean_squared_error(Yte_true[:,i], pmono[:,i]))
    r2_q   = r2_score(Yte_true[:,i], pmono[:,i])
    nse_q  = nse(Yte_true[:,i], pmono[:,i])
    kge_q  = kge(Yte_true[:,i], pmono[:,i])
    print(f"  {qc:20s}  MAE={mae_q:8.4f}  RMSE={rmse_q:8.4f}  R2={r2_q:7.4f}  NSE={nse_q:7.4f}  KGE={kge_q:7.4f}")

res_df = pd.DataFrame({
    'StationID': X_test['StationID'].iloc[te_idx].values,
    **{f'true_{q_cols_target[i]}': Yte_true[:,i] for i in range(len(q_cols_target))},
    **{f'pred_{q_cols_target[i]}': pmono[:,i]     for i in range(len(q_cols_target))}
})
res_df.to_csv('../predict_score_red/lstm_v12_results.txt', sep=' ', index=False)
print(f"\n  Saved: ../predict_score_red/lstm_v12_results.txt")

with open('../predict_score_red/lstm_v12_selected_features.txt', 'w') as fh:
    fh.write(f"# Selected static features ({len(static_final)})\n")
    for feat in static_final:
        fh.write(f"{feat}\n")
print(f"  Saved: ../predict_score_red/lstm_v12_selected_features.txt")

print("\n" + "="*100)
print(f"COMPLETE - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)
EOFPYTHON