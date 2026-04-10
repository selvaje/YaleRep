#!/bin/bash
#SBATCH -p day
######SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V10_FIXED.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V10_FIXED.%J.err
#SBATCH --job-name=sc31_LSTM_V10
#SBATCH --mem=40G

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
from scipy.stats import spearmanr
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
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

print("\n" + "="*100)
print("SC31: LSTM V10 - FIXED TEMPORAL SPLIT + SEQUENTIAL SELECTION")
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

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
USE_GPU = torch.cuda.is_available()

if USE_GPU:
    print(f"✓ GPU DETECTED")
    print(f"  Device: {torch.cuda.get_device_name(0)}")
    print(f"  CUDA: {torch.version.cuda}")
    print(f"  Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    torch.backends.cudnn.benchmark = True
    
    # GPU settings
    SELECTION_BATCH = 512
    FINAL_BATCH = 1024
    NUM_WORKERS = 4
    USE_MIXED_PRECISION = True
    SELECTION_HIDDEN = 64
    FINAL_HIDDEN = 128
else:
    print(f"⚠️ CPU MODE (no GPU detected)")
    print(f"  Cores: {os.cpu_count()}")
    
    # CPU settings
    SELECTION_BATCH = 128
    FINAL_BATCH = 256
    NUM_WORKERS = 2
    USE_MIXED_PRECISION = False
    SELECTION_HIDDEN = 32
    FINAL_HIDDEN = 64

print(f"\nSettings: batch={FINAL_BATCH}, workers={NUM_WORKERS}, amp={USE_MIXED_PRECISION}")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', os.cpu_count()))

# Feature Selection
SPEARMAN_STATION_THRESHOLD = 0.90
USE_SEQUENTIAL_SELECTION = True
MAX_STATIC_FEATURES = 20
SELECTION_PATIENCE = 3

# Temporal
TRAIN_YEARS = 11
TEST_YEARS = 11
RANDOM_STATE = 24

# LSTM - Selection phase (lightweight)
SEQ_LEN = 132  # 11 years × 12 months
SELECTION_LAYERS = 1
SELECTION_DROPOUT = 0.1
SELECTION_EPOCHS = 15
SELECTION_LR = 1e-3

# LSTM - Final phase (full capacity)
FINAL_LAYERS = 2
FINAL_DROPOUT = 0.3
FINAL_EPOCHS = 100
FINAL_LR = 1e-3
LR_PATIENCE = 10
LR_FACTOR = 0.5
EARLY_STOP_PATIENCE = 20

print(f"\n{'='*100}")
print("CONFIGURATION")
print(f"{'='*100}")
print(f"  Sequence length: {SEQ_LEN} months (11 years)")
print(f"  Sequential selection: {USE_SEQUENTIAL_SELECTION}")
print(f"  Max static features: {MAX_STATIC_FEATURES}")
print(f"  Spearman threshold: {SPEARMAN_STATION_THRESHOLD}")
print(f"\nSelection phase (lightweight for speed):")
print(f"  Hidden: {SELECTION_HIDDEN}, Layers: {SELECTION_LAYERS}, Epochs: {SELECTION_EPOCHS}")
print(f"\nFinal phase (full capacity):")
print(f"  Hidden: {FINAL_HIDDEN}, Layers: {FINAL_LAYERS}, Epochs: {FINAL_EPOCHS}")
print(f"{'='*100}")

# Data Files - CORRECTED TO X11/Y11
DATA_X = 'stationID_x_y_valueALL_predictors_X1_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y1_floredSFD.txt'

# Variables
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
# PHASE 1: LOAD DATA - PRESERVE ROW ORDER
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: LOAD DATA (X AND Y ALREADY ALIGNED)")
print("="*100)

load_start = datetime.now()
# Read WITHOUT resetting index - preserve original row order from sc29 script
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
load_time = (datetime.now() - load_start).total_seconds()

print(f"✓ Loaded in {load_time:.1f}s: X {X.shape}, Y {Y.shape}")
print(f"  X and Y are already aligned from sc29 script - preserving row order")

# Verify alignment
if len(X) != len(Y):
    print(f"❌ ERROR: X and Y have different lengths! X={len(X)}, Y={len(Y)}")
    sys.exit(1)

# Check if key columns match
if not (X['IDr'] == Y['IDr']).all():
    print(f"⚠️ WARNING: IDr mismatch between X and Y")
if not (X['YYYY'] == Y['YYYY']).all():
    print(f"⚠️ WARNING: YYYY mismatch between X and Y")
if not (X['MM'] == Y['MM']).all():
    print(f"⚠️ WARNING: MM mismatch between X and Y")

static_present = [v for v in static_var if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]

print(f"Variables: {len(static_present)} static, {len(dynamic_present)} dynamic, {len(q_cols)} targets")

# Create unique station identifier: IDr + IDs
if 'IDs' in X.columns:
    X['StationID'] = X['IDr'].astype(str) + '_' + X['IDs'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str) + '_' + Y['IDs'].astype(str)
    print(f"  Using IDr + IDs as unique station identifier")
else:
    X['StationID'] = X['IDr'].astype(str)
    Y['StationID'] = Y['IDr'].astype(str)
    print(f"  Using IDr only as station identifier (IDs not found)")

print(f"Unique stations: {X['StationID'].nunique()}")

# =========================================================================
# PHASE 2: CHECK 132 CONSECUTIVE MONTHS (FULL DATASET)
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 2: CHECK {SEQ_LEN} CONSECUTIVE MONTHS (FULL DATASET)")
print("="*100)

def check_consecutive_months(df, min_length):
    """Check max consecutive months per station"""
    station_consecutive = {}
    
    for station, group in df.groupby('StationID'):
        group = group.sort_values(['YYYY', 'MM']).reset_index(drop=True)
        group['date'] = pd.to_datetime(
            group['YYYY'].astype(str) + '-' + group['MM'].astype(str).str.zfill(2) + '-01'
        )
        
        max_consecutive = 0
        current_consecutive = 1
        
        for i in range(1, len(group)):
            expected_date = group.loc[i-1, 'date'] + pd.DateOffset(months=1)
            actual_date = group.loc[i, 'date']
            
            if expected_date == actual_date:
                current_consecutive += 1
                max_consecutive = max(max_consecutive, current_consecutive)
            else:
                current_consecutive = 1
        
        if len(group) == 1:
            max_consecutive = 1
        
        station_consecutive[station] = max_consecutive
    
    return station_consecutive

print(f"Analyzing {X['StationID'].nunique()} stations...")
station_months = check_consecutive_months(X, SEQ_LEN)

valid_stations = [sid for sid, months in station_months.items() if months >= SEQ_LEN]
invalid_stations = [sid for sid, months in station_months.items() if months < SEQ_LEN]

print(f"\n  Total stations: {len(station_months)}")
print(f"  Valid (≥{SEQ_LEN} consecutive): {len(valid_stations)}")
print(f"  Invalid (<{SEQ_LEN} consecutive): {len(invalid_stations)} (DISCARDED)")

if len(invalid_stations) > 0:
    invalid_months = [station_months[sid] for sid in invalid_stations]
    print(f"\n  Discarded stats:")
    print(f"    Mean consecutive: {np.mean(invalid_months):.1f}")
    print(f"    Max consecutive: {np.max(invalid_months):.0f}")

if len(valid_stations) == 0:
    print(f"\n❌ ERROR: No stations have {SEQ_LEN} consecutive months!")
    print(f"  Maximum available: {max(station_months.values())}")
    sys.exit(1)

# Filter to valid stations
print(f"\nFiltering to {len(valid_stations)} valid stations...")
X = X[X['StationID'].isin(valid_stations)].reset_index(drop=True)
Y = Y[Y['StationID'].isin(valid_stations)].reset_index(drop=True)

print(f"After filter: X={len(X)}, Y={len(Y)}")

del station_months
gc.collect()

# =========================================================================
# PHASE 3: CREATE DERIVED FEATURES
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: CREATE DERIVED FEATURES")
print("="*100)

acc = X['accumulation'].astype('float32').values
acc_safe = np.where(acc == 0, 1e-10, acc)

accumulated_vars = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'soil0', 'soil1', 'soil2', 'soil3',
    'GRWLw'
]

