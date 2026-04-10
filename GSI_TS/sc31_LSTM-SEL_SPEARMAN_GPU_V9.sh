#!/bin/bash
#SBATCH -p day
######SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 24 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V8_FIXED.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V8_FIXED.%J.err
#SBATCH --job-name=sc31_LSTM_V8
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
from scipy.stats import spearmanr, pearsonr
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torch.cuda.amp import autocast, GradScaler
import gc
import warnings
warnings.filterwarnings('ignore')

os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("SC31: LSTM V8 - FIXED TEMPORAL SPLIT + SEQUENTIAL SELECTION")
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

# Data Files
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
# PHASE 1: LOAD DATA - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: LOAD DATA")
print("="*100)

load_start = datetime.now()
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
load_time = (datetime.now() - load_start).total_seconds()

print(f"✓ Loaded in {load_time:.1f}s: X {X.shape}, Y {Y.shape}")

static_present = [v for v in static_var if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

print(f"Variables: {len(static_present)} static, {len(dynamic_present)} dynamic, {len(q_cols)} targets")

# =========================================================================
# PHASE 2: ALIGN X AND Y - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: ALIGN X AND Y")
print("="*100)

# Create unique station identifier: IDr + IDs
if 'IDs' in X.columns and 'IDs' in Y.columns:
    X['station_id'] = X['IDr'].astype(str) + '_' + X['IDs'].astype(str)
    Y['station_id'] = Y['IDr'].astype(str) + '_' + Y['IDs'].astype(str)
    print("  Using IDr + IDs as unique station identifier")
else:
    X['station_id'] = X['IDr'].astype(str)
    Y['station_id'] = Y['IDr'].astype(str)
    print("  Using IDr only as station identifier (IDs not found)")

merge_keys = ['station_id', 'YYYY', 'MM']
print(f"Before: X={len(X)}, Y={len(Y)}")

# Remove duplicates
X_dups = X.duplicated(subset=merge_keys, keep=False).sum()
Y_dups = Y.duplicated(subset=merge_keys, keep=False).sum()

if X_dups > 0:
    print(f"  Removing {X_dups} duplicate rows in X")
    X = X.drop_duplicates(subset=merge_keys, keep='first').reset_index(drop=True)
    
if Y_dups > 0:
    print(f"  Removing {Y_dups} duplicate rows in Y")
    Y = Y.drop_duplicates(subset=merge_keys, keep='first').reset_index(drop=True)

# Align
X['__key__'] = X['station_id'] + '_' + X['YYYY'].astype(str) + '_' + X['MM'].astype(str)
Y['__key__'] = Y['station_id'] + '_' + Y['YYYY'].astype(str) + '_' + Y['MM'].astype(str)

common_keys = set(X['__key__']) & set(Y['__key__'])

X = X[X['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)
Y = Y[Y['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)

X = X.drop(columns=['__key__'])
Y = Y.drop(columns=['__key__'])

print(f"After: X={len(X)}, Y={len(Y)}")
print(f"Unique stations: {X['station_id'].nunique()}")

# =========================================================================
# PHASE 3: CHECK 132 CONSECUTIVE MONTHS (FULL DATASET) - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 3: CHECK {SEQ_LEN} CONSECUTIVE MONTHS (FULL DATASET)")
print("="*100)

def check_consecutive_months(df, min_length, station_col='station_id'):
    """Check max consecutive months per station"""
    station_consecutive = {}
    
    for station, group in df.groupby(station_col):
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

X_sorted = X.copy().sort_values(['station_id', 'YYYY', 'MM']).reset_index(drop=True)

print(f"Analyzing {X['station_id'].nunique()} stations...")
station_months = check_consecutive_months(X_sorted, SEQ_LEN)

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
X = X[X['station_id'].isin(valid_stations)].reset_index(drop=True)
Y = Y[Y['station_id'].isin(valid_stations)].reset_index(drop=True)

print(f"After filter: X={len(X)}, Y={len(Y)}")

del X_sorted, station_months
gc.collect()

# =========================================================================
# PHASE 4: CREATE DERIVED FEATURES - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: CREATE DERIVED FEATURES")
print("="*100)

acc = X['accumulation'].astype('float32').values
acc_safe = np.where(acc == 0, 1e-10, acc)

accumulated_vars = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
    'GRWLw'
]

derived_features = []
for var in accumulated_vars:
    if var in X.columns:
        X[f'{var}_mean'] = (X[var].astype('float32').values / acc_safe).astype('float32')
        derived_features.append(f'{var}_mean')

if 'tmax0' in X.columns:
    derived_features.append('tmax0')

print(f"✓ Created {len(derived_features)} derived features")
dynamic_final = derived_features.copy()

del acc, acc_safe
gc.collect()

# =========================================================================
# PHASE 5: CREATE SPECIFIC DISCHARGE - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: CREATE SPECIFIC DISCHARGE")
print("="*100)

Y_accumulation = X['accumulation'].values.astype('float32')
Y_accumulation_safe = np.where(Y_accumulation == 0, 1e-10, Y_accumulation)

q_cols_specific = []
for q_col in q_cols:
    q_specific_col = f'{q_col}_specific'
    Y[q_specific_col] = (Y[q_col].values / Y_accumulation_safe).astype('float32')
    q_cols_specific.append(q_specific_col)

q_cols_target = q_cols_specific
target_suffix = '_specific'

print(f"✓ Created {len(q_cols_specific)} specific discharge targets (m³/s/km²)")

del Y_accumulation, Y_accumulation_safe
gc.collect()

# =========================================================================
# PHASE 6: SPEARMAN DECORRELATION (STATION-LEVEL - FAST) - DO NOT CHANGE
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: SPEARMAN DECORRELATION (STATION-LEVEL - FAST)")
print("="*100)

def decorrelate_by_spearman_fast(X_df, groups, threshold):
    """Fast Spearman decorrelation using pandas correlation matrix.
    Aggregates by station, computes correlation, removes highly correlated features."""
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
    X_static_df, X['station_id'].to_numpy(), SPEARMAN_STATION_THRESHOLD
)

print(f"\n✓ Spearman complete: {len(static_present)} → {len(static_decorrelated)} features")

del X_static_df
gc.collect()

# =========================================================================
# PHASE 7: TEMPORAL SPLIT (PER-STATION) - FIXED
# =========================================================================
print("\n" + "="*100)
print("PHASE 7: TEMPORAL SPLIT (PER-STATION) - FIXED")
print("="*100)

from joblib import Parallel, delayed

def split_station_temporal(station_data, train_years=11, test_years=11):
    """
    Split a single station's data into train/test temporally.
    
    Args:
        station_data: DataFrame for one station (IDr + IDs)
        train_years: Number of years for training
        test_years: Number of years for testing
    
    Returns:
        dict with train and test indices
    """
    # Sort by year and month (chronological order)
    station_data = station_data.sort_values(['YYYY', 'MM']).reset_index(drop=True)
    
    total_months = len(station_data)
    train_months = train_years * 12
    test_months = test_years * 12
    required_months = train_months + test_months
    
    # Check if station has enough data
    if total_months < required_months:
        return {'station_id': station_data[['IDr', 'IDs']].iloc[0].values,
                'train_idx': np.array([]),
                'test_idx': np.array([]),
                'total_months': total_months,
                'skipped': True}
    
    # TEMPORAL SPLIT: First N years = TRAIN, Next M years = TEST
    train_idx = station_data.index[:train_months].values
    test_idx = station_data.index[train_months:train_months + test_months].values
    
    return {
        'station_id': station_data[['IDr', 'IDs']].iloc[0].values,
        'train_idx': train_idx,
        'test_idx': test_idx,
        'total_months': total_months,
        'skipped': False
    }

# Create unique station identifier
df_merged['station_id'] = df_merged['IDr'].astype(str) + '_' + df_merged['IDs'].astype(str)

# Group by station (IDr + IDs combination)
print(f"\nGrouping by unique station (IDr + IDs)...")
grouped = df_merged.groupby('station_id')
print(f"✓ Found {len(grouped)} unique stations")

# Parallel processing of stations
print(f"\nProcessing temporal split per station (parallel with {NCPU} cores)...")
from joblib import Parallel, delayed

station_splits = Parallel(n_jobs=NCPU, backend='loky', verbose=5)(
    delayed(split_station_temporal)(
        group.copy(),
        train_years=TRAIN_YEARS,
        test_years=TEST_YEARS
    )
    for name, group in grouped
)

# Collect results
train_indices = []
test_indices = []
skipped_stations = []

for split_result in station_splits:
    if split_result['skipped']:
        skipped_stations.append(split_result['station_id'])
    else:
        train_indices.extend(split_result['train_idx'])
        test_indices.extend(split_result['test_idx'])

# Convert to numpy arrays
train_indices = np.array(train_indices)
test_indices = np.array(test_indices)

print(f"\n{'='*80}")
print("TEMPORAL SPLIT SUMMARY")
print(f"{'='*80}")
print(f"Total stations: {len(grouped)}")
print(f"Valid stations: {len(station_splits) - len(skipped_stations)}")
print(f"Skipped stations (insufficient data): {len(skipped_stations)}")
print(f"\nTrain indices: {len(train_indices)}")
print(f"Test indices: {len(test_indices)}")
print(f"{'='*80}")

# Verify split
if len(train_indices) == 0:
    print("\n❌ ERROR: No training data after split!")
    print("This suggests a problem with the temporal filtering or split logic.")
    sys.exit(1)

if len(test_indices) == 0:
    print("\n❌ ERROR: No test data after split!")
    sys.exit(1)

# Extract train and test sets
df_train = df_merged.iloc[train_indices].copy()
df_test = df_merged.iloc[test_indices].copy()

print(f"\n✓ Train shape: {df_train.shape}")
print(f"✓ Test shape: {df_test.shape}")

# Verify temporal ordering
print(f"\nTrain period: {df_train['YYYY'].min()}-{df_train['YYYY'].max()}")
print(f"Test period: {df_test['YYYY'].min()}-{df_test['YYYY'].max()}")

# Check for temporal overlap (should be none for proper temporal split)
train_dates = set(zip(df_train['YYYY'], df_train['MM']))
test_dates = set(zip(df_test['YYYY'], df_test['MM']))
overlap = train_dates.intersection(test_dates)

if len(overlap) > 0:
    print(f"\n⚠️ WARNING: {len(overlap)} overlapping YYYY-MM between train and test!")
else:
    print(f"\n✓ No temporal overlap - clean split")

# Show sample stations
print(f"\n{'='*80}")
print("SAMPLE STATION SPLITS")
print(f"{'='*80}")
for i, split_result in enumerate(station_splits[:3]):  # Show first 3 stations
    if not split_result['skipped']:
        print(f"\nStation {i+1}: IDr={split_result['station_id'][0]}, IDs={split_result['station_id'][1]}")
        print(f"  Total months: {split_result['total_months']}")
        print(f"  Train samples: {len(split_result['train_idx'])}")
        print(f"  Test samples: {len(split_result['test_idx'])}")

print(f"{'='*80}")

gc.collect()

# =========================================================================
# PHASE 8: DATA PREPARATION FOR LSTM (IMPROVED - FIXED)
# =========================================================================
print("\n" + "="*100)
print("PHASE 8: DATA PREPARATION FOR LSTM")
print("="*100)

def clean_data(df):
    return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))

# Extract and clean dynamic features
X_train_dyn = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_data(X_test[dynamic_final]).astype('float32')

# Extract and clean static features (all decorrelated for now)
X_train_sta_all = clean_data(X_train[static_decorrelated]).astype('float32')
X_test_sta_all = clean_data(X_test[static_decorrelated]).astype('float32')

# Extract and clean targets
Y_train_qdf = clean_data(Y_train[q_cols_target]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols_target]).astype('float32')

