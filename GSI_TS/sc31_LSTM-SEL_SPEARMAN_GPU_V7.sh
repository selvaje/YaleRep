#!/bin/bash
#SBATCH -p day
######SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_V7_FIXED.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_V7_FIXED.%J.err
#SBATCH --job-name=sc31_LSTM_V7
#SBATCH --mem=20G

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
print("SC31: LSTM V7 - FIXED TIME SERIES + SEQUENTIAL SELECTION")
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

# LSTM
SEQ_LEN = 132  # 11 years × 12 months - FIXED
SELECTION_LAYERS = 1
SELECTION_DROPOUT = 0.1
SELECTION_EPOCHS = 15
SELECTION_LR = 1e-3

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
print(f"  Selection: {SELECTION_EPOCHS} epochs, {SELECTION_HIDDEN} hidden")
print(f"  Final: {FINAL_EPOCHS} epochs, {FINAL_HIDDEN} hidden")
print(f"{'='*100}")

# Data Files - CORRECTED
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

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
# PHASE 1: LOAD DATA
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
# PHASE 2: ALIGN X AND Y
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: ALIGN X AND Y")
print("="*100)

merge_keys = ['IDr', 'YYYY', 'MM']
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
X['__key__'] = X['IDr'].astype(str) + '_' + X['YYYY'].astype(str) + '_' + X['MM'].astype(str)
Y['__key__'] = Y['IDr'].astype(str) + '_' + Y['YYYY'].astype(str) + '_' + Y['MM'].astype(str)

common_keys = set(X['__key__']) & set(Y['__key__'])

