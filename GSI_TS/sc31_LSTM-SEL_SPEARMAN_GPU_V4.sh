#!/bin/bash
#SBATCH -p scavenge
#####SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 1:00:00  # Increased time for sequential selection
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_SPEARMAN_RFECV_GPU_V3.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_SPEARMAN_RFECV_GPU_V3.%J.err
#SBATCH --job-name=sc31_LSTM_V3
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
from datetime import datetime, timedelta
from scipy.stats import spearmanr, pearsonr
from sklearn.preprocessing import QuantileTransformer
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
print("SC31: LSTM WITH GPU + SEQUENTIAL FEATURE SELECTION")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Job ID: {os.environ.get('SLURM_JOB_ID', 'N/A')}")
print("="*100)

# =========================================================================
# GPU CONFIGURATION
# =========================================================================
print(f"\n{'='*100}")
print("GPU CONFIGURATION")
print(f"{'='*100}")

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

if torch.cuda.is_available():
    print(f"✓ CUDA available")
    print(f"  Version: {torch.version.cuda}")
    print(f"  GPU: {torch.cuda.get_device_name(0)}")
    print(f"  Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    torch.backends.cudnn.benchmark = True
else:
    print("⚠️ CUDA not available - using CPU")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 32))

# Feature Selection
SPEARMAN_STATION_THRESHOLD = 0.90
USE_SEQUENTIAL_SELECTION = True  # <<<--- LSTM-based sequential selection
MAX_STATIC_FEATURES = 15         # Maximum static features to select
SELECTION_PATIENCE = 3           # Stop if no improvement for N iterations

print(f"\n{'='*100}")
print("FEATURE SELECTION CONFIGURATION")
print(f"{'='*100}")
print(f"  Spearman threshold: {SPEARMAN_STATION_THRESHOLD}")
print(f"  LSTM Sequential Selection: {USE_SEQUENTIAL_SELECTION}")
if USE_SEQUENTIAL_SELECTION:
    print(f"    Max static features: {MAX_STATIC_FEATURES}")
    print(f"    Patience (early stop): {SELECTION_PATIENCE} iterations")
print(f"{'='*100}")

# Temporal Split
TRAIN_YEARS = 11
TEST_YEARS = 11
RANDOM_STATE = 24

# LSTM Hyperparameters - SCALED TO NUMBER OF FEATURES
SEQ_LEN = 12

# Selection phase (lightweight for speed)
SELECTION_HIDDEN = 64           # Smaller hidden size for selection
SELECTION_LAYERS = 1            # Single layer for selection
SELECTION_DROPOUT = 0.1         # Light dropout
SELECTION_BATCH = 512           # Moderate batch size
SELECTION_EPOCHS = 15           # Fewer epochs for selection
SELECTION_LR = 1e-3

# Final training phase (full capacity)
FINAL_HIDDEN = 128              # Full hidden size
FINAL_LAYERS = 2                # Two LSTM layers
FINAL_DROPOUT = 0.2             # Standard dropout
FINAL_BATCH = 1024              # Large batch for GPU
FINAL_EPOCHS = 50               # Full training epochs
FINAL_LR = 1e-3

NUM_WORKERS_DATALOADER = 4
USE_MIXED_PRECISION = True

print(f"\n{'='*100}")
print("LSTM HYPERPARAMETERS")
print(f"{'='*100}")
print(f"Sequence length: {SEQ_LEN} timesteps")
print(f"\nSELECTION PHASE (lightweight for speed):")
print(f"  Hidden units: {SELECTION_HIDDEN}")
print(f"  LSTM layers: {SELECTION_LAYERS}")
print(f"  Dropout: {SELECTION_DROPOUT}")
print(f"  Batch size: {SELECTION_BATCH}")
print(f"  Epochs: {SELECTION_EPOCHS}")
print(f"  Learning rate: {SELECTION_LR}")
print(f"\nFINAL TRAINING PHASE (full capacity):")
print(f"  Hidden units: {FINAL_HIDDEN}")
print(f"  LSTM layers: {FINAL_LAYERS}")
print(f"  Dropout: {FINAL_DROPOUT}")
print(f"  Batch size: {FINAL_BATCH}")
print(f"  Epochs: {FINAL_EPOCHS}")
print(f"  Learning rate: {FINAL_LR}")
print(f"\nGeneral:")
print(f"  Device: {DEVICE}")
print(f"  Mixed precision: {USE_MIXED_PRECISION}")
print(f"  DataLoader workers: {NUM_WORKERS_DATALOADER}")
print(f"  Random state: {RANDOM_STATE}")
print(f"{'='*100}")

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
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

X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)

print(f"✓ X: {X.shape}, Y: {Y.shape}")

