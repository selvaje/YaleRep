#!/bin/bash
#SBATCH -p day
####SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V6_FINAL.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V6_FINAL.%J.err
#SBATCH --job-name=sc31_LSTM_V6
#SBATCH --mem=10G

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
from datetime import datetime, timedelta
from scipy.stats import spearmanr, pearsonr
from sklearn.preprocessing import StandardScaler, QuantileTransformer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torch.cuda.amp import autocast, GradScaler
from joblib import Parallel, delayed, parallel_backend
import gc
import warnings
warnings.filterwarnings('ignore')

os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("SC31: LSTM V6 - HYDROLOGICAL BEST PRACTICES (CORRECTED SEQUENCE BUILDING)")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Job ID: {os.environ.get('SLURM_JOB_ID', 'N/A')}")
print("="*100)

# =========================================================================
# TEST MODE CONFIGURATION
# =========================================================================
TEST_MODE = True  # <<<--- SET TO False FOR FULL RUN
TEST_N_STATIONS = 1000  # Number of stations for testing

# =========================================================================
# GPU/CPU AUTO-DETECTION
# =========================================================================
print(f"\n{'='*100}")
print("HARDWARE AUTO-DETECTION")
print(f"{'='*100}")

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
USE_GPU = torch.cuda.is_available()