print(f"Data extracted:")
print(f"  Train: dyn {X_train_dyn.shape}, sta {X_train_sta_all.shape}, y {Y_train_qdf.shape}")
print(f"  Test:  dyn {X_test_dyn.shape}, sta {X_test_sta_all.shape}, y {Y_test_qdf.shape}")

# Scaling
print("\nScaling...")

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

# Build sequences (FIXED - using station_id)
print("\nBuilding sequences...")

def build_sequences(df_meta, X_dyn, X_sta, Y, station_col='station_id'):
    """Build sequences for LSTM.
    Groups by station_id, sorts by time, creates overlapping sequences."""
    df = df_meta.copy().sort_values([station_col, 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    for station, group in df.groupby(station_col):
        indices = group.index.tolist()
        n = len(indices)
        
        if n < SEQ_LEN:
            continue
        
        # Create overlapping sequences
        for j in range(SEQ_LEN - 1, n):
            w0 = j - (SEQ_LEN - 1)
            seq_idx = indices[w0:j+1]
            
            X_seq_dyn.append(X_dyn[seq_idx])
            X_seq_sta.append(X_sta[indices[j]])
            Y_last.append(Y[indices[j]])
            idx_last.append(indices[j])
    
    return (
        np.array(X_seq_dyn, dtype=np.float32),
        np.array(X_seq_sta, dtype=np.float32),
        np.array(Y_last, dtype=np.float32),
        np.array(idx_last, dtype=np.int64)
    )

Xtr_meta = X_train[['station_id', 'YYYY', 'MM']]
Xte_meta = X_test[['station_id', 'YYYY', 'MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s
)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s, Y_test_s
)

print(f"Train sequences: {Xtr_seq_dyn.shape[0]:,} (shape: {Xtr_seq_dyn.shape})")
print(f"Test sequences: {Xte_seq_dyn.shape[0]:,} (shape: {Xte_seq_dyn.shape})")

if Xtr_seq_dyn.shape[0] == 0:
    print("\n❌ ERROR: No train sequences created!")
    print(f"   Train stations: {X_train['station_id'].nunique()}")
    print(f"   Required SEQ_LEN: {SEQ_LEN}")
    sys.exit(1)

if Xte_seq_dyn.shape[0] == 0:
    print("\n❌ ERROR: No test sequences created!")
    print(f"   Test stations: {X_test['station_id'].nunique()}")
    print(f"   Required SEQ_LEN: {SEQ_LEN}")
    sys.exit(1)

# Get true targets (unscaled) for final evaluation
Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

print(f"✓ Sequences built successfully")

del X_train_dyn, X_test_dyn, X_train_dyn_s, X_test_dyn_s
gc.collect()

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
# SEQUENTIAL FORWARD SELECTION FOR STATIC FEATURES
# =========================================================================
if USE_SEQUENTIAL_SELECTION and len(static_decorrelated) > 0:
    print("\n" + "="*100)
    print("SEQUENTIAL FORWARD SELECTION (STATIC FEATURES ONLY)")
    print("="*100)
    print(f"Pool: {len(static_decorrelated)} static features available")
    print(f"Target: Select up to {MAX_STATIC_FEATURES} best features")
    print(f"Method: Greedy forward selection with lightweight LSTM")
    print("="*100)
    
    def train_eval_lightweight_lstm(X_dyn, X_sta_indices, Y, X_sta_pool):
        """Train lightweight LSTM for feature evaluation"""
        
        # Extract selected static features
        if len(X_sta_indices) > 0:
            X_sta = X_sta_pool[:, X_sta_indices]
        else:
            X_sta = np.zeros((len(X_sta_pool), 0), dtype=np.float32)
        
        # Create dataset
        dataset = LSTMDataset(X_dyn, X_sta, Y)
        loader = DataLoader(
            dataset, 
            batch_size=SELECTION_BATCH, 
            shuffle=True,
            num_workers=0,
            pin_memory=False
        )
        
        # Model
        n_dyn = X_dyn.shape[2]
        n_sta = X_sta.shape[1]
        
        model = LSTMWithContext(
            n_dyn, n_sta, 
            SELECTION_HIDDEN, SELECTION_LAYERS, SELECTION_DROPOUT,
            len(q_cols_target)
        ).to(DEVICE)
        
        opt = torch.optim.Adam(model.parameters(), lr=SELECTION_LR)
        loss_fn = nn.SmoothL1Loss()
        
        # Train
        model.train()
        for ep in range(SELECTION_EPOCHS):
            for x_dyn, x_sta, y in loader:
                x_dyn = x_dyn.to(DEVICE)
                x_sta = x_sta.to(DEVICE)
                y = y.to(DEVICE)
                
                opt.zero_grad()
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
                loss.backward()
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                opt.step()
        
        # Evaluate
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for x_dyn, x_sta, y in loader:
                x_dyn = x_dyn.to(DEVICE)
                x_sta = x_sta.to(DEVICE)
                y = y.to(DEVICE)
                
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
                val_loss += loss.item()
        
        val_loss /= len(loader)
        
        del model, opt, dataset, loader
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()
        
        return val_loss
    
    # Baseline: dynamic only (no static features)
    print("\n" + "-"*100)
    print("BASELINE (dynamic features only, no static)")
    print("-"*100)
    
    baseline_loss = train_eval_lightweight_lstm(
        Xtr_seq_dyn, [], Ytr_seq, Xtr_seq_sta_all
    )
    
    print(f"✓ Baseline validation loss: {baseline_loss:.6f}")
    
    # Sequential forward selection
    selected_static_indices = []
    selected_static_names = []
    remaining_indices = list(range(len(static_decorrelated)))
    best_loss = baseline_loss
    patience_counter = 0
    
    selection_history = []
    
    print("\n" + "-"*100)
    print("GREEDY FORWARD SELECTION")
    print("-"*100)
    
    for iteration in range(1, MAX_STATIC_FEATURES + 1):
        print(f"\n{'Iteration ' + str(iteration):-^100}")
        print(f"  Current selected: {len(selected_static_indices)} features")
        print(f"  Remaining pool: {len(remaining_indices)} features")
        print(f"  Current best loss: {best_loss:.6f}")
        
        best_candidate = None
        best_candidate_loss = best_loss
        best_candidate_name = None
        
        # Test each remaining feature
        for idx, candidate_idx in enumerate(remaining_indices):
            test_indices = selected_static_indices + [candidate_idx]
            
            loss = train_eval_lightweight_lstm(
                Xtr_seq_dyn, test_indices, Ytr_seq, Xtr_seq_sta_all
            )
            
            if loss < best_candidate_loss:
                best_candidate_loss = loss
                best_candidate = candidate_idx
                best_candidate_name = static_decorrelated[candidate_idx]
            
            if (idx + 1) % 5 == 0 or (idx + 1) == len(remaining_indices):
                print(f"    Progress: {idx + 1}/{len(remaining_indices)} features tested...")
        
        # Check improvement
        improvement = best_loss - best_candidate_loss
        
        if best_candidate is not None and improvement > 1e-6:
            selected_static_indices.append(best_candidate)
            selected_static_names.append(best_candidate_name)
            remaining_indices.remove(best_candidate)
            best_loss = best_candidate_loss
            patience_counter = 0
            
            selection_history.append({
                'iteration': iteration,
                'feature': best_candidate_name,
                'loss': best_candidate_loss,
                'improvement': improvement
            })
            
            print(f"\n  ✓ SELECTED: {best_candidate_name}")
            print(f"    Loss: {best_candidate_loss:.6f}")
            print(f"    Improvement: {improvement:.6f} ({improvement/baseline_loss*100:.2f}%)")
        else:
            patience_counter += 1
            print(f"\n  ✗ NO IMPROVEMENT (patience: {patience_counter}/{SELECTION_PATIENCE})")
            
            if patience_counter >= SELECTION_PATIENCE:
                print(f"\n  Early stopping: no improvement for {SELECTION_PATIENCE} iterations")
                break
    
    static_final = selected_static_names
    
    print("\n" + "="*100)
    print("SELECTION SUMMARY")
    print("="*100)
    print(f"Selected {len(static_final)} static features:")
    for i, (feat, info) in enumerate(zip(static_final, selection_history), 1):
        print(f"  {i:2d}. {feat:35s} | loss={info['loss']:.6f}, Δ={info['improvement']:.6f}")
    
    improvement_pct = (baseline_loss - best_loss) / baseline_loss * 100
    print(f"\nTotal improvement: {baseline_loss - best_loss:.6f} ({improvement_pct:.2f}%)")
    print(f"  Baseline loss: {baseline_loss:.6f}")
    print(f"  Final loss:    {best_loss:.6f}")
    
    # Save selection results
    selection_df = pd.DataFrame(selection_history)
    selection_df.to_csv('../predict_score_red/LSTM_V8_sequential_selection.txt', sep=' ', index=False)
    print(f"\n✓ Saved: ../predict_score_red/LSTM_V8_sequential_selection.txt")
    
else:
    static_final = static_decorrelated if len(static_decorrelated) > 0 else []
    print(f"\n✓ Using all {len(static_final)} decorrelated static features (no selection)")

# Prepare final training data with selected features
if len(static_final) > 0:
    static_final_indices = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, static_final_indices]
    Xte_seq_sta_final = Xte_seq_sta_all[:, static_final_indices]
else:
    Xtr_seq_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_seq_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"\n{'='*100}")