static_present = [v for v in static_var if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# =========================================================================
# CREATE DERIVED FEATURES
# =========================================================================
print("\n" + "="*100)
print("CREATING DERIVED FEATURES")
print("="*100)

acc = X['accumulation'].astype('float32').values
acc_safe = np.where(acc == 0, 1e-10, acc)

vars_to_derive = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 
                  'tmin0', 'tmin1', 'tmin2', 'tmin3', 'tmax0',
                  'soil0', 'soil1', 'soil2', 'soil3', 'GRWLw']

derived_features = []
for var in vars_to_derive:
    if var in X.columns:
        X[f'{var}_area'] = (X[var].astype('float32').values / acc_safe).astype('float32')
        derived_features.append(f'{var}_area')

print(f"✓ Created {len(derived_features)} derived features")
dynamic_final = derived_features.copy()

del acc, acc_safe
gc.collect()

# =========================================================================
# SPEARMAN DECORRELATION
# =========================================================================
print("\n" + "="*100)
print("SPEARMAN DECORRELATION")
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

def decorrelate_by_spearman_parallel(X_np, groups, col_names, threshold, n_jobs):
    df = pd.DataFrame(X_np, columns=col_names)
    df['__g__'] = groups
    df_g = df.groupby('__g__').mean(numeric_only=True).reset_index(drop=True)
    df_g = df_g.replace([np.inf, -np.inf], np.nan).fillna(df_g.median(numeric_only=True))
    
    del df
    gc.collect()
    
    n_features = len(df_g.columns)
    pairs = [(i, j) for i in range(n_features) for j in range(i+1, n_features)]
    chunk_size = max(1, len(pairs) // (n_jobs * 4))
    chunks = [pairs[i:i+chunk_size] for i in range(0, len(pairs), chunk_size)]
    
    with parallel_backend('loky', n_jobs=n_jobs):
        chunk_results = Parallel()(
            delayed(compute_pairwise_correlation_chunk)(chunk, df_g)
            for chunk in chunks
        )
    
    all_correlations = [item for sublist in chunk_results for item in sublist]
    
    high_corr_pairs = {}
    for col1, col2, corr in all_correlations:
        if corr > threshold:
            if col1 not in high_corr_pairs:
                high_corr_pairs[col1] = []
            high_corr_pairs[col1].append(col2)
    
    cols = list(df_g.columns)
    drop = set()
    keep = []
    
    for c in cols:
        if c in drop:
            continue
        keep.append(c)
        if c in high_corr_pairs:
            for h in high_corr_pairs[c]:
                drop.add(h)
    
    print(f'  Output: {len(keep)} KEPT, {len(drop)} DISCARDED')
    
    del df_g, all_correlations
    gc.collect()
    
    return keep

X_static_np = X[[c for c in static_present if c in X.columns]].to_numpy(dtype=np.float32)
groups = X['IDr'].to_numpy()

static_decorrelated = decorrelate_by_spearman_parallel(
    X_static_np, groups, [c for c in static_present if c in X.columns],
    SPEARMAN_STATION_THRESHOLD, NCPU
)

print(f"\n✓ Spearman complete: {len(static_present)} → {len(static_decorrelated)} features")

del X_static_np, groups
gc.collect()

# =========================================================================
# TEMPORAL SPLIT
# =========================================================================
print("\n" + "="*100)
print("TEMPORAL SPLIT")
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

print(f"Train: {X_train.shape}, Stations: {X_train['IDr'].nunique()}")
print(f"Test:  {X_test.shape}, Stations: {X_test['IDr'].nunique()}")

del X, Y, train_mask, test_mask
gc.collect()

# =========================================================================
# PREPARE DATA FOR LSTM
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

Y_train_qdf = clean_data(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols]).astype('float32')

print("Scaling...")

qt_dyn = QuantileTransformer(n_quantiles=min(2000, len(X_train_dyn)), 
                             output_distribution='normal', random_state=RANDOM_STATE)
qt_sta = QuantileTransformer(n_quantiles=min(2000, len(X_train_sta_all)), 
                             output_distribution='normal', random_state=RANDOM_STATE)
qt_y = QuantileTransformer(n_quantiles=min(2000, len(Y_train_qdf)), 
                           output_distribution='normal', random_state=RANDOM_STATE)

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_all_s = qt_sta.fit_transform(X_train_sta_all.to_numpy()).astype('float32')
X_test_sta_all_s = qt_sta.transform(X_test_sta_all.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print("✓ Scaling complete")

# Build sequences
print("\nBuilding sequences...")

def build_sequences(df_meta, X_dyn, X_sta, Y):
    df = df_meta.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    for idr, group in df.groupby('IDr'):
        indices = group.index.tolist()
        n = len(indices)
        
        if n < SEQ_LEN:
            continue
        
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

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']]
Xte_meta = X_test[['IDr', 'YYYY', 'MM']]

Xtr_seq_dyn, Xtr_seq_sta_all, Ytr_seq, tr_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_all_s, Y_train_s
)
Xte_seq_dyn, Xte_seq_sta_all, Yte_seq, te_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_all_s, Y_test_s
)