derived_features = []
for var in accumulated_vars:
    if var in X.columns:
        X[f'{var}_mean'] = (X[var].astype('float32').values / acc_safe).astype('float32')
        derived_features.append(f'{var}_mean')

print(f"✓ Created {len(derived_features)} derived features")
dynamic_final = derived_features.copy()

del acc, acc_safe
gc.collect()

# =========================================================================
# PHASE 4: CREATE SPECIFIC DISCHARGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: CREATE SPECIFIC DISCHARGE")
print("="*100)

Y_accumulation = X['accumulation'].values.astype('float32')

q_cols_specific = []
for q_col in q_cols:
    q_specific_col = f'{q_col}_specific'
    Y[q_specific_col] = (Y[q_col].values / Y_accumulation).astype('float32')
    q_cols_specific.append(q_specific_col)

q_cols_target = q_cols_specific

print(f"✓ Created {len(q_cols_specific)} specific discharge targets (m³/s/km²)")

del Y_accumulation
gc.collect()

# =========================================================================
# PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL - FAST)
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: SPEARMAN DECORRELATION (STATION-LEVEL - FAST)")
print("="*100)

def decorrelate_by_spearman_fast(X_df, groups, threshold):
    """Fast Spearman decorrelation using pandas correlation matrix."""
    print(f"  Input: {len(X_df.columns)} features, threshold={threshold}")
    
    df = X_df.copy()
    df['__g__'] = groups
    
    # Station-level aggregation
    df_station = df.groupby('__g__', observed=True).mean(numeric_only=True)
    df_station = df_station.replace([np.inf, -np.inf], np.nan).fillna(df_station.median())
    
    print(f"  Aggregated to {len(df_station)} stations")
    
    del df
    gc.collect()
    
    # Compute correlation matrix
    corr_matrix = df_station.corr(method='spearman').abs()
    
    # Upper triangle to avoid duplicates
    corr_array = corr_matrix.to_numpy().copy()
    np.fill_diagonal(corr_array, 0)
    corr_matrix = pd.DataFrame(corr_array, index=corr_matrix.index, columns=corr_matrix.columns)
    
    features = list(df_station.columns)
    to_drop = set()
    kept = []
    
    for feat in features:
        if feat in to_drop:
            continue
        kept.append(feat)
        # Find highly correlated features
        high_corr = corr_matrix.loc[feat, :][corr_matrix.loc[feat, :] > threshold].index.tolist()
        for corr_feat in high_corr:
            if corr_feat != feat and corr_feat not in kept:
                to_drop.add(corr_feat)
    
    print(f"  Output: {len(kept)} KEPT, {len(to_drop)} DISCARDED")
    
    del df_station, corr_matrix
    gc.collect()
    
    return kept