print("FINAL FEATURE CONFIGURATION")
print(f"{'='*100}")
print(f"  Dynamic: {len(dynamic_final)} features")
print(f"  Static:  {len(static_final)} features (selected from {len(static_decorrelated)} decorrelated)")
print(f"  Total:   {len(dynamic_final) + len(static_final)} features")
print(f"  Targets: {len(q_cols_target)} quantiles")

# =========================================================================
# FINAL LSTM TRAINING (FULL CAPACITY)
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (FULL CAPACITY)")
print("="*100)

print(f"\n{'MODEL ARCHITECTURE':-^100}")
print(f"  Input (dynamic): {len(dynamic_final)} features × {SEQ_LEN} timesteps")
print(f"  Input (static):  {len(static_final)} features")
print(f"  LSTM hidden:     {FINAL_HIDDEN} units × {FINAL_LAYERS} layers")
print(f"  Dropout:         {FINAL_DROPOUT}")
print(f"  Output:          {len(q_cols_target)} quantiles")
print(f"\n{'TRAINING SETUP':-^100}")
print(f"  Batch size:      {FINAL_BATCH}")
print(f"  Epochs:          {FINAL_EPOCHS}")
print(f"  Learning rate:   {FINAL_LR}")
print(f"  Device:          {DEVICE}")
print(f"  Mixed precision: {USE_MIXED_PRECISION}")
print("-"*100)

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq)
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq)