X = X[X['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)
Y = Y[Y['__key__'].isin(common_keys)].sort_values('__key__').reset_index(drop=True)

X = X.drop(columns=['__key__'])
Y = Y.drop(columns=['__key__'])

print(f"After: X={len(X)}, Y={len(Y)}")

# =========================================================================
# PHASE 3: CHECK CONSECUTIVE MONTHS (FULL DATASET)
# =========================================================================
print("\n" + "="*100)
print(f"PHASE 3: CHECK {SEQ_LEN} CONSECUTIVE MONTHS (FULL DATASET)")
print("="*100)

def check_consecutive_months(df, min_length):
    """Check max consecutive months per station"""
    station_consecutive = {}
    
    for idr, group in df.groupby('IDr'):
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
        
        station_consecutive[idr] = max_consecutive
    
    return station_consecutive

X_sorted = X.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)

print(f"Analyzing {X['IDr'].nunique()} stations...")
station_months = check_consecutive_months(X_sorted, SEQ_LEN)

valid_stations = [idr for idr, months in station_months.items() if months >= SEQ_LEN]
invalid_stations = [idr for idr, months in station_months.items() if months < SEQ_LEN]

print(f"\n  Total stations: {len(station_months)}")
print(f"  Valid (≥{SEQ_LEN} consecutive): {len(valid_stations)}")
print(f"  Invalid (<{SEQ_LEN} consecutive): {len(invalid_stations)} (DISCARDED)")

if len(invalid_stations) > 0:
    invalid_months = [station_months[idr] for idr in invalid_stations]
    print(f"\n  Discarded stats:")
    print(f"    Mean consecutive: {np.mean(invalid_months):.1f}")
    print(f"    Max consecutive: {np.max(invalid_months):.0f}")

if len(valid_stations) == 0:
    print(f"\n❌ ERROR: No stations have {SEQ_LEN} consecutive months!")
    print(f"  Maximum available: {max(station_months.values())}")
    sys.exit(1)

# Filter to valid stations
print(f"\nFiltering to {len(valid_stations)} valid stations...")
X = X[X['IDr'].isin(valid_stations)].reset_index(drop=True)
Y = Y[Y['IDr'].isin(valid_stations)].reset_index(drop=True)

print(f"After filter: X={len(X)}, Y={len(Y)}")

del X_sorted, station_months
gc.collect()

# =========================================================================
# PHASE 4: CREATE DERIVED FEATURES
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
# PHASE 5: CREATE SPECIFIC DISCHARGE
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
# PHASE 6: SPEARMAN DECORRELATION (FULL DATASET)
# =========================================================================
print("\n" + "="*100)
print("PHASE 6: SPEARMAN DECORRELATION (FULL DATASET)")
print("="*100)

def compute_pairwise_correlation_chunk(col_pairs, df_g):
    results = []
    for i, j in col_pairs:
        try:
            r, _ = spearmanr(df_g.iloc[:, i].values, df_g.iloc[:, j].values, nan_policy='omit')
            if not np.isnan(r):
                results.append((df_g.columns[i], df_g.columns[j], abs(r)))
        except:
            pass
    return results

def decorrelate_by_spearman_parallel(X_df, groups, threshold, n_jobs):
    print(f"  Input: {len(X_df.columns)} features")
    
    df = X_df.copy()
    df['__IDr__'] = groups
    
    # Aggregate at station level
    df_station = df.groupby('__IDr__', observed=True).mean(numeric_only=True)
    df_station = df_station.replace([np.inf, -np.inf], np.nan).fillna(df_station.median())
    
    print(f"  Aggregated to {len(df_station)} stations")
    print(f"  Computing correlations...")
    
    n_features = len(df_station.columns)
    pairs = [(i, j) for i in range(n_features) for j in range(i+1, n_features)]
    chunk_size = max(1, len(pairs) // (n_jobs * 4))
    chunks = [pairs[i:i+chunk_size] for i in range(0, len(pairs), chunk_size)]
    
    with parallel_backend('loky', n_jobs=n_jobs):
        chunk_results = Parallel()(
            delayed(compute_pairwise_correlation_chunk)(chunk, df_station)
            for chunk in chunks
        )
    
    all_correlations = [item for sublist in chunk_results for item in sublist]
    
    high_corr_pairs = {}
    for col1, col2, corr in all_correlations:
        if corr > threshold:
            if col1 not in high_corr_pairs:
                high_corr_pairs[col1] = []
            high_corr_pairs[col1].append(col2)
    
    features = list(df_station.columns)
    to_drop = set()
    kept = []
    
    for feat in features:
        if feat in to_drop:
            continue
        kept.append(feat)
        if feat in high_corr_pairs:
            for corr_feat in high_corr_pairs[feat]:
                if corr_feat not in kept:
                    to_drop.add(corr_feat)
    
    print(f"  Output: {len(kept)} KEPT, {len(to_drop)} DISCARDED")
    
    del df, df_station, all_correlations
    gc.collect()
    
    return kept

X_static_df = X[[c for c in static_present if c in X.columns]]
static_decorrelated = decorrelate_by_spearman_parallel(
    X_static_df, X['IDr'].to_numpy(), SPEARMAN_STATION_THRESHOLD, NCPU
)

print(f"\n✓ {len(static_present)} → {len(static_decorrelated)} features")

del X_static_df
gc.collect()

# =========================================================================
# PHASE 7: SEQUENTIAL FORWARD SELECTION (FULL DATASET)
# =========================================================================
if USE_SEQUENTIAL_SELECTION and len(static_decorrelated) > 0:
    print("\n" + "="*100)
    print("PHASE 7: SEQUENTIAL FORWARD SELECTION (FULL DATASET)")
    print("="*100)
    print(f"Pool: {len(static_decorrelated)} static features")
    print(f"Target: Select up to {MAX_STATIC_FEATURES} features")
    print("="*100)
    
    # Prepare full dataset for selection
    def clean_data(df):
        return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))
    
    X_dyn_full = clean_data(X[dynamic_final]).astype('float32')
    X_sta_full = clean_data(X[static_decorrelated]).astype('float32')
    Y_full = clean_data(Y[q_cols_target]).astype('float32')
    
    # Scale
    print("\nScaling full dataset for selection...")
    scaler_dyn = StandardScaler()
    scaler_sta = StandardScaler()
    scaler_y = StandardScaler()
    
    X_dyn_full_s = scaler_dyn.fit_transform(X_dyn_full).astype('float32')
    X_sta_full_s = scaler_sta.fit_transform(X_sta_full).astype('float32')
    Y_full_s = scaler_y.fit_transform(Y_full).astype('float32')
    
    # Build sequences (use shorter SEQ_LEN for selection speed)
    SELECTION_SEQ_LEN = min(SEQ_LEN, 60)  # Use 60 months for faster selection
    
    print(f"\nBuilding sequences (SEQ_LEN={SELECTION_SEQ_LEN} for selection)...")
    
    def build_sequences_simple(df_meta, X_dyn, X_sta, Y, seq_len):
        df = df_meta.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)
        
        X_seq_dyn, X_seq_sta, Y_last = [], [], []
        
        for idr, group in df.groupby('IDr'):
            indices = group.index.tolist()
            n = len(indices)
            
            if n < seq_len:
                continue
            
            for j in range(seq_len - 1, n):
                seq_idx = indices[j-seq_len+1:j+1]
                X_seq_dyn.append(X_dyn[seq_idx])
                X_seq_sta.append(X_sta[indices[j]])
                Y_last.append(Y[indices[j]])
        
        return (
            np.array(X_seq_dyn, dtype=np.float32),
            np.array(X_seq_sta, dtype=np.float32),
            np.array(Y_last, dtype=np.float32)
        )
    
    X_meta = X[['IDr', 'YYYY', 'MM']]
    X_seq_dyn_sel, X_seq_sta_sel, Y_seq_sel = build_sequences_simple(
        X_meta, X_dyn_full_s, X_sta_full_s, Y_full_s, SELECTION_SEQ_LEN
    )
    
    print(f"  Sequences for selection: {X_seq_dyn_sel.shape[0]:,}")
    
    del X_dyn_full, X_sta_full, Y_full, X_dyn_full_s, X_meta
    gc.collect()
    
    # LSTM for selection
    class LSTMWithContext(nn.Module):
        def __init__(self, n_dyn, n_sta, hidden, num_layers, dropout, out_dim):
            super().__init__()
            self.lstm = nn.LSTM(n_dyn, hidden, num_layers, batch_first=True,
                               dropout=dropout if num_layers > 1 else 0.0)
            if n_sta > 0:
                self.static_encoder = nn.Sequential(
                    nn.Linear(n_sta, max(8, n_sta // 2)),
                    nn.ReLU(),
                    nn.Dropout(dropout)
                )
                fusion_dim = hidden + max(8, n_sta // 2)
            else:
                self.static_encoder = None
                fusion_dim = hidden
            
            self.head = nn.Sequential(
                nn.Linear(fusion_dim, hidden),
                nn.ReLU(),
                nn.Dropout(dropout),
                nn.Linear(hidden, out_dim)
            )

        def forward(self, x_dyn, x_sta):
            out, _ = self.lstm(x_dyn)
            h_last = out[:, -1, :]
            if self.static_encoder and x_sta.shape[1] > 0:
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
    
    def train_lightweight_lstm(X_dyn, X_sta_indices, Y, X_sta_pool):
        """Train lightweight LSTM for feature evaluation"""
        
        if len(X_sta_indices) > 0:
            X_sta = X_sta_pool[:, X_sta_indices]
        else:
            X_sta = np.zeros((len(X_sta_pool), 0), dtype=np.float32)
        
        dataset = LSTMDataset(X_dyn, X_sta, Y)
        loader = DataLoader(
            dataset, 
            batch_size=SELECTION_BATCH, 
            shuffle=True,
            num_workers=0,
            pin_memory=False
        )
        
        n_dyn = X_dyn.shape[2]
        n_sta = X_sta.shape[1]
        
        model = LSTMWithContext(
            n_dyn, n_sta, 
            SELECTION_HIDDEN, SELECTION_LAYERS, SELECTION_DROPOUT,
            len(q_cols_target)
        ).to(DEVICE)
        
        opt = torch.optim.Adam(model.parameters(), lr=SELECTION_LR)
        loss_fn = nn.MSELoss()
        
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
        if USE_GPU:
            torch.cuda.empty_cache()
        gc.collect()
        
        return val_loss
    
    # Baseline
    print("\n" + "-"*100)
    print("Baseline (dynamic only)")
    print("-"*100)
    
    baseline_loss = train_lightweight_lstm(
        X_seq_dyn_sel, [], Y_seq_sel, X_seq_sta_sel
    )
    
    print(f"✓ Baseline loss: {baseline_loss:.6f}")
    
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
        print(f"  Current: {len(selected_static_indices)} features")
        print(f"  Pool: {len(remaining_indices)} remaining")
        
        best_candidate = None
        best_candidate_loss = best_loss
        
        for idx, candidate_idx in enumerate(remaining_indices):
            test_indices = selected_static_indices + [candidate_idx]
            
            loss = train_lightweight_lstm(
                X_seq_dyn_sel, test_indices, Y_seq_sel, X_seq_sta_sel
            )
            
            if loss < best_candidate_loss:
                best_candidate_loss = loss
                best_candidate = candidate_idx
            
            if (idx + 1) % 10 == 0 or (idx + 1) == len(remaining_indices):
                print(f"    Tested {idx + 1}/{len(remaining_indices)}...")
        
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
            print(f"    Loss: {best_candidate_loss:.6f} (Δ={improvement:.6f})")
        else:
            patience_counter += 1
            print(f"\n  ✗ No improvement (patience: {patience_counter}/{SELECTION_PATIENCE})")
            
            if patience_counter >= SELECTION_PATIENCE:
                print(f"\n  Early stop: no improvement for {SELECTION_PATIENCE} iterations")
                break
    
    static_final = selected_static_names
    
    print("\n" + "="*100)
    print("SELECTION SUMMARY")
    print("="*100)
    print(f"Selected {len(static_final)} static features:")
    for i, (feat, info) in enumerate(zip(static_final, selection_history), 1):
        print(f"  {i:2d}. {feat:30s} | loss={info['loss']:.6f}, Δ={info['improvement']:.6f}")
    
    print(f"\nImprovement: {baseline_loss - best_loss:.6f} ({(baseline_loss - best_loss)/baseline_loss*100:.2f}%)")
    
    # Save
    selection_df = pd.DataFrame(selection_history)
    selection_df.to_csv('../predict_score_red/LSTM_sequential_selection_v7.txt', sep=' ', index=False)
    print(f"\n✓ Saved: ../predict_score_red/LSTM_sequential_selection_v7.txt")
    
    del X_seq_dyn_sel, X_seq_sta_sel, Y_seq_sel, X_sta_full_s, Y_full_s
    gc.collect()
    
else:
    static_final = static_decorrelated
    print(f"\n✓ Using all {len(static_final)} decorrelated features (no sequential selection)")

# =========================================================================
# PHASE 8: TEMPORAL SPLIT
# =========================================================================
print("\n" + "="*100)
print("PHASE 8: TEMPORAL SPLIT")
print("="*100)

min_year = Y['YYYY'].min()
max_year = Y['YYYY'].max()

if max_year - min_year + 1 < TRAIN_YEARS + TEST_YEARS:
    TRAIN_YEARS = int((max_year - min_year + 1) * 0.5)
    TEST_YEARS = (max_year - min_year + 1) - TRAIN_YEARS

TRAIN_START = min_year
TRAIN_END = TRAIN_START + TRAIN_YEARS - 1
TEST_START = TRAIN_END + 1
TEST_END = TEST_START + TEST_YEARS - 1

print(f"Train: {TRAIN_START}-{TRAIN_END} ({TRAIN_YEARS} years)")
print(f"Test:  {TEST_START}-{TEST_END} ({TEST_YEARS} years)")

train_mask = (X['YYYY'] >= TRAIN_START) & (X['YYYY'] <= TRAIN_END)
test_mask = (X['YYYY'] >= TEST_START) & (X['YYYY'] <= TEST_END)

X_train = X[train_mask].copy().reset_index(drop=True)
Y_train = Y[train_mask].copy().reset_index(drop=True)
X_test = X[test_mask].copy().reset_index(drop=True)
Y_test = Y[test_mask].copy().reset_index(drop=True)

print(f"Train: X {X_train.shape}, Y {Y_train.shape}, Stations: {X_train['IDr'].nunique()}")
print(f"Test:  X {X_test.shape}, Y {Y_test.shape}, Stations: {X_test['IDr'].nunique()}")

del X, Y, train_mask, test_mask
gc.collect()

# =========================================================================
# PHASE 9: PREPARE FINAL DATA
# =========================================================================
print("\n" + "="*100)
print("PHASE 9: PREPARE FINAL DATA")
print("="*100)

def clean_data(df):
    return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))

X_train_dyn = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_data(X_test[dynamic_final]).astype('float32')

if len(static_final) > 0:
    X_train_sta = clean_data(X_train[static_final]).astype('float32')
    X_test_sta = clean_data(X_test[static_final]).astype('float32')
else:
    X_train_sta = pd.DataFrame(np.zeros((len(X_train), 0), dtype=np.float32))
    X_test_sta = pd.DataFrame(np.zeros((len(X_test), 0), dtype=np.float32))

Y_train_qdf = clean_data(Y_train[q_cols_target]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols_target]).astype('float32')