X_static_df = X[[c for c in static_present if c in X.columns]]
static_decorrelated = decorrelate_by_spearman_fast(
    X_static_df, X['StationID'].to_numpy(), SPEARMAN_STATION_THRESHOLD
)

print(f"\n✓ Spearman complete: {len(static_present)} → {len(static_decorrelated)} features")

del X_static_df
gc.collect()

# =========================================================================
# PHASE 6: TEMPORAL SPLIT (PER-STATION) - FIXED WITH PARALLELIZATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: TEMPORAL SPLIT (PER-STATION) - FIXED WITH PARALLELIZATION")
print("="*100)

def split_station_temporal(station_data, train_years=11, test_years=11):
    """
    Split a single station's data into train/test temporally.
    First 11 years = TRAIN, Next 11 years = TEST
    """
    # Sort by year and month (chronological order)
    station_data = station_data.sort_values(['YYYY', 'MM']).reset_index(drop=True)
    
    total_months = len(station_data)
    train_months = train_years * 12
    test_months = test_years * 12
    required_months = train_months + test_months
    
    station_id = station_data['StationID'].iloc[0]
    
    # Check if station has enough data
    if total_months < required_months:
        return {
            'station_id': station_id,
            'train_idx': np.array([]),
            'test_idx': np.array([]),
            'total_months': total_months,
            'skipped': True,
            'train_dates': None,
            'test_dates': None
        }
    
    # TEMPORAL SPLIT: First 132 months = TRAIN, Next 132 months = TEST
    train_idx = station_data.index[:train_months].values
    test_idx = station_data.index[train_months:train_months + test_months].values
    
    train_dates = (
        station_data.iloc[0]['YYYY'], station_data.iloc[0]['MM'],
        station_data.iloc[train_months-1]['YYYY'], station_data.iloc[train_months-1]['MM']
    )
    test_dates = (
        station_data.iloc[train_months]['YYYY'], station_data.iloc[train_months]['MM'],
        station_data.iloc[train_months + test_months - 1]['YYYY'], station_data.iloc[train_months + test_months - 1]['MM']
    )
    
    return {
        'station_id': station_id,
        'train_idx': train_idx,
        'test_idx': test_idx,
        'total_months': total_months,
        'skipped': False,
        'train_dates': train_dates,
        'test_dates': test_dates
    }