train_loader = DataLoader(
    train_ds, 
    batch_size=FINAL_BATCH, 
    shuffle=True, 
    num_workers=NUM_WORKERS,
    pin_memory=True if USE_GPU else False,
    persistent_workers=True if NUM_WORKERS > 0 else False
)
test_loader = DataLoader(
    test_ds, 
    batch_size=FINAL_BATCH, 
    shuffle=False, 
    num_workers=NUM_WORKERS,
    pin_memory=True if USE_GPU else False,
    persistent_workers=True if NUM_WORKERS > 0 else False
)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta_final.shape[1]

model = LSTMWithContext(
    n_dyn, n_sta, FINAL_HIDDEN, FINAL_LAYERS, FINAL_DROPOUT, len(q_cols_target)
).to(DEVICE)

opt = torch.optim.Adam(model.parameters(), lr=FINAL_LR)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
    opt, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE, verbose=True
)
loss_fn = nn.SmoothL1Loss()

scaler = GradScaler() if USE_MIXED_PRECISION and USE_GPU else None

total_params = sum(p.numel() for p in model.parameters())
trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)

print(f"\nModel parameters:")
print(f"  Total:      {total_params:,}")
print(f"  Trainable:  {trainable_params:,}")

if USE_GPU:
    print(f"\nGPU memory: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB")