print("Scaling...")

scaler_dyn_final = StandardScaler()
scaler_sta_final = StandardScaler()
scaler_y_final = StandardScaler()

X_train_dyn_s = scaler_dyn_final.fit_transform(X_train_dyn).astype('float32')
X_test_dyn_s = scaler_dyn_final.transform(X_test_dyn).astype('float32')

if len(static_final) > 0:
    X_train_sta_s = scaler_sta_final.fit_transform(X_train_sta).astype('float32')
    X_test_sta_s = scaler_sta_final.transform(X_test_sta).astype('float32')
else:
    X_train_sta_s = np.zeros((len(X_train_dyn_s), 0), dtype=np.float32)
    X_test_sta_s = np.zeros((len(X_test_dyn_s), 0), dtype=np.float32)

Y_train_s = scaler_y_final.fit_transform(Y_train_qdf).astype('float32')
Y_test_s = scaler_y_final.transform(Y_test_qdf).astype('float32')

print("✓ Scaling complete")

# =========================================================================
# PHASE 10: BUILD SEQUENCES (GAP-AWARE)
# =========================================================================
print(f"\n{'='*100}")
print(f"PHASE 10: BUILD SEQUENCES (SEQ_LEN={SEQ_LEN}, GAP-AWARE)")
print(f"{'='*100}")