print(f"Splitting {X['StationID'].nunique()} stations using {NCPU} cores...")

# Parallel processing
split_start = datetime.now()
results = Parallel(n_jobs=NCPU)(
    delayed(split_station_temporal)(group, TRAIN_YEARS, TEST_YEARS)
    for _, group in X.groupby('StationID')
)
split_time = (datetime.now() - split_start).total_seconds()

# Collect indices
train_indices = []
test_indices = []
skipped_stations = []

for result in results:
    if result['skipped']:
        skipped_stations.append(result['station_id'])
    else:
        train_indices.extend(result['train_idx'].tolist())
        test_indices.extend(result['test_idx'].tolist())

print(f"\n✓ Split completed in {split_time:.1f}s")
print(f"  Processed stations: {len(results)}")
print(f"  Valid stations: {len(results) - len(skipped_stations)}")
print(f"  Skipped stations: {len(skipped_stations)} (insufficient data)")

if len(train_indices) == 0:
    print("\n❌ ERROR: No training data after temporal split!")
    print("  Possible causes:")
    print("    - Stations have < 264 months (22 years)")
    print("    - Incorrect temporal ordering")
    sys.exit(1)

if len(test_indices) == 0:
    print("\n❌ ERROR: No test data after temporal split!")
    sys.exit(1)

# Split X and Y
X_train = X.loc[train_indices].copy().reset_index(drop=True)
Y_train = Y.loc[train_indices].copy().reset_index(drop=True)
X_test = X.loc[test_indices].copy().reset_index(drop=True)
Y_test = Y.loc[test_indices].copy().reset_index(drop=True)

print(f"\nTemporal split summary:")
print(f"  Train: {len(X_train):,} rows, {X_train['StationID'].nunique()} stations")
print(f"  Test:  {len(X_test):,} rows, {X_test['StationID'].nunique()} stations")
print(f"  Train date range: {X_train['YYYY'].min()}-{X_train['MM'].min()} to {X_train['YYYY'].max()}-{X_train['MM'].max()}")
print(f"  Test date range:  {X_test['YYYY'].min()}-{X_test['MM'].min()} to {X_test['YYYY'].max()}-{X_test['MM'].max()}")

# Show sample station split
sample_result = [r for r in results if not r['skipped']][0]
print(f"\nSample station ({sample_result['station_id']}):")
print(f"  Train: {sample_result['train_dates'][0]}-{sample_result['train_dates'][1]} to {sample_result['train_dates'][2]}-{sample_result['train_dates'][3]}")
print(f"  Test:  {sample_result['test_dates'][0]}-{sample_result['test_dates'][1]} to {sample_result['test_dates'][2]}-{sample_result['test_dates'][3]}")

del results, train_indices, test_indices
gc.collect()

# =========================================================================
# PHASE 7: DATA PREPARATION FOR LSTM
# =========================================================================
print("\n" + "="*100)
print("PHASE 7: DATA PREPARATION FOR LSTM")
print("="*100)

def clean_data(df):
    return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))

# Prepare features
X_train_dyn = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_data(X_test[dynamic_final]).astype('float32')

X_train_sta_all = clean_data(X_train[static_decorrelated]).astype('float32')
X_test_sta_all = clean_data(X_test[static_decorrelated]).astype('float32')

Y_train_qdf = clean_data(Y_train[q_cols_target]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols_target]).astype('float32')

print("Scaling...")

# Fit scalers on training data
scaler_dyn = StandardScaler()
scaler_sta = StandardScaler()
scaler_y = StandardScaler()

X_train_dyn_s = scaler_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = scaler_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_all_s = scaler_sta.fit_transform(X_train_sta_all.to_numpy()).astype('float32')
X_test_sta_all_s = scaler_sta.transform(X_test_sta_all.to_numpy()).astype('float32')

Y_train_s = scaler_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = scaler_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print("✓ Scaling complete")

# Build sequences
print("\nBuilding sequences...")