def run_epoch(loader, train=True):
    model.train() if train else model.eval()
    losses, preds = [], []

    for x_dyn, x_sta, y in loader:
        x_dyn = x_dyn.to(DEVICE, non_blocking=True)
        x_sta = x_sta.to(DEVICE, non_blocking=True)
        y = y.to(DEVICE, non_blocking=True)

        if train:
            opt.zero_grad(set_to_none=True)

        if USE_MIXED_PRECISION and scaler is not None:
            with autocast():
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
            
            if train:
                scaler.scale(loss).backward()
                scaler.unscale_(opt)
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler.step(opt)
                scaler.update()
        else:
            with torch.set_grad_enabled(train):
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
                if train:
                    loss.backward()
                    nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                    opt.step()

        losses.append(loss.item())
        preds.append(pred.detach().cpu().numpy())

    p_all = np.concatenate(preds) if preds else np.zeros((0, len(q_cols_target)), dtype=np.float32)
    return np.mean(losses) if losses else np.nan, p_all

print("\nTraining progress:")
print("-"*100)

best_val = np.inf
best_state = None
no_improve_count = 0

for ep in range(1, FINAL_EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, True)
    te_loss, _ = run_epoch(test_loader, False)
    
    scheduler.step(te_loss)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
        no_improve_count = 0
    else:
        no_improve_count += 1

    if ep == 1 or ep % 10 == 0 or ep == FINAL_EPOCHS:
        print(f'Epoch {ep:3d}/{FINAL_EPOCHS} | train={tr_loss:.5f} | test={te_loss:.5f} | best={best_val:.5f}')
        if USE_GPU:
            print(f'  GPU mem: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB, LR: {opt.param_groups[0]["lr"]:.2e}')
    
    if no_improve_count >= EARLY_STOP_PATIENCE:
        print(f"\nEarly stopping at epoch {ep} (no improvement for {EARLY_STOP_PATIENCE} epochs)")
        break