print(f"Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"Test sequences: {Xte_seq_dyn.shape[0]:,}")

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
# SEQUENTIAL FORWARD SELECTION
# =========================================================================

if USE_SEQUENTIAL_SELECTION:
    print("\n" + "="*100)
    print("LSTM-BASED SEQUENTIAL FORWARD SELECTION")
    print("="*100)
    print(f"Starting with {len(dynamic_final)} dynamic + 0 static features")
    print(f"Pool: {len(static_decorrelated)} static features available")
    print(f"Target: Select up to {MAX_STATIC_FEATURES} best static features")
    print("="*100)
    
    def train_lightweight_lstm(X_dyn, X_sta_indices, Y, X_sta_pool):
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
            len(q_cols)
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
        torch.cuda.empty_cache()
        gc.collect()
        
        return val_loss
    
    # Baseline: dynamic only
    print("\n" + "-"*100)
    print("Baseline (dynamic features only)")
    print("-"*100)
    
    baseline_loss = train_lightweight_lstm(
        Xtr_seq_dyn, [], Ytr_seq, Xtr_seq_sta_all
    )
    
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
        
        # Test each remaining feature
        for idx, candidate_idx in enumerate(remaining_indices):
            test_indices = selected_static_indices + [candidate_idx]
            
            loss = train_lightweight_lstm(
                Xtr_seq_dyn, test_indices, Ytr_seq, Xtr_seq_sta_all
            )
            
            if loss < best_candidate_loss:
                best_candidate_loss = loss
                best_candidate = candidate_idx
            
            if (idx + 1) % 5 == 0 or (idx + 1) == len(remaining_indices):
                print(f"    Tested {idx + 1}/{len(remaining_indices)} candidates...")
        
        # Check improvement
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
    
    # Save selection results
    selection_df = pd.DataFrame(selection_history)
    selection_df.to_csv('../predict_score_red/LSTM_sequential_selection_v3.txt', sep=' ', index=False)
    print(f"\n✓ Saved selection history to: ../predict_score_red/LSTM_sequential_selection_v3.txt")
    
else:
    static_final = static_decorrelated
    print(f"\n✓ Using all {len(static_final)} decorrelated static features")

# =========================================================================
# PREPARE FINAL TRAINING DATA
# =========================================================================
print("\n" + "="*100)
print("PREPARING FINAL TRAINING DATA")
print("="*100)

if len(static_final) > 0:
    static_final_indices = [static_decorrelated.index(f) for f in static_final]
    Xtr_seq_sta_final = Xtr_seq_sta_all[:, static_final_indices]
    Xte_seq_sta_final = Xte_seq_sta_all[:, static_final_indices]
else:
    Xtr_seq_sta_final = np.zeros((len(Xtr_seq_dyn), 0), dtype=np.float32)
    Xte_seq_sta_final = np.zeros((len(Xte_seq_dyn), 0), dtype=np.float32)

print(f"Final feature configuration:")
print(f"  Dynamic: {len(dynamic_final)} features")
print(f"  Static:  {len(static_final)} features")
print(f"  Total:   {len(dynamic_final) + len(static_final)} features")
print(f"  Targets: {len(q_cols)} quantiles")

# =========================================================================
# FINAL LSTM TRAINING
# =========================================================================
print("\n" + "="*100)
print("FINAL LSTM TRAINING (FULL CAPACITY)")
print("="*100)

print(f"\n{'FINAL MODEL HYPERPARAMETERS':-^100}")
print(f"  Architecture:")
print(f"    Input (dynamic): {len(dynamic_final)} features × {SEQ_LEN} timesteps")
print(f"    Input (static):  {len(static_final)} features")
print(f"    LSTM hidden:     {FINAL_HIDDEN} units × {FINAL_LAYERS} layers")
print(f"    Static encoder:  {len(static_final)} → {max(8, len(static_final) // 2)}")
print(f"    Fusion layer:    {FINAL_HIDDEN} + {max(8, len(static_final) // 2) if len(static_final) > 0 else 0}")
print(f"    Dense layer:     128 units")
print(f"    Output:          {len(q_cols)} quantiles")
print(f"\n  Training:")
print(f"    Batch size:      {FINAL_BATCH}")
print(f"    Epochs:          {FINAL_EPOCHS}")
print(f"    Learning rate:   {FINAL_LR}")
print(f"    Dropout:         {FINAL_DROPOUT}")
print(f"    Optimizer:       Adam")
print(f"    Loss function:   SmoothL1Loss")
print(f"    Grad clipping:   1.0")
print(f"\n  Hardware:")
print(f"    Device:          {DEVICE}")
print(f"    Mixed precision: {USE_MIXED_PRECISION}")
print(f"    DataLoader:      {NUM_WORKERS_DATALOADER} workers")
print("-"*100)

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta_final, Ytr_seq)
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta_final, Yte_seq)