def build_sequences(df_meta, X_dyn, X_sta, Y, seq_len=132):
    """
    Build LSTM sequences using StationID + YYYY + MM.
    For each station, create ONE sequence of length seq_len.
    """
    df = df_meta.copy().sort_values(['StationID', 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    for station_id, group in df.groupby('StationID'):
        indices = group.index.tolist()
        n = len(indices)
        
        if n < seq_len:
            continue
        
        # Take the first seq_len months as ONE sequence
        seq_idx = indices[:seq_len]
        
        X_seq_dyn.append(X_dyn[seq_idx])
        X_seq_sta.append(X_sta[indices[seq_len-1]])  # Static at last timestep
        Y_last.append(Y[indices[seq_len-1]])         # Target at last timestep
        idx_last.append(indices[seq_len-1])
    
    return (
        np.array(X_seq_dyn, dtype=np.float32),
        np.array(X_seq_sta, dtype=np.float32),
        np.array(Y_last, dtype=np.float32),
        np.array(idx_last, dtype=np.int64)
    )

Xtr_meta = X_train[['StationID', 'YYYY', 'MM']]
Xte_meta = X_test[['StationID', 'YYYY', 'MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN
)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s, Y_test_s, SEQ_LEN
)

print(f"Train sequences: {Xtr_seq_dyn.shape[0]:,} (one per station)")
print(f"Test sequences: {Xte_seq_dyn.shape[0]:,} (one per station)")
print(f"Sequence shape: {Xtr_seq_dyn.shape}")

if Xtr_seq_dyn.shape[0] == 0:
    print("\n❌ ERROR: No training sequences created!")
    print("  Check that stations have at least 132 consecutive months")
    sys.exit(1)

if Xte_seq_dyn.shape[0] == 0:
    print("\n❌ ERROR: No test sequences created!")
    sys.exit(1)

# Get true targets (unscaled)
Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

# =========================================================================
# LSTM MODEL DEFINITION
# =========================================================================

class LSTMWithContext(nn.Module):
    def __init__(self, n_dyn, n_sta, hidden, num_layers, dropout, out_dim):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=n_dyn,
            hidden_size=hidden,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
            bidirectional=False
        )
        
        self.static_encoder = nn.Sequential(
            nn.Linear(n_sta, max(8, n_sta // 2)),
            nn.ReLU(),
            nn.Dropout(dropout)
        ) if n_sta > 0 else None
        
        fusion_dim = hidden + (max(8, n_sta // 2) if n_sta > 0 else 0)
        self.head = nn.Sequential(
            nn.Linear(fusion_dim, 128),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(128, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        if self.static_encoder is not None and x_sta.shape[1] > 0:
            sta_encoded = self.static_encoder(x_sta)
            z = torch.cat([h_last, sta_encoded], dim=1)
        else:
            z = h_last
        return self.head(z)

class LSTMDataset(Dataset):
    def __init__(self, X_dyn, X_sta, Y):
        self.X_dyn = torch.from_numpy(X_dyn)
        self.X_sta = torch.from_numpy(X_sta)
        self.Y = torch.from_numpy(Y)

    def __len__(self):
        return len(self.X_dyn)

    def __getitem__(self, idx):
        return self.X_dyn[idx], self.X_sta[idx], self.Y[idx]

# =========================================================================
# SEQUENTIAL FORWARD SELECTION (STATIC FEATURES ONLY)
# =========================================================================

if USE_SEQUENTIAL_SELECTION and len(static_decorrelated) > 0:
    print("\n" + "="*100)
    print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES)")
    print("="*100)
    
    selected_static = []
    remaining_static = static_decorrelated.copy()
    
    n_dyn = Xtr_seq_dyn.shape[2]
    n_out = Ytr_seq.shape[1]
    
    # Baseline (dynamic only)
    print("\n--- BASELINE: Dynamic features only ---")
    
    model_baseline = LSTMWithContext(
        n_dyn=n_dyn, n_sta=0, hidden=SELECTION_HIDDEN,
        num_layers=SELECTION_LAYERS, dropout=SELECTION_DROPOUT, out_dim=n_out
    ).to(DEVICE)
    
    # Create dataset with NO static features
    Xtr_seq_sta_empty = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_seq_sta_empty = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)
    
    train_ds_baseline = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_empty, Ytr_seq)
    test_ds_baseline = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_empty, Yte_seq)
    
    train_dl_baseline = DataLoader(train_ds_baseline, batch_size=SELECTION_BATCH, shuffle=True, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
    test_dl_baseline = DataLoader(test_ds_baseline, batch_size=SELECTION_BATCH * 2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
    
    optimizer_baseline = torch.optim.Adam(model_baseline.parameters(), lr=SELECTION_LR)
    criterion = nn.MSELoss()
    scaler_amp = GradScaler() if USE_MIXED_PRECISION else None
    
    # Train baseline
    model_baseline.train()
    for epoch in range(SELECTION_EPOCHS):
        train_loss = 0.0
        for x_dyn, x_sta, y in train_dl_baseline:
            x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
            
            optimizer_baseline.zero_grad()
            
            if USE_MIXED_PRECISION:
                with autocast():
                    y_pred = model_baseline(x_dyn, x_sta)
                    loss = criterion(y_pred, y)
                scaler_amp.scale(loss).backward()
                scaler_amp.step(optimizer_baseline)
                scaler_amp.update()
            else:
                y_pred = model_baseline(x_dyn, x_sta)
                loss = criterion(y_pred, y)
                loss.backward()
                optimizer_baseline.step()
            
            train_loss += loss.item()
    
    # Evaluate baseline
    model_baseline.eval()
    all_preds_baseline = []
    with torch.no_grad():
        for x_dyn, x_sta, y in test_dl_baseline:
            x_dyn, x_sta = x_dyn.to(DEVICE), x_sta.to(DEVICE)
            if USE_MIXED_PRECISION:
                with autocast():
                    y_pred = model_baseline(x_dyn, x_sta)
            else:
                y_pred = model_baseline(x_dyn, x_sta)
            all_preds_baseline.append(y_pred.cpu().numpy())
    
    preds_baseline = np.vstack(all_preds_baseline)
    preds_baseline_unscaled = scaler_y.inverse_transform(preds_baseline)
    
    mae_baseline = mean_absolute_error(Yte_true, preds_baseline_unscaled)
    rmse_baseline = np.sqrt(mean_squared_error(Yte_true, preds_baseline_unscaled))
    r2_baseline = r2_score(Yte_true, preds_baseline_unscaled)
    
    print(f"Baseline MAE: {mae_baseline:.4f}, RMSE: {rmse_baseline:.4f}, R²: {r2_baseline:.4f}")
    
    best_mae = mae_baseline
    patience_counter = 0
    
    print(f"\n--- FORWARD SELECTION (max {MAX_STATIC_FEATURES} features) ---")
    
    # Selection loop
    for iteration in range(MAX_STATIC_FEATURES):
        if len(remaining_static) == 0:
            print("\n  No more features to add")
            break
        
        print(f"\n[Iteration {iteration+1}] Testing {len(remaining_static)} candidate features...")
        
        candidate_results = []
        
        for candidate in remaining_static:
            # Build feature set
            current_features = selected_static + [candidate]
            
            # Get column indices
            col_indices = [static_decorrelated.index(f) for f in current_features]
            
            # Extract static features
            Xtr_seq_sta_current = Xtr_seq_sta_all[:, col_indices]
            Xte_seq_sta_current = Xte_seq_sta_all[:, col_indices]
            
            # Build model
            model_candidate = LSTMWithContext(
                n_dyn=n_dyn, n_sta=len(current_features), hidden=SELECTION_HIDDEN,
                num_layers=SELECTION_LAYERS, dropout=SELECTION_DROPOUT, out_dim=n_out
            ).to(DEVICE)
            
            train_ds_candidate = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_current, Ytr_seq)
            test_ds_candidate = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_current, Yte_seq)
            
            train_dl_candidate = DataLoader(train_ds_candidate, batch_size=SELECTION_BATCH, shuffle=True, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
            test_dl_candidate = DataLoader(test_ds_candidate, batch_size=SELECTION_BATCH * 2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
            
            optimizer_candidate = torch.optim.Adam(model_candidate.parameters(), lr=SELECTION_LR)
            
            # Train
            model_candidate.train()
            for epoch in range(SELECTION_EPOCHS):
                for x_dyn, x_sta, y in train_dl_candidate:
                    x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
                    
                    optimizer_candidate.zero_grad()
                    
                    if USE_MIXED_PRECISION:
                        with autocast():
                            y_pred = model_candidate(x_dyn, x_sta)
                            loss = criterion(y_pred, y)
                        scaler_amp.scale(loss).backward()
                        scaler_amp.step(optimizer_candidate)
                        scaler_amp.update()
                    else:
                        y_pred = model_candidate(x_dyn, x_sta)
                        loss = criterion(y_pred, y)
                        loss.backward()
                        optimizer_candidate.step()
            
            # Evaluate
            model_candidate.eval()
            all_preds_candidate = []
            with torch.no_grad():
                for x_dyn, x_sta, y in test_dl_candidate:
                    x_dyn, x_sta = x_dyn.to(DEVICE), x_sta.to(DEVICE)
                    if USE_MIXED_PRECISION:
                        with autocast():
                            y_pred = model_candidate(x_dyn, x_sta)
                    else:
                        y_pred = model_candidate(x_dyn, x_sta)
                    all_preds_candidate.append(y_pred.cpu().numpy())
            
            preds_candidate = np.vstack(all_preds_candidate)
            preds_candidate_unscaled = scaler_y.inverse_transform(preds_candidate)
            
            mae_candidate = mean_absolute_error(Yte_true, preds_candidate_unscaled)
            
            candidate_results.append((candidate, mae_candidate))
            
            del model_candidate, train_ds_candidate, test_ds_candidate
            gc.collect()
            torch.cuda.empty_cache() if USE_GPU else None
        
        # Find best candidate
        candidate_results.sort(key=lambda x: x[1])
        best_candidate, best_candidate_mae = candidate_results[0]
        
        print(f"  Best candidate: {best_candidate} (MAE: {best_candidate_mae:.4f})")
        
        # Check improvement
        if best_candidate_mae < best_mae:
            improvement = best_mae - best_candidate_mae
            print(f"  ✓ ADDED (improvement: {improvement:.4f})")
            selected_static.append(best_candidate)
            remaining_static.remove(best_candidate)
            best_mae = best_candidate_mae
            patience_counter = 0
        else:
            patience_counter += 1
            print(f"  ✗ No improvement (patience: {patience_counter}/{SELECTION_PATIENCE})")
            if patience_counter >= SELECTION_PATIENCE:
                print("\n  Early stopping: no improvement for 3 iterations")
                break
    
    print(f"\n{'='*100}")
    print(f"SELECTION COMPLETE")
    print(f"{'='*100}")
    print(f"Selected {len(selected_static)} static features:")
    for i, feat in enumerate(selected_static, 1):
        print(f"  {i}. {feat}")
    print(f"\nBaseline MAE: {mae_baseline:.4f}")
    print(f"Final MAE:    {best_mae:.4f}")
    print(f"Improvement:  {mae_baseline - best_mae:.4f} ({(mae_baseline - best_mae)/mae_baseline*100:.1f}%)")
    
    static_final = selected_static
    
else:
    print("\n⚠️ Skipping sequential selection (disabled or no static features)")
    static_final = static_decorrelated

# =========================================================================
# FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)
# =========================================================================

print("\n" + "="*100)
print("FINAL LSTM TRAINING (DYNAMIC + SELECTED STATIC)")
print("="*100)

# Extract selected static features
if len(static_final) > 0:
    col_indices_final = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, col_indices_final]
    Xte_seq_sta_final = Xte_seq_sta_all[:, col_indices_final]
else:
    Xtr_seq_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_seq_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"Final features:")
print(f"  Dynamic: {n_dyn}")
print(f"  Static: {len(static_final)}")
print(f"  Total: {n_dyn + len(static_final)}")

# Build final model
model_final = LSTMWithContext(
    n_dyn=n_dyn, n_sta=len(static_final), hidden=FINAL_HIDDEN,
    num_layers=FINAL_LAYERS, dropout=FINAL_DROPOUT, out_dim=n_out
).to(DEVICE)

train_ds_final = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq)
test_ds_final = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq)

train_dl_final = DataLoader(train_ds_final, batch_size=FINAL_BATCH, shuffle=True, num_workers=NUM_WORKERS, pin_memory=USE_GPU)
test_dl_final = DataLoader(test_ds_final, batch_size=FINAL_BATCH * 2, shuffle=False, num_workers=NUM_WORKERS, pin_memory=USE_GPU)

optimizer_final = torch.optim.Adam(model_final.parameters(), lr=FINAL_LR)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer_final, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE)
scaler_amp_final = GradScaler() if USE_MIXED_PRECISION else None