def build_sequences_gap_aware(df_meta, X_dyn, X_sta, Y, seq_len):
    """Build sequences ONLY from consecutive months (no gaps)"""
    
    df = df_meta.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    stations_used = 0
    stations_skipped = 0
    total_sequences = 0
    
    for idr, group in df.groupby('IDr'):
        group = group.sort_values(['YYYY', 'MM']).reset_index(drop=True)
        group['date'] = pd.to_datetime(
            group['YYYY'].astype(str) + '-' + group['MM'].astype(str).str.zfill(2) + '-01'
        )
        
        # Find consecutive blocks
        consecutive_blocks = []
        current_block = []
        
        for i in range(len(group)):
            if i == 0:
                current_block.append(group.iloc[i].name)
            else:
                expected_date = group.iloc[i-1]['date'] + pd.DateOffset(months=1)
                actual_date = group.iloc[i]['date']
                
                if expected_date == actual_date:
                    current_block.append(group.iloc[i].name)
                else:
                    # Gap detected
                    if len(current_block) >= seq_len:
                        consecutive_blocks.append(current_block)
                    current_block = [group.iloc[i].name]
        
        # Last block
        if len(current_block) >= seq_len:
            consecutive_blocks.append(current_block)
        
        # Build sequences from each block
        if len(consecutive_blocks) > 0:
            stations_used += 1
            for block in consecutive_blocks:
                for j in range(seq_len - 1, len(block)):
                    seq_idx = block[j-seq_len+1:j+1]
                    X_seq_dyn.append(X_dyn[seq_idx])
                    X_seq_sta.append(X_sta[block[j]])
                    Y_last.append(Y[block[j]])
                    idx_last.append(block[j])
                    total_sequences += 1
        else:
            stations_skipped += 1
    
    print(f"  Stations: used={stations_used}, skipped={stations_skipped}")
    print(f"  Sequences: {total_sequences}")
    
    return (
        np.array(X_seq_dyn, dtype=np.float32) if total_sequences > 0 else np.zeros((0, seq_len, X_dyn.shape[1]), dtype=np.float32),
        np.array(X_seq_sta, dtype=np.float32) if total_sequences > 0 else np.zeros((0, X_sta.shape[1]), dtype=np.float32),
        np.array(Y_last, dtype=np.float32) if total_sequences > 0 else np.zeros((0, Y.shape[1]), dtype=np.float32),
        np.array(idx_last, dtype=np.int64) if total_sequences > 0 else np.array([], dtype=np.int64)
    )

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']]
Xte_meta = X_test[['IDr', 'YYYY', 'MM']]