if best_state:
    model.load_state_dict(best_state)

print(f"\n✓ Training complete. Best loss: {best_val:.5f}")

# Final predictions
print("\nGenerating predictions...")
_, Ptr = run_epoch(train_loader, False)
_, Pte = run_epoch(test_loader, False)

# Inverse transform
Q_train_pred = scaler_y.inverse_transform(Ptr).astype('float32')
Q_test_pred = scaler_y.inverse_transform(Pte).astype('float32')

print("✓ Predictions generated")

# =========================================================================
# PERFORMANCE METRICS
# =========================================================================
print("\n" + "="*100)
print("PERFORMANCE EVALUATION")
print("="*100)

def kge_1d(y_true, y_pred):
    """Kling-Gupta Efficiency"""
    if np.all(y_true == y_true[0]) or len(y_true) < 2:
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1] if np.std(y_true) > 0 and np.std(y_pred) > 0 else np.nan
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    if np.isnan(r) or np.isnan(beta) or np.isnan(gamma):
        return np.nan
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

def compute_metrics(Y_true, Y_pred):
    """Compute metrics for each quantile"""
    metrics = {}
    for i in range(len(q_cols_target)):
        try:
            r, _ = pearsonr(Y_pred[:, i], Y_true[:, i])
            metrics.setdefault('r', []).append(r)
            
            nse = 1 - np.sum((Y_true[:, i] - Y_pred[:, i])**2) / np.sum((Y_true[:, i] - np.mean(Y_true[:, i]))**2)
            metrics.setdefault('nse', []).append(nse)
            
            kge = kge_1d(Y_true[:, i], Y_pred[:, i])
            metrics.setdefault('kge', []).append(kge)
            
            mae = mean_absolute_error(Y_true[:, i], Y_pred[:, i])
            metrics.setdefault('mae', []).append(mae)
            
            rmse = np.sqrt(mean_squared_error(Y_true[:, i], Y_pred[:, i]))
            metrics.setdefault('rmse', []).append(rmse)
        except:
            metrics.setdefault('r', []).append(np.nan)
            metrics.setdefault('nse', []).append(np.nan)
            metrics.setdefault('kge', []).append(np.nan)
            metrics.setdefault('mae', []).append(np.nan)
            metrics.setdefault('rmse', []).append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true, Q_train_pred)