print(f"\nTraining for {FINAL_EPOCHS} epochs...")
print(f"  Early stopping patience: {EARLY_STOP_PATIENCE}")

best_val_loss = float('inf')
early_stop_counter = 0

for epoch in range(FINAL_EPOCHS):
    # Train
    model_final.train()
    train_loss = 0.0
    for x_dyn, x_sta, y in train_dl_final:
        x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
        
        optimizer_final.zero_grad()
        
        if USE_MIXED_PRECISION:
            with autocast():
                y_pred = model_final(x_dyn, x_sta)
                loss = criterion(y_pred, y)
            scaler_amp_final.scale(loss).backward()
            scaler_amp_final.step(optimizer_final)
            scaler_amp_final.update()
        else:
            y_pred = model_final(x_dyn, x_sta)
            loss = criterion(y_pred, y)
            loss.backward()
            optimizer_final.step()
        
        train_loss += loss.item()
    
    train_loss /= len(train_dl_final)
    
    # Validate
    model_final.eval()
    val_loss = 0.0
    with torch.no_grad():
        for x_dyn, x_sta, y in test_dl_final:
            x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
            if USE_MIXED_PRECISION:
                with autocast():
                    y_pred = model_final(x_dyn, x_sta)
                    loss = criterion(y_pred, y)
            else:
                y_pred = model_final(x_dyn, x_sta)
                loss = criterion(y_pred, y)
            val_loss += loss.item()
    
    val_loss /= len(test_dl_final)
    
    scheduler.step(val_loss)
    
    if (epoch + 1) % 10 == 0:
        print(f"Epoch {epoch+1}/{FINAL_EPOCHS} - Train Loss: {train_loss:.6f}, Val Loss: {val_loss:.6f}")
    
    # Early stopping
    if val_loss < best_val_loss:
        best_val_loss = val_loss
        early_stop_counter = 0
        # Save best model
        torch.save(model_final.state_dict(), '../predict_score_red/best_model_v10.pt')
    else:
        early_stop_counter += 1
        if early_stop_counter >= EARLY_STOP_PATIENCE:
            print(f"\nEarly stopping at epoch {epoch+1}")
            break