print("\nTrain:")
Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_idx = build_sequences_gap_aware(
    Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s, SEQ_LEN
)

print("\nTest:")
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_idx = build_sequences_gap_aware(
    Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s, SEQ_LEN
)

if Xtr_seq_dyn.shape[0] == 0:
    print("\n❌ ERROR: No training sequences!")
    sys.exit(1)

if Xte_seq_dyn.shape[0] == 0:
    print("\n⚠️ WARNING: No test sequences - evaluation will be skipped")
    SKIP_EVAL = True
else:
    SKIP_EVAL = False

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
if not SKIP_EVAL:
    Yte_true = Y_test_qdf.to_numpy()[te_idx]

# =========================================================================
# PHASE 11: FINAL LSTM TRAINING
# =========================================================================
print("\n" + "="*100)
print("PHASE 11: FINAL LSTM TRAINING")
print("="*100)

print(f"\nConfiguration:")
print(f"  Input: {len(dynamic_final)} dynamic + {len(static_final)} static")
print(f"  Sequence: {SEQ_LEN} timesteps")
print(f"  Architecture: {FINAL_HIDDEN} hidden × {FINAL_LAYERS} layers")
print(f"  Batch: {FINAL_BATCH}, Epochs: {FINAL_EPOCHS}")
print(f"  Device: {DEVICE}")

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq)
train_loader = DataLoader(
    train_ds, 
    batch_size=FINAL_BATCH, 
    shuffle=True, 
    num_workers=NUM_WORKERS,
    pin_memory=USE_GPU,
    persistent_workers=(NUM_WORKERS > 0)
)