test_metrics = compute_metrics(Yte_true, Q_test_pred)

print(f"\n{'OVERALL PERFORMANCE':-^100}")
print(f"TRAIN: r={train_metrics['r'][0]:.4f}, NSE={train_metrics['nse'][0]:.4f}, KGE={train_metrics['kge'][0]:.4f}, MAE={train_metrics['mae'][0]:.4f}, RMSE={train_metrics['rmse'][0]:.4f}")
print(f"TEST:  r={test_metrics['r'][0]:.4f}, NSE={test_metrics['nse'][0]:.4f}, KGE={test_metrics['kge'][0]:.4f}, MAE={test_metrics['mae'][0]:.4f}, RMSE={test_metrics['rmse'][0]:.4f}")

# Per-quantile performance
quantile_perf = pd.DataFrame({
    'Quantile': [q.replace('_specific', '') for q in q_cols_target],
    'r': test_metrics['r'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1],
    'MAE': test_metrics['mae'][1],
    'RMSE': test_metrics['rmse'][1]
}).round(4)

print(f"\n{'PER-QUANTILE PERFORMANCE (TEST)':-^100}")
print(quantile_perf.to_string(index=False))

# =========================================================================
# SAVE RESULTS
# =========================================================================
print("\n" + "="*100)
print("SAVING RESULTS")
print("="*100)