# Load best model
model_final.load_state_dict(torch.load('../predict_score_red/best_model_v10.pt'))

# =========================================================================
# FINAL EVALUATION
# =========================================================================

print("\n" + "="*100)
print("FINAL EVALUATION")
print("="*100)

model_final.eval()
all_preds_final = []
with torch.no_grad():
    for x_dyn, x_sta, y in test_dl_final:
        x_dyn, x_sta = x_dyn.to(DEVICE), x_sta.to(DEVICE)
        if USE_MIXED_PRECISION:
            with autocast():
                y_pred = model_final(x_dyn, x_sta)
        else:
            y_pred = model_final(x_dyn, x_sta)
        all_preds_final.append(y_pred.cpu().numpy())

preds_final = np.vstack(all_preds_final)
preds_final_unscaled = scaler_y.inverse_transform(preds_final)

# Compute metrics
mae_final = mean_absolute_error(Yte_true, preds_final_unscaled)
rmse_final = np.sqrt(mean_squared_error(Yte_true, preds_final_unscaled))
r2_final = r2_score(Yte_true, preds_final_unscaled)

print(f"\nOverall metrics:")
print(f"  MAE:  {mae_final:.4f}")
print(f"  RMSE: {rmse_final:.4f}")
print(f"  R²:   {r2_final:.4f}")