if not SKIP_EVAL:
    test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)
    test_loader = DataLoader(
        test_ds, 
        batch_size=FINAL_BATCH, 
        shuffle=False, 
        num_workers=NUM_WORKERS,
        pin_memory=USE_GPU,
        persistent_workers=(NUM_WORKERS > 0)
    )

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = LSTMWithContext(n_dyn, n_sta, FINAL_HIDDEN, FINAL_LAYERS, FINAL_DROPOUT, len(q_cols_target)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=FINAL_LR)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(opt, mode='min', factor=LR_FACTOR, patience=LR_PATIENCE)
loss_fn = nn.MSELoss()

scaler_amp = GradScaler() if USE_MIXED_PRECISION else None

total_params = sum(p.numel() for p in model.parameters())
print(f"\nParameters: {total_params:,}")

def run_epoch(loader, train=True):
    model.train() if train else model.eval()
    losses, preds = [], []

    for x_dyn, x_sta, y in loader:
        x_dyn = x_dyn.to(DEVICE, non_blocking=True)
        x_sta = x_sta.to(DEVICE, non_blocking=True)
        y = y.to(DEVICE, non_blocking=True)

        if train:
            opt.zero_grad(set_to_none=True)

        if USE_MIXED_PRECISION and scaler_amp:
            with autocast():
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
            
            if train:
                scaler_amp.scale(loss).backward()
                scaler_amp.unscale_(opt)
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler_amp.step(opt)
                scaler_amp.update()
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

    return np.mean(losses), np.concatenate(preds) if preds else np.zeros((0, len(q_cols_target)), dtype=np.float32)

print("\nTraining:")
best_val = np.inf
best_state = None
patience = 0

for ep in range(1, FINAL_EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, True)
    
    if not SKIP_EVAL:
        te_loss, _ = run_epoch(test_loader, False)
        scheduler.step(te_loss)
        
        if te_loss < best_val:
            best_val = te_loss
            best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
            patience = 0
        else:
            patience += 1
    else:
        te_loss = np.nan
        best_val = tr_loss
        best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
    
    if ep % 10 == 0 or ep == 1:
        print(f'Epoch {ep:3d} | train={tr_loss:.5f} | test={te_loss:.5f} | best={best_val:.5f}')
    
    if not SKIP_EVAL and patience >= EARLY_STOP_PATIENCE:
        print(f'Early stop at epoch {ep}')
        break

if best_state:
    model.load_state_dict(best_state)

print(f"\n✓ Training complete. Best loss: {best_val:.5f}")

# Predictions
_, Ptr = run_epoch(train_loader, False)
Q_train_pred = scaler_y_final.inverse_transform(Ptr).astype('float32')