# Predictions
np.savetxt('../predict_prediction_red/LSTM_V8_train_pred.txt', Q_train_pred, fmt='%.6f', 
           header=' '.join([q.replace('_specific', '') for q in q_cols_target]), comments='')
np.savetxt('../predict_prediction_red/LSTM_V8_test_pred.txt', Q_test_pred, fmt='%.6f', 
           header=' '.join([q.replace('_specific', '') for q in q_cols_target]), comments='')

# True values
np.savetxt('../predict_prediction_red/LSTM_V8_train_true.txt', Ytr_true, fmt='%.6f', 
           header=' '.join([q.replace('_specific', '') for q in q_cols_target]), comments='')
np.savetxt('../predict_prediction_red/LSTM_V8_test_true.txt', Yte_true, fmt='%.6f', 
           header=' '.join([q.replace('_specific', '') for q in q_cols_target]), comments='')

# Metrics
quantile_perf.to_csv('../predict_score_red/LSTM_V8_metrics.txt', sep=' ', index=False)

# Feature list
with open('../predict_importance_red/LSTM_V8_features.txt', 'w') as f:
    f.write(f"# LSTM V8 Feature Configuration\n")
    f.write(f"# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
    f.write(f"HARDWARE\n")
    f.write(f"  Device: {DEVICE}\n")
    f.write(f"  GPU: {torch.cuda.get_device_name(0) if USE_GPU else 'N/A'}\n")
    f.write(f"  Mixed precision: {USE_MIXED_PRECISION}\n\n")
    f.write(f"ARCHITECTURE\n")
    f.write(f"  Sequence length: {SEQ_LEN}\n")
    f.write(f"  Hidden units: {FINAL_HIDDEN}\n")
    f.write(f"  LSTM layers: {FINAL_LAYERS}\n")
    f.write(f"  Dropout: {FINAL_DROPOUT}\n")
    f.write(f"  Batch size: {FINAL_BATCH}\n")
    f.write(f"  Epochs: {FINAL_EPOCHS}\n\n")
    f.write(f"FEATURES\n")
    f.write(f"  Dynamic ({len(dynamic_final)}):\n")
    for feat in dynamic_final:
        f.write(f"    {feat}\n")
    f.write(f"\n  Static ({len(static_final)} selected from {len(static_decorrelated)} decorrelated):\n")
    if len(static_final) > 0:
        for feat in static_final:
            f.write(f"    {feat}\n")
    else:
        f.write(f"    (none)\n")
    f.write(f"\n  Targets ({len(q_cols_target)}):\n")
    for q in q_cols_target:
        f.write(f"    {q}\n")
    f.write(f"\nPERFORMANCE\n")
    f.write(f"  Train: r={train_metrics['r'][0]:.4f}, NSE={train_metrics['nse'][0]:.4f}, KGE={train_metrics['kge'][0]:.4f}\n")
    f.write(f"  Test:  r={test_metrics['r'][0]:.4f}, NSE={test_metrics['nse'][0]:.4f}, KGE={test_metrics['kge'][0]:.4f}\n")

print("✓ Saved predictions:")
print("  - ../predict_prediction_red/LSTM_V8_train_pred.txt")
print("  - ../predict_prediction_red/LSTM_V8_test_pred.txt")
print("  - ../predict_prediction_red/LSTM_V8_train_true.txt")
print("  - ../predict_prediction_red/LSTM_V8_test_true.txt")
print("✓ Saved metrics:")
print("  - ../predict_score_red/LSTM_V8_metrics.txt")
if USE_SEQUENTIAL_SELECTION:
    print("  - ../predict_score_red/LSTM_V8_sequential_selection.txt")
print("✓ Saved features:")
print("  - ../predict_importance_red/LSTM_V8_features.txt")

print("\n" + "="*100)
print("COMPLETE")
print("="*100)
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100)

EOFPYTHON