if USE_GPU:
    print(f"✓ GPU MODE ACTIVATED")
    print(f"  CUDA Version: {torch.version.cuda}")
    print(f"  GPU: {torch.cuda.get_device_name(0)}")
    print(f"  GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    torch.backends.cudnn.benchmark = True
    
    BATCH_SIZE = 256 if not TEST_MODE else 128
    NUM_WORKERS_DATALOADER = 4
    USE_MIXED_PRECISION = True
    HIDDEN = 256 if not TEST_MODE else 128
else:
    print(f"⚠️ CPU MODE ACTIVATED")
    print(f"  CPU Cores: {os.cpu_count()}")
    
    BATCH_SIZE = 32
    NUM_WORKERS_DATALOADER = 2
    USE_MIXED_PRECISION = False
    HIDDEN = 128

print(f"\n  Device: {DEVICE}")
print(f"  Batch size: {BATCH_SIZE}")
print(f"  Workers: {NUM_WORKERS_DATALOADER}")
print(f"  Mixed precision: {USE_MIXED_PRECISION}")
print(f"  Hidden units: {HIDDEN}")

if TEST_MODE:
    print(f"\n  ⚠️ TEST MODE ENABLED")
    print(f"  Limited to {TEST_N_STATIONS} stations")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', os.cpu_count()))

# TARGET VARIABLE
USE_SPECIFIC_DISCHARGE = True

# Feature Selection
SPEARMAN_STATION_THRESHOLD = 0.90
USE_SEQUENTIAL_SELECTION = True if not TEST_MODE else False  # Skip in test mode for speed
MAX_STATIC_FEATURES = 15
SELECTION_PATIENCE = 3

# Temporal Split
TRAIN_YEARS = 11
TEST_YEARS = 11
RANDOM_STATE = 24

# =========================================================================
# LSTM HYPERPARAMETERS - ALWAYS USE FULL SEQUENCE LENGTH
# =========================================================================
SEQ_LEN = 132  # ← ALWAYS 11 years × 12 months (even in test mode)

# Selection phase
SELECTION_HIDDEN = 64
SELECTION_LAYERS = 1
SELECTION_DROPOUT = 0.1
SELECTION_BATCH = 512
SELECTION_EPOCHS = 15
SELECTION_LR = 1e-3

# Final training phase
FINAL_HIDDEN = HIDDEN  # Use auto-detected value
FINAL_LAYERS = 2
FINAL_DROPOUT = 0.2
FINAL_BATCH = BATCH_SIZE
FINAL_EPOCHS = 10 if TEST_MODE else 50
FINAL_LR = 1e-3
LR_PATIENCE = 10
LR_FACTOR = 0.5
EARLY_STOP_PATIENCE = 5 if TEST_MODE else 20

# Scaler choice
USE_STANDARD_SCALER = True  # ← SET TO False FOR QuantileTransformer

print(f"\n{'='*100}")
print("CONFIGURATION SUMMARY")
print(f"{'='*100}")
print(f"  Mode: {'TEST' if TEST_MODE else 'FULL'}")
print(f"  Sequence length: {SEQ_LEN} months ({SEQ_LEN//12} years) - ALWAYS FULL LENGTH")
print(f"  Target: {'Specific discharge (q=Q/area)' if USE_SPECIFIC_DISCHARGE else 'Absolute discharge (Q)'}")
print(f"  Scaler: {'StandardScaler' if USE_STANDARD_SCALER else 'QuantileTransformer'}")
print(f"  Sequential selection: {USE_SEQUENTIAL_SELECTION}")
print(f"  Max static features: {MAX_STATIC_FEATURES}")
print(f"  Final epochs: {FINAL_EPOCHS}")
print(f"{'='*100}")

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'  # ← Use sample for testing
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

# Variable definitions
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
print("PHASE 1: DATA LOADING")
print("="*100)

load_start = datetime.now()
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
load_time = (datetime.now() - load_start).total_seconds()

print(f"✓ Loaded in {load_time:.1f}s: X {X.shape}, Y {Y.shape}")

# TEST MODE: Sample subset of stations
if TEST_MODE:
    unique_stations = X['IDr'].unique()
    if len(unique_stations) > TEST_N_STATIONS:
        np.random.seed(RANDOM_STATE)
        sampled_stations = np.random.choice(unique_stations, TEST_N_STATIONS, replace=False)
        X = X[X['IDr'].isin(sampled_stations)].reset_index(drop=True)
        Y = Y[Y['IDr'].isin(sampled_stations)].reset_index(drop=True)
        print(f"  TEST MODE: Sampled {TEST_N_STATIONS} stations")
        print(f"  Reduced data: X {X.shape}, Y {Y.shape}")

static_present = [v for v in static_var if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# =========================================================================
# ALIGN X AND Y
# =========================================================================
print("\n" + "="*100)
print("ALIGNING X AND Y DATASETS")
print("="*100)

merge_keys = ['IDr', 'YYYY', 'MM']
print(f"  Before alignment: X={len(X)}, Y={len(Y)}")

X_dups = X.duplicated(subset=merge_keys, keep=False).sum()
Y_dups = Y.duplicated(subset=merge_keys, keep=False).sum()

if X_dups > 0:
    print(f"  Removing {X_dups} duplicate rows in X")
    X = X.drop_duplicates(subset=merge_keys, keep='first').reset_index(drop=True)
    
if Y_dups > 0:
    print(f"  Removing {Y_dups} duplicate rows in Y")
    Y = Y.drop_duplicates(subset=merge_keys, keep='first').reset_index(drop=True)

X['__key__'] = X['IDr'].astype(str) + '_' + X['YYYY'].astype(str) + '_' + X['MM'].astype(str)
Y['__key__'] = Y['IDr'].astype(str) + '_' + Y['YYYY'].astype(str) + '_' + Y['MM'].astype(str)

common_keys = set(X['__key__']) & set(Y['__key__'])

X = X[X['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)
Y = Y[Y['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)

X = X.drop(columns=['__key__'])
Y = Y.drop(columns=['__key__'])

print(f"  After alignment: X={len(X)}, Y={len(Y)}")

# =========================================================================
# CREATE DERIVED FEATURES
# =========================================================================
print("\n" + "="*100)
print("CREATING DERIVED FEATURES")
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

print(f"✓ Created {len(derived_features)} features")

dynamic_final = derived_features.copy()

del acc, acc_safe
gc.collect()

# =========================================================================
# CREATE SPECIFIC DISCHARGE TARGET
# =========================================================================
if USE_SPECIFIC_DISCHARGE:
    print("\n" + "="*100)
    print("CREATING SPECIFIC DISCHARGE TARGET")
    print("="*100)
    
    Y_accumulation = X['accumulation'].values.astype('float32')
    
    q_cols_specific = []
    for q_col in q_cols:
        q_specific_col = f'{q_col}_specific'
        Y[q_specific_col] = (Y[q_col].values / Y_accumulation).astype('float32')
        q_cols_specific.append(q_specific_col)
    
    q_cols_target = q_cols_specific
    target_suffix = '_specific'
    target_unit = 'm³/s/km²'
    
    print(f"✓ Created {len(q_cols_specific)} specific discharge targets")
    
    del Y_accumulation
else:
    q_cols_target = q_cols
    target_suffix = '_absolute'
    target_unit = 'm³/s'

# =========================================================================
# SPEARMAN DECORRELATION (PARALLEL, FAST, CORRECT)
# =========================================================================
print("\n" + "="*100)
print("SPEARMAN DECORRELATION (PARALLEL)")
print("="*100)

def compute_pairwise_correlation_chunk(col_pairs, df_g):
    """Compute correlations for a chunk of column pairs"""
    results = []
    for i, j in col_pairs:
        try:
            r, _ = spearmanr(df_g.iloc[:, i].values, df_g.iloc[:, j].values, nan_policy='omit')
            if not np.isnan(r):
                results.append((df_g.columns[i], df_g.columns[j], abs(r)))
        except:
            pass
    return results

def decorrelate_by_spearman_parallel(X_np, groups, col_names, threshold, n_jobs):
    """
    Fast parallel Spearman decorrelation at station level
    """
    print(f"  Input: {len(col_names)} features")
    
    # Aggregate to station level
    df = pd.DataFrame(X_np, columns=col_names)
    df['__g__'] = groups
    df_g = df.groupby('__g__').mean(numeric_only=True).reset_index(drop=True)
    df_g = df_g.replace([np.inf, -np.inf], np.nan).fillna(df_g.median(numeric_only=True))
    
    print(f"  Aggregated to {df_g.shape[0]} stations")
    
    del df
    gc.collect()
    
    # Parallel correlation computation
    n_features = len(df_g.columns)
    pairs = [(i, j) for i in range(n_features) for j in range(i+1, n_features)]
    chunk_size = max(1, len(pairs) // (n_jobs * 4))
    chunks = [pairs[i:i+chunk_size] for i in range(0, len(pairs), chunk_size)]
    
    print(f"  Computing {len(pairs)} pairwise correlations in {len(chunks)} chunks...")
    
    with parallel_backend('loky', n_jobs=n_jobs):
        chunk_results = Parallel()(
            delayed(compute_pairwise_correlation_chunk)(chunk, df_g)
            for chunk in chunks
        )
    
    all_correlations = [item for sublist in chunk_results for item in sublist]
    
    # Build high-correlation pairs dict
    high_corr_pairs = {}
    for col1, col2, corr in all_correlations:
        if corr > threshold:
            if col1 not in high_corr_pairs:
                high_corr_pairs[col1] = []
            high_corr_pairs[col1].append(col2)
    
    # Greedy selection
    cols = list(df_g.columns)
    drop = set()
    keep = []
    
    for c in cols:
        if c in drop:
            continue
        keep.append(c)
        if c in high_corr_pairs:
            for h in high_corr_pairs[c]:
                if h not in keep:
                    drop.add(h)
    
    print(f"  Output: {len(keep)} KEPT, {len(drop)} DISCARDED")
    
    del df_g, all_correlations, high_corr_pairs
    gc.collect()
    
    return keep

X_static_np = X[[c for c in static_present if c in X.columns]].to_numpy(dtype=np.float32)
groups = X['IDr'].to_numpy()

static_decorrelated = decorrelate_by_spearman_parallel(
    X_static_np, groups, [c for c in static_present if c in X.columns],
    SPEARMAN_STATION_THRESHOLD, NCPU
)

print(f"✓ {len(static_present)} → {len(static_decorrelated)} features")

del X_static_np, groups
gc.collect()

# =========================================================================
# TEMPORAL SPLIT (DO THIS FIRST)
# =========================================================================
print("\n" + "="*100)
print("TEMPORAL SPLIT")
print("="*100)

min_year = Y['YYYY'].min()
max_year = Y['YYYY'].max()
total_years = max_year - min_year + 1

if total_years < TRAIN_YEARS + TEST_YEARS:
    TRAIN_YEARS = int(total_years * 0.5)
    TEST_YEARS = total_years - TRAIN_YEARS

TRAIN_START = min_year
TRAIN_END = TRAIN_START + TRAIN_YEARS - 1
TEST_START = TRAIN_END + 1
TEST_END = TEST_START + TEST_YEARS - 1

print(f"Train: {TRAIN_START}-{TRAIN_END} ({TRAIN_YEARS} years)")
print(f"Test:  {TEST_START}-{TEST_END} ({TEST_YEARS} years)")

train_mask = (X['YYYY'] >= TRAIN_START) & (X['YYYY'] <= TRAIN_END)
test_mask = (X['YYYY'] >= TEST_START) & (X['YYYY'] <= TEST_END)

X_train_full = X[train_mask].copy().reset_index(drop=True)
Y_train_full = Y[train_mask].copy().reset_index(drop=True)
X_test_full = X[test_mask].copy().reset_index(drop=True)
Y_test_full = Y[test_mask].copy().reset_index(drop=True)

print(f"Before filtering:")
print(f"  Train: X {X_train_full.shape}, Stations: {X_train_full['IDr'].nunique()}")
print(f"  Test:  X {X_test_full.shape}, Stations: {X_test_full['IDr'].nunique()}")

# =========================================================================
# FILTER STATIONS BY CONSECUTIVE MONTHS (AFTER SPLIT!)
# =========================================================================
print("\n" + "="*100)
print(f"FILTERING STATIONS (MIN: {SEQ_LEN} CONSECUTIVE MONTHS IN EACH SPLIT)")
print("="*100)

def get_stations_with_consecutive_months(df, min_length):
    """
    Returns set of station IDs that have at least min_length consecutive months
    """
    valid_stations = set()
    
    for idr, group in df.groupby('IDr'):
        group = group.sort_values(['YYYY', 'MM']).reset_index(drop=True)
        group['date'] = pd.to_datetime(
            group['YYYY'].astype(str) + '-' + group['MM'].astype(str).str.zfill(2) + '-01'
        )
        
        # Find max consecutive sequence
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
        
        if max_consecutive >= min_length:
            valid_stations.add(idr)
    
    return valid_stations

print("\nAnalyzing train split...")
train_valid_stations = get_stations_with_consecutive_months(X_train_full, SEQ_LEN)
print(f"  Stations with ≥{SEQ_LEN} consecutive months in TRAIN: {len(train_valid_stations)}")

print("\nAnalyzing test split...")
test_valid_stations = get_stations_with_consecutive_months(X_test_full, SEQ_LEN)
print(f"  Stations with ≥{SEQ_LEN} consecutive months in TEST: {len(test_valid_stations)}")

# Keep only stations valid in BOTH splits
valid_stations = train_valid_stations & test_valid_stations

print(f"\n{'='*100}")
print(f"STATION FILTERING SUMMARY")
print(f"{'='*100}")
print(f"  Total stations: {X['IDr'].nunique()}")
print(f"  Valid in train only: {len(train_valid_stations - test_valid_stations)}")
print(f"  Valid in test only: {len(test_valid_stations - train_valid_stations)}")
print(f"  Valid in BOTH (kept): {len(valid_stations)}")
print(f"{'='*100}")

if len(valid_stations) == 0:
    print(f"\n❌ ERROR: No stations have {SEQ_LEN} consecutive months in BOTH splits!")
    print(f"\nDiagnostics:")
    print(f"  Train period: {TRAIN_START}-{TRAIN_END}")
    print(f"  Test period: {TEST_START}-{TEST_END}")
    print(f"  Required: {SEQ_LEN} months ({SEQ_LEN/12:.1f} years) in each split")
    print(f"\nThis is expected with small samples. Solutions:")
    print(f"  1. Use larger sample (current: {X['IDr'].nunique()} stations)")
    print(f"  2. Use full dataset (not sample)")
    print(f"  3. Reduce SEQ_LEN (but you wanted 132)")
    sys.exit(1)

# Filter to valid stations
print(f"\nFiltering to {len(valid_stations)} valid stations...")
X_train = X_train_full[X_train_full['IDr'].isin(valid_stations)].reset_index(drop=True)
Y_train = Y_train_full[Y_train_full['IDr'].isin(valid_stations)].reset_index(drop=True)
X_test = X_test_full[X_test_full['IDr'].isin(valid_stations)].reset_index(drop=True)
Y_test = Y_test_full[Y_test_full['IDr'].isin(valid_stations)].reset_index(drop=True)

print(f"\nAfter filtering:")
print(f"  Train: X {X_train.shape}, Stations: {X_train['IDr'].nunique()}")
print(f"  Test:  X {X_test.shape}, Stations: {X_test['IDr'].nunique()}")

del X, Y, X_train_full, Y_train_full, X_test_full, Y_test_full, train_mask, test_mask
gc.collect()

# =========================================================================
# DATA PREPARATION
# =========================================================================
print("\n" + "="*100)
print("DATA PREPARATION")
print("="*100)

def clean_data(df):
    return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))

X_train_dyn = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_data(X_test[dynamic_final]).astype('float32')

X_train_sta_all = clean_data(X_train[static_decorrelated]).astype('float32')
X_test_sta_all = clean_data(X_test[static_decorrelated]).astype('float32')

Y_train_qdf = clean_data(Y_train[q_cols_target]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols_target]).astype('float32')

print(f"Scaling ({('StandardScaler' if USE_STANDARD_SCALER else 'QuantileTransformer')})...")

if USE_STANDARD_SCALER:
    scaler_dyn = StandardScaler()
    scaler_sta = StandardScaler()
    scaler_y = StandardScaler()
else:
    scaler_dyn = QuantileTransformer(n_quantiles=min(2000, len(X_train_dyn)), 
                                     output_distribution='normal', random_state=RANDOM_STATE)
    scaler_sta = QuantileTransformer(n_quantiles=min(2000, len(X_train_sta_all)), 
                                     output_distribution='normal', random_state=RANDOM_STATE)
    scaler_y = QuantileTransformer(n_quantiles=min(2000, len(Y_train_qdf)), 
                                   output_distribution='normal', random_state=RANDOM_STATE)

X_train_dyn_s = scaler_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = scaler_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_all_s = scaler_sta.fit_transform(X_train_sta_all.to_numpy()).astype('float32')
X_test_sta_all_s = scaler_sta.transform(X_test_sta_all.to_numpy()).astype('float32')

Y_train_s = scaler_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = scaler_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print("✓ Scaling complete")

# =========================================================================
# BUILD SEQUENCES - WITH GAP DETECTION
# =========================================================================
print(f"\n{'='*100}")
print(f"BUILDING SEQUENCES (SEQ_LEN={SEQ_LEN}) - WITH GAP DETECTION")
print(f"{'='*100}")

def build_sequences_with_gap_detection(df_meta, X_dyn, X_sta, Y, seq_len):
    """
    Build sequences ONLY from truly consecutive months.
    If there's a gap, do NOT span across it.
    """
    df = df_meta.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    stations_used = 0
    stations_skipped = 0
    total_sequences = 0
    
    for idr, group in df.groupby('IDr'):
        group = group.sort_values(['YYYY', 'MM']).reset_index(drop=True)
        
        # Create date column for gap detection
        group['date'] = pd.to_datetime(
            group['YYYY'].astype(str) + '-' + group['MM'].astype(str).str.zfill(2) + '-01'
        )
        
        # Find consecutive blocks (no gaps allowed)
        consecutive_blocks = []
        current_block_original_idx = []
        
        for i in range(len(group)):
            if i == 0:
                current_block_original_idx.append(group.iloc[i].name)
            else:
                expected_date = group.iloc[i-1]['date'] + pd.DateOffset(months=1)
                actual_date = group.iloc[i]['date']
                
                if expected_date == actual_date:
                    current_block_original_idx.append(group.iloc[i].name)
                else:
                    # GAP detected - save current block and start new one
                    if len(current_block_original_idx) >= seq_len:
                        consecutive_blocks.append(current_block_original_idx)
                    current_block_original_idx = [group.iloc[i].name]
        
        # Don't forget last block
        if len(current_block_original_idx) >= seq_len:
            consecutive_blocks.append(current_block_original_idx)
        
        # Build sequences from each consecutive block separately
        if len(consecutive_blocks) > 0:
            stations_used += 1
        else:
            stations_skipped += 1
        
        for block_original_indices in consecutive_blocks:
            block_len = len(block_original_indices)
            
            # Build sliding window sequences within this block only
            for j in range(seq_len - 1, block_len):
                w0 = j - (seq_len - 1)
                seq_original_indices = block_original_indices[w0:j+1]
                
                X_seq_dyn.append(X_dyn[seq_original_indices])
                X_seq_sta.append(X_sta[seq_original_indices[-1]])
                Y_last.append(Y[seq_original_indices[-1]])
                idx_last.append(seq_original_indices[-1])
                total_sequences += 1
    
    print(f"  Stations used: {stations_used}, skipped: {stations_skipped}")
    print(f"  Total sequences built: {total_sequences}")
    
    if total_sequences == 0:
        print("  ⚠️ WARNING: No sequences generated!")
    
    return (
        np.array(X_seq_dyn, dtype=np.float32) if total_sequences > 0 else np.zeros((0, seq_len, X_dyn.shape[1]), dtype=np.float32),
        np.array(X_seq_sta, dtype=np.float32) if total_sequences > 0 else np.zeros((0, X_sta.shape[1]), dtype=np.float32),
        np.array(Y_last, dtype=np.float32) if total_sequences > 0 else np.zeros((0, Y.shape[1]), dtype=np.float32),
        np.array(idx_last, dtype=np.int64) if total_sequences > 0 else np.array([], dtype=np.int64)
    )

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']]
Xte_meta = X_test[['IDr', 'YYYY', 'MM']]

print("\nTrain sequences:")
Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences_with_gap_detection(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s, SEQ_LEN
)

print("\nTest sequences:")
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences_with_gap_detection(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s, Y_test_s, SEQ_LEN
)

print(f"\n✓ Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"✓ Test sequences: {Xte_seq_dyn.shape[0]:,}")

if Xtr_seq_dyn.shape[0] == 0:
    print(f"\n❌ ERROR: No training sequences generated!")
    sys.exit(1)

# Check if we have test sequences
HAS_TEST_DATA = (Xte_seq_dyn.shape[0] > 0)
if not HAS_TEST_DATA:
    print(f"\n⚠️ WARNING: No test sequences - will train only")

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
if HAS_TEST_DATA:
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
# SEQUENTIAL FORWARD SELECTION (FROM V4, SKIP IN TEST MODE)
# =========================================================================

static_final = static_decorrelated[:MAX_STATIC_FEATURES]  # Default: use first N

if USE_SEQUENTIAL_SELECTION and HAS_TEST_DATA:
    print("\n" + "="*100)
    print("LSTM-BASED SEQUENTIAL FORWARD SELECTION")
    print("="*100)
    print(f"Starting with {len(dynamic_final)} dynamic + 0 static features")
    print(f"Pool: {len(static_decorrelated)} static features available")
    print(f"Target: Select up to {MAX_STATIC_FEATURES} best static features")
    print("="*100)
    
    def train_lightweight_lstm(X_dyn, X_sta_indices, Y, X_sta_pool):
        """Train lightweight LSTM for feature evaluation"""
        
        if len(X_sta_indices) > 0:
            X_sta = X_sta_pool[:, X_sta_indices]
        else:
            X_sta = np.zeros((len(X_sta_pool), 0), dtype=np.float32)
        
        dataset = LSTMDataset(X_dyn, X_sta, Y)
        loader = DataLoader(dataset, batch_size=SELECTION_BATCH, shuffle=True,
                          num_workers=0, pin_memory=False)
        
        n_dyn = X_dyn.shape[2]
        n_sta = X_sta.shape[1]
        
        model = LSTMWithContext(n_dyn, n_sta, SELECTION_HIDDEN, SELECTION_LAYERS, 
                               SELECTION_DROPOUT, len(q_cols_target)).to(DEVICE)
        
        opt = torch.optim.Adam(model.parameters(), lr=SELECTION_LR)
        loss_fn = nn.SmoothL1Loss()
        
        # Train
        model.train()
        for ep in range(SELECTION_EPOCHS):
            for x_dyn, x_sta, y in loader:
                x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
                
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
                x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
                val_loss += loss.item()
        
        val_loss /= len(loader)
        
        del model, opt, dataset, loader
        torch.cuda.empty_cache()
        gc.collect()
        
        return val_loss
    
    # Baseline
    print("\n" + "-"*100)
    print("Baseline (dynamic only)")
    print("-"*100)
    
    baseline_loss = train_lightweight_lstm(Xtr_seq_dyn, [], Ytr_seq, Xtr_seq_sta_all)
    print(f"✓ Baseline validation loss: {baseline_loss:.6f}")
    
    # Sequential selection
    selected_static_indices = []
    selected_static_names = []
    remaining_indices = list(range(len(static_decorrelated)))
    best_loss = baseline_loss
    patience_counter = 0
    selection_history = []
    
    print("\n" + "-"*100)
    print("Sequential Forward Selection")
    print("-"*100)
    
    for iteration in range(1, MAX_STATIC_FEATURES + 1):
        print(f"\nIteration {iteration}:")
        print(f"  Current features: {len(selected_static_indices)}")
        print(f"  Remaining pool: {len(remaining_indices)}")
        
        best_candidate = None
        best_candidate_loss = best_loss
        
        for idx, candidate_idx in enumerate(remaining_indices):
            test_indices = selected_static_indices + [candidate_idx]
            
            loss = train_lightweight_lstm(Xtr_seq_dyn, test_indices, Ytr_seq, Xtr_seq_sta_all)
            
            if loss < best_candidate_loss:
                best_candidate_loss = loss
                best_candidate = candidate_idx
            
            if (idx + 1) % 5 == 0 or (idx + 1) == len(remaining_indices):
                print(f"    Tested {idx + 1}/{len(remaining_indices)} candidates...")
        
        improvement = best_loss - best_candidate_loss
        
        if best_candidate is not None and improvement > 1e-5:
            selected_static_indices.append(best_candidate)
            selected_static_names.append(static_decorrelated[best_candidate])
            remaining_indices.remove(best_candidate)
            best_loss = best_candidate_loss
            patience_counter = 0
            
            selection_history.append({
                'iteration': iteration,
                'feature': static_decorrelated[best_candidate],
                'loss': best_candidate_loss,
                'improvement': improvement
            })
            
            print(f"\n  ✓ Selected: {static_decorrelated[best_candidate]}")
            print(f"    Loss: {best_candidate_loss:.6f} (improvement: {improvement:.6f})")
        else:
            patience_counter += 1
            print(f"\n  ✗ No improvement (patience: {patience_counter}/{SELECTION_PATIENCE})")
            
            if patience_counter >= SELECTION_PATIENCE:
                print(f"\n  Early stopping: no improvement for {SELECTION_PATIENCE} iterations")
                break
    
    static_final = selected_static_names
    
    print("\n" + "="*100)
    print("SEQUENTIAL SELECTION SUMMARY")
    print("="*100)
    print(f"Selected {len(static_final)} static features:")
    for i, (feat, info) in enumerate(zip(static_final, selection_history), 1):
        print(f"  {i:2d}. {feat:30s} | loss={info['loss']:.6f}, Δ={info['improvement']:.6f}")
    
    print(f"\nFinal improvement: {baseline_loss - best_loss:.6f} ({(baseline_loss - best_loss)/baseline_loss*100:.2f}%)")
    
    # Save
    selection_df = pd.DataFrame(selection_history)
    selection_df.to_csv(f'../predict_score_red/LSTM_sequential_selection_v6{target_suffix}.txt', sep=' ', index=False)

else:
    print(f"\n✓ Using first {len(static_final)} static features (selection skipped)")

# =========================================================================
# PREPARE FINAL TRAINING DATA
# =========================================================================
print("\n" + "="*100)
print("PREPARING FINAL TRAINING DATA")
print("="*100)

if len(static_final) > 0:
    static_final_indices = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, static_final_indices]
    if HAS_TEST_DATA:
        Xte_seq_sta_final = Xte_seq_sta_all[:, static_final_indices]
else:
    Xtr_seq_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    if HAS_TEST_DATA:
        Xte_seq_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"Final features: Dynamic={len(dynamic_final)}, Static={len(static_final)}, Total={len(dynamic_final)+len(static_final)}")

# =========================================================================
# FINAL LSTM TRAINING
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (FULL CAPACITY)")
print("="*100)

train_ds_final = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq)
train_loader_final = DataLoader(
    train_ds_final, batch_size=FINAL_BATCH, shuffle=True,
    num_workers=NUM_WORKERS_DATALOADER, pin_memory=USE_GPU,
    persistent_workers=(NUM_WORKERS_DATALOADER > 0)
)

if HAS_TEST_DATA:
    test_ds_final = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq)
    test_loader_final = DataLoader(
        test_ds_final, batch_size=FINAL_BATCH, shuffle=False,
        num_workers=NUM_WORKERS_DATALOADER, pin_memory=USE_GPU,
        persistent_workers=(NUM_WORKERS_DATALOADER > 0)
    )

n_dyn_final = Xtr_seq_dyn.shape[2]
n_sta_final = Xtr_seq_sta_final.shape[1]

model_final = LSTMWithContext(n_dyn_final, n_sta_final, FINAL_HIDDEN, FINAL_LAYERS, 
                              FINAL_DROPOUT, len(q_cols_target)).to(DEVICE)
opt_final = torch.optim.Adam(model_final.parameters(), lr=FINAL_LR)

if HAS_TEST_DATA:
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(
        opt_final, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE,
        threshold=1e-4, min_lr=1e-6
    )

loss_fn_final = nn.SmoothL1Loss()
scaler_final = GradScaler() if USE_MIXED_PRECISION else None

total_params = sum(p.numel() for p in model_final.parameters())
print(f"Model parameters: {total_params:,}")

def run_epoch_final(loader, train=True):
    model_final.train() if train else model_final.eval()
    losses, preds = [], []

    for x_dyn, x_sta, y in loader:
        x_dyn, x_sta, y = x_dyn.to(DEVICE), x_sta.to(DEVICE), y.to(DEVICE)

        if train:
            opt_final.zero_grad(set_to_none=True)

        if USE_MIXED_PRECISION and scaler_final:
            with autocast():
                pred = model_final(x_dyn, x_sta)
                loss = loss_fn_final(pred, y)
            
            if train:
                scaler_final.scale(loss).backward()
                scaler_final.unscale_(opt_final)
                nn.utils.clip_grad_norm_(model_final.parameters(), 1.0)
                scaler_final.step(opt_final)
                scaler_final.update()
        else:
            with torch.set_grad_enabled(train):
                pred = model_final(x_dyn, x_sta)
                loss = loss_fn_final(pred, y)
                if train:
                    loss.backward()
                    nn.utils.clip_grad_norm_(model_final.parameters(), 1.0)
                    opt_final.step()

        losses.append(loss.item())
        preds.append(pred.detach().cpu().numpy())

    p_all = np.concatenate(preds) if preds else np.zeros((0, len(q_cols_target)), dtype=np.float32)
    return np.mean(losses) if losses else np.nan, p_all

print("\nTraining:")
best_val = np.inf
best_state = None
patience_counter = 0

for ep in range(1, FINAL_EPOCHS + 1):
    tr_loss, _ = run_epoch_final(train_loader_final, True)
    
    if HAS_TEST_DATA:
        te_loss, _ = run_epoch_final(test_loader_final, False)
        
        old_lr = opt_final.param_groups[0]['lr']
        scheduler.step(te_loss)
        current_lr = opt_final.param_groups[0]['lr']
        
        if current_lr != old_lr:
            print(f'  → LR reduced: {old_lr:.6f} → {current_lr:.6f}')
        
        if te_loss < best_val:
            best_val = te_loss
            best_state = {k: v.cpu().clone() for k, v in model_final.state_dict().items()}
            patience_counter = 0
        else:
            patience_counter += 1
    else:
        te_loss = np.nan
        best_val = tr_loss
        best_state = {k: v.cpu().clone() for k, v in model_final.state_dict().items()}
        current_lr = opt_final.param_groups[0]['lr']
    
    if ep == 1 or ep % 5 == 0 or ep == FINAL_EPOCHS:
        print(f'Epoch {ep:3d} | train={tr_loss:.5f} | test={te_loss:.5f} | best={best_val:.5f} | lr={current_lr:.6f}')
    
    if HAS_TEST_DATA and patience_counter >= EARLY_STOP_PATIENCE:
        print(f'\n✓ Early stopping at epoch {ep}')
        break

if best_state:
    model_final.load_state_dict(best_state)

print(f"\n✓ Training complete. Best loss: {best_val:.5f}")

# Predictions
_, Ptr_final = run_epoch_final(train_loader_final, False)
Q_train_pred = scaler_y.inverse_transform(Ptr_final).astype('float32')

if HAS_TEST_DATA:
    _, Pte_final = run_epoch_final(test_loader_final, False)
    Q_test_pred = scaler_y.inverse_transform(Pte_final).astype('float32')

# =========================================================================
# METRICS
# =========================================================================
print("\n" + "="*100)
print("PERFORMANCE EVALUATION")
print("="*100)

def compute_metrics(Y_true, Y_pred):
    metrics = {}
    for i in range(len(q_cols_target)):
        try:
            metrics.setdefault('r', []).append(pearsonr(Y_pred[:, i], Y_true[:, i])[0])
        except:
            metrics.setdefault('r', []).append(np.nan)
    return {'r': (np.nanmean(metrics['r']), metrics['r'])}

train_metrics = compute_metrics(Ytr_true, Q_train_pred)

print(f"\nTRAIN: r={train_metrics['r'][0]:.4f}")

if HAS_TEST_DATA:
    test_metrics = compute_metrics(Yte_true, Q_test_pred)
    print(f"TEST:  r={test_metrics['r'][0]:.4f}")

# Save
suffix = '_seq_sel' if USE_SEQUENTIAL_SELECTION else '_decorr'
suffix += '_test' if TEST_MODE else ''
suffix += target_suffix

np.savetxt(f'../predict_prediction_red/LSTM_train_v6{suffix}.txt', Q_train_pred, fmt='%.6f', 
          header=' '.join(q_cols_target), comments='')

if HAS_TEST_DATA:
    np.savetxt(f'../predict_prediction_red/LSTM_test_v6{suffix}.txt', Q_test_pred, fmt='%.6f', 
              header=' '.join(q_cols_target), comments='')

with open(f'../predict_importance_red/LSTM_features_v6{suffix}.txt', 'w') as f:
    f.write(f'GPU: {torch.cuda.get_device_name(0) if USE_GPU else "CPU"}\n')
    f.write(f'Test mode: {TEST_MODE}\n')
    f.write(f'Sequential selection: {USE_SEQUENTIAL_SELECTION}\n')
    f.write(f'Scaler: {("StandardScaler" if USE_STANDARD_SCALER else "QuantileTransformer")}\n')
    f.write(f'Sequence length: {SEQ_LEN}\n\n')
    f.write(f'DYNAMIC ({len(dynamic_final)})\n')
    for d in dynamic_final:
        f.write(f'{d}\n')
    f.write(f'\nSTATIC ({len(static_final)})\n')
    for s in static_final:
        f.write(f'{s}\n')
    f.write(f'\nTRAIN: r={train_metrics["r"][0]:.4f}\n')
    if HAS_TEST_DATA:
        f.write(f'TEST:  r={test_metrics["r"][0]:.4f}\n')

print(f"\n✓ Complete: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

EOFPYTHON

if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "=== GPU INFO ==="
    nvidia-smi
fi