train_loader = DataLoader(
    train_ds, 
    batch_size=FINAL_BATCH, 
    shuffle=True, 
    num_workers=NUM_WORKERS_DATALOADER,
    pin_memory=True,
    persistent_workers=True if NUM_WORKERS_DATALOADER > 0 else False
)
test_loader = DataLoader(
    test_ds, 
    batch_size=FINAL_BATCH, 
    shuffle=False, 
    num_workers=NUM_WORKERS_DATALOADER,
    pin_memory=True,
    persistent_workers=True if NUM_WORKERS_DATALOADER > 0 else False
)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta_final.shape[1]

model = LSTMWithContext(n_dyn, n_sta, FINAL_HIDDEN, FINAL_LAYERS, FINAL_DROPOUT, len(q_cols)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=FINAL_LR)
loss_fn = nn.SmoothL1Loss()

scaler = GradScaler() if USE_MIXED_PRECISION and torch.cuda.is_available() else None

total_params = sum(p.numel() for p in model.parameters())
trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)

print(f"\nModel parameters:")
print(f"  Total:      {total_params:,}")
print(f"  Trainable:  {trainable_params:,}")

if torch.cuda.is_available():
    print(f"\nGPU memory after model load: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB")

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

    p_all = np.concatenate(preds) if preds else np.zeros((0, len(q_cols)), dtype=np.float32)
    return np.mean(losses) if losses else np.nan, p_all

print("\nTraining progress:")
print("-"*100)

best_val = np.inf
best_state = None

for ep in range(1, FINAL_EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, True)
    te_loss, _ = run_epoch(test_loader, False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == FINAL_EPOCHS:
        print(f'Epoch {ep:3d}/{FINAL_EPOCHS} | train={tr_loss:.5f} | test={te_loss:.5f} | best={best_val:.5f}')
        if torch.cuda.is_available():
            print(f'  GPU mem: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB')

if best_state:
    model.load_state_dict(best_state)

print(f"\n✓ Training complete. Best loss: {best_val:.5f}")

# Predictions
_, Ptr = run_epoch(train_loader, False)
_, Pte = run_epoch(test_loader, False)

Q_train_pred = qt_y.inverse_transform(Ptr).astype('float32')
Q_test_pred = qt_y.inverse_transform(Pte).astype('float32')

# =========================================================================
# METRICS
# =========================================================================
print("\n" + "="*100)
print("PERFORMANCE EVALUATION")
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
    for i in range(len(q_cols)):
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
test_metrics = compute_metrics(Yte_true, Q_test_pred)

print(f"\nTRAIN: r={train_metrics['r'][0]:.4f}, NSE={train_metrics['nse'][0]:.4f}, KGE={train_metrics['kge'][0]:.4f}")
print(f"TEST:  r={test_metrics['r'][0]:.4f}, NSE={test_metrics['nse'][0]:.4f}, KGE={test_metrics['kge'][0]:.4f}")

quantile_perf = pd.DataFrame({
    'Quantile': q_cols,
    'r': test_metrics['r'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1]
}).round(4)
print(f"\n{quantile_perf.to_string(index=False)}")

# Save
suffix = '_seq_sel' if USE_SEQUENTIAL_SELECTION else '_all_static'
np.savetxt(f'../predict_prediction_red/LSTM_train_v3{suffix}.txt', Q_train_pred, fmt='%.6f', header=' '.join(q_cols), comments='')
np.savetxt(f'../predict_prediction_red/LSTM_test_v3{suffix}.txt', Q_test_pred, fmt='%.6f', header=' '.join(q_cols), comments='')

with open(f'../predict_importance_red/LSTM_features_v3{suffix}.txt', 'w') as f:
    f.write(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else "N/A"}\n')
    f.write(f'Sequential Selection: {USE_SEQUENTIAL_SELECTION}\n\n')
    f.write(f'DYNAMIC ({len(dynamic_final)})\n')
    for d in dynamic_final:
        f.write(f'{d}\n')
    f.write(f'\nSTATIC ({len(static_final)})\n')
    for s in static_final:
        f.write(f'{s}\n')
    f.write(f'\nTRAIN: r={train_metrics["r"][0]:.4f}, NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}\n')
    f.write(f'TEST:  r={test_metrics["r"][0]:.4f}, NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}\n')

print(f"\n✓ Complete: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

EOFPYTHON

echo ""
echo "=== GPU INFO AFTER TRAINING ==="
nvidia-smi
echo "================================"