if not SKIP_EVAL:
    _, Pte = run_epoch(test_loader, False)
    Q_test_pred = scaler_y_final.inverse_transform(Pte).astype('float32')

# =========================================================================
# PHASE 12: METRICS
# =========================================================================
print("\n" + "="*100)
print("PHASE 12: PERFORMANCE EVALUATION")
print("="*100)

def kge_1d(y_true, y_pred):
    if np.all(y_true == y_true[0]) or len(y_true) < 2:
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1] if np.std(y_true) > 0 and np.std(y_pred) > 0 else np.nan
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    if np.isnan(r) or np.isnan(beta) or np.isnan(gamma):
        return np.nan
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

def compute_metrics(Y_true, Y_pred):
    metrics = {}
    for i in range(len(q_cols_target)):
        try:
            metrics.setdefault('r', []).append(pearsonr(Y_pred[:, i], Y_true[:, i])[0])
            metrics.setdefault('nse', []).append(1 - np.sum((Y_true[:, i] - Y_pred[:, i])**2) / np.sum((Y_true[:, i] - np.mean(Y_true[:, i]))**2))
            metrics.setdefault('kge', []).append(kge_1d(Y_true[:, i], Y_pred[:, i]))
        except:
            metrics.setdefault('r', []).append(np.nan)
            metrics.setdefault('nse', []).append(np.nan)
            metrics.setdefault('kge', []).append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true, Q_train_pred)

print(f"\nTRAIN: r={train_metrics['r'][0]:.4f}, NSE={train_metrics['nse'][0]:.4f}, KGE={train_metrics['kge'][0]:.4f}")

if not SKIP_EVAL:
    test_metrics = compute_metrics(Yte_true, Q_test_pred)
    print(f"TEST:  r={test_metrics['r'][0]:.4f}, NSE={test_metrics['nse'][0]:.4f}, KGE={test_metrics['kge'][0]:.4f}")

# =========================================================================
# PHASE 13: SAVE OUTPUTS
# =========================================================================
print("\n" + "="*100)
print("PHASE 13: SAVE OUTPUTS")
print("="*100)

suffix = '_seq_sel' if USE_SEQUENTIAL_SELECTION else '_spearman_only'

np.savetxt(f'../predict_prediction_red/LSTM_train_v7{suffix}.txt', Q_train_pred, fmt='%.6f', header=' '.join(q_cols_target), comments='')
print(f"✓ Saved: ../predict_prediction_red/LSTM_train_v7{suffix}.txt")

if not SKIP_EVAL:
    np.savetxt(f'../predict_prediction_red/LSTM_test_v7{suffix}.txt', Q_test_pred, fmt='%.6f', header=' '.join(q_cols_target), comments='')
    print(f"✓ Saved: ../predict_prediction_red/LSTM_test_v7{suffix}.txt")

with open(f'../predict_importance_red/LSTM_features_v7{suffix}.txt', 'w') as f:
    f.write(f'SC31 LSTM V7 - FIXED TIME SERIES\n')
    f.write(f'='*80 + '\n\n')
    f.write(f'Hardware: {torch.cuda.get_device_name(0) if USE_GPU else "CPU"}\n')
    f.write(f'Sequential Selection: {USE_SEQUENTIAL_SELECTION}\n')
    f.write(f'Sequence Length: {SEQ_LEN} months\n\n')
    f.write(f'DYNAMIC FEATURES ({len(dynamic_final)})\n')
    f.write('-'*80 + '\n')
    for d in dynamic_final:
        f.write(f'{d}\n')
    f.write(f'\nSTATIC FEATURES ({len(static_final)})\n')
    f.write('-'*80 + '\n')
    for s in static_final:
        f.write(f'{s}\n')
    f.write(f'\nPERFORMANCE\n')
    f.write('-'*80 + '\n')
    f.write(f'TRAIN: r={train_metrics["r"][0]:.4f}, NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}\n')
    if not SKIP_EVAL:
        f.write(f'TEST:  r={test_metrics["r"][0]:.4f}, NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}\n')

print(f"✓ Saved: ../predict_importance_red/LSTM_features_v7{suffix}.txt")

print(f"\n{'='*100}")
print(f"✓ COMPLETE: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"{'='*100}")

EOFPYTHON

if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "=== GPU INFO ==="
    nvidia-smi
fi