# Per-quantile metrics
print(f"\nPer-quantile metrics:")
for i, q_col in enumerate(q_cols_target):
    mae_q = mean_absolute_error(Yte_true[:, i], preds_final_unscaled[:, i])
    rmse_q = np.sqrt(mean_squared_error(Yte_true[:, i], preds_final_unscaled[:, i]))
    r2_q = r2_score(Yte_true[:, i], preds_final_unscaled[:, i])
    print(f"  {q_col:20s} - MAE: {mae_q:8.4f}, RMSE: {rmse_q:8.4f}, R²: {r2_q:7.4f}")

# Save results
results_df = pd.DataFrame({
    'StationID': X_test['StationID'].iloc[te_idx].values,
    **{f'true_{q_cols_target[i]}': Yte_true[:, i] for i in range(len(q_cols_target))},
    **{f'pred_{q_cols_target[i]}': preds_final_unscaled[:, i] for i in range(len(q_cols_target))}
})

results_df.to_csv('../predict_score_red/lstm_v10_results.txt', sep=' ', index=False)
print(f"\n✓ Saved results to: ../predict_score_red/lstm_v10_results.txt")

# Save selected features
with open('../predict_score_red/lstm_v10_selected_features.txt', 'w') as f:
    f.write(f"# Selected static features ({len(static_final)})\n")
    for feat in static_final:
        f.write(f"{feat}\n")

print(f"✓ Saved selected features to: ../predict_score_red/lstm_v10_selected_features.txt")

print("\n" + "="*100)
print(f"COMPLETE - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)

EOFPYTHON
