#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_SPEARMAN_V1.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_SPEARMAN_V1.%A_%a.err
#SBATCH --job-name=sc31_LSTM_SPEARMAN_V1
#SBATCH --mem=20G

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
module unload SciPy-bundle

source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

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
from joblib import Parallel, delayed
import warnings
warnings.filterwarnings('ignore')

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("SC31: LSTM WITH SPEARMAN DECORRELATION PIPELINE")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# Temporal Split Parameters (11 years each)
TRAIN_YEARS = 11
TEST_YEARS = 11
TRAIN_START_YEAR = 2000  # Adjust based on your data
TEST_START_YEAR = TRAIN_START_YEAR + TRAIN_YEARS

# Spearman Decorrelation Thresholds
SPEARMAN_STATION_THRESHOLD = 0.85   # Station-level decorrelation
SPEARMAN_RESPONSE_THRESHOLD = 0.85  # Response-level filtering

# LSTM Parameters
SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X1_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y1_floredSFD.txt'

# =========================================================================
# STATIC AND DYNAMIC VARIABLE DEFINITIONS
# =========================================================================
static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'channel_dist_dw_seg', 'channel_elv_dw_seg', 'channel_grad_dw_seg',
    'elev', 'northness', 'eastness', 'convergence',
    'aspect-cosine', 'aspect-sine', 'elev-stdev',
    'pcurv', 'tcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tpi', 'tri', 'vrm',
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

print("Loading data...")
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)

print(f"✓ X shape: {X.shape}, Y shape: {Y.shape}")

# Identify available variables
all_cols = X.columns.tolist()
static_present = [v for v in static_var if v in all_cols]
dynamic_present = [v for v in dinamic_var if v in all_cols]

print(f"✓ Static variables available: {len(static_present)}/{len(static_var)}")
print(f"✓ Dynamic variables available: {len(dynamic_present)}/{len(dinamic_var)}")

# Target quantiles
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]
print(f"✓ Target quantiles: {len(q_cols)} - {', '.join(q_cols)}")

# Reset indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# =========================================================================
# PHASE 2: TEMPORAL TRAIN/TEST SPLIT (11 years each)
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: TEMPORAL TRAIN/TEST SPLIT")
print("="*100)

# Ensure YYYY and MM columns exist
if 'YYYY' not in Y.columns or 'MM' not in Y.columns:
    print("ERROR: YYYY and MM columns not found in dataset")
    sys.exit(1)

# Determine data range
min_year = Y['YYYY'].min()
max_year = Y['YYYY'].max()
print(f"Data range: {min_year} - {max_year} ({max_year - min_year + 1} years)")

# Adjust train/test split to actual data
if max_year - min_year + 1 < TRAIN_YEARS + TEST_YEARS:
    print(f"⚠ Insufficient data for {TRAIN_YEARS}+{TEST_YEARS} years split")
    # Use proportional split
    total_years = max_year - min_year + 1
    TRAIN_YEARS = int(total_years * 0.5)
    TEST_YEARS = total_years - TRAIN_YEARS
    print(f"  Adjusting to {TRAIN_YEARS} train + {TEST_YEARS} test years")

TRAIN_START_YEAR = min_year
TRAIN_END_YEAR = TRAIN_START_YEAR + TRAIN_YEARS - 1
TEST_START_YEAR = TRAIN_END_YEAR + 1
TEST_END_YEAR = TEST_START_YEAR + TEST_YEARS - 1

print(f"\nTrain period: {TRAIN_START_YEAR} - {TRAIN_END_YEAR} ({TRAIN_YEARS} years, {TRAIN_YEARS * 12} months)")
print(f"Test period:  {TEST_START_YEAR} - {TEST_END_YEAR} ({TEST_YEARS} years, {TEST_YEARS * 12} months)")

# Create train/test masks based on year
train_mask_X = (X['YYYY'] >= TRAIN_START_YEAR) & (X['YYYY'] <= TRAIN_END_YEAR)
train_mask_Y = (Y['YYYY'] >= TRAIN_START_YEAR) & (Y['YYYY'] <= TRAIN_END_YEAR)

test_mask_X = (X['YYYY'] >= TEST_START_YEAR) & (X['YYYY'] <= TEST_END_YEAR)
test_mask_Y = (Y['YYYY'] >= TEST_START_YEAR) & (Y['YYYY'] <= TEST_END_YEAR)

X_train = X[train_mask_X].copy().reset_index(drop=True)
Y_train = Y[train_mask_Y].copy().reset_index(drop=True)
X_test = X[test_mask_X].copy().reset_index(drop=True)
Y_test = Y[test_mask_Y].copy().reset_index(drop=True)

print(f"\nDataset shapes:")
print(f"  Train: X {X_train.shape}, Y {Y_train.shape}")
print(f"  Test:  X {X_test.shape}, Y {Y_test.shape}")
print(f"  Train stations: {X_train['IDr'].nunique()}")
print(f"  Test stations: {X_test['IDr'].nunique()}")

# =========================================================================
# PHASE 3: SPEARMAN DECORRELATION-BASED FEATURE SELECTION
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: SPEARMAN DECORRELATION-BASED FEATURE SELECTION")
print("="*100)

# Helper function for safe Spearman correlation
def _safe_spearman(a, b):
    """Compute Spearman correlation with error handling"""
    try:
        r, _ = spearmanr(a, b, nan_policy='omit')
        if np.isnan(r):
            return 0.0
        return float(r)
    except Exception:
        return 0.0

# -------------------------------------------------------------------------
# FUNCTION 1: decorrelate_by_spearman_station_level
# -------------------------------------------------------------------------
def decorrelate_by_spearman_station_level(X_np, groups, col_names, threshold=0.85):
    """
    Remove highly correlated static features at station level.
    
    Args:
        X_np: numpy array of features
        groups: station IDs (IDr)
        col_names: list of feature names
        threshold: correlation threshold (default 0.85)
    
    Returns:
        list of feature names to keep (decorrelated)
    """
    print(f"\n  Function: decorrelate_by_spearman_station_level(threshold={threshold})")
    print(f"  Input: {len(col_names)} features")
    
    # Create DataFrame and aggregate by station
    df = pd.DataFrame(X_np, columns=col_names)
    df['__g__'] = groups
    
    # Station-level means
    df_g = df.groupby('__g__', observed=True).mean(numeric_only=True).reset_index(drop=True)
    df_g = df_g.replace([np.inf, -np.inf], np.nan).fillna(df_g.median(numeric_only=True))
    
    if df_g.shape[1] == 0:
        print(f'  Output: 0 features kept (no valid data)')
        return []
    
    # Compute Spearman correlation matrix
    corr = df_g.corr(method='spearman').abs()
    cols = list(df_g.columns)
    
    # Upper triangle
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))
    
    # Greedy decorrelation
    drop = set()
    keep = []
    
    for c in cols:
        if c in drop:
            continue
        keep.append(c)
        # Find variables highly correlated with current variable
        high = upper.index[upper[c] > threshold].tolist()
        for h in high:
            drop.add(h)
    
    print(f'  Output: {len(keep)} features kept, {len(drop)} dropped')
    print(f'  Kept: {", ".join(keep[:10])}{"..." if len(keep) > 10 else ""}')
    
    return keep

# -------------------------------------------------------------------------
# FUNCTION 2: filter_static_by_response_spearman_obs_level_keep_high
# -------------------------------------------------------------------------
def filter_static_by_response_spearman_obs_level_keep_high(X_np, Y_np, col_names, threshold=0.85):
    """
    Keep static features highly correlated with response variables (quantiles).
    
    Args:
        X_np: numpy array of features
        Y_np: numpy array of response variables (quantiles)
        col_names: list of feature names
        threshold: correlation threshold (default 0.85)
    
    Returns:
        list of feature names to keep (highly correlated with response)
    """
    print(f"\n  Function: filter_static_by_response_spearman_obs_level_keep_high(threshold={threshold})")
    print(f"  Input: {len(col_names)} features")
    
    if len(col_names) == 0:
        print(f'  Output: 0 features kept (no input)')
        return []
    
    # Create DataFrame and clean
    Xdf = pd.DataFrame(X_np, columns=col_names).replace([np.inf, -np.inf], np.nan)
    Xdf = Xdf.fillna(Xdf.median(numeric_only=True))
    
    keep = []
    corr_values = {}
    
    # For each feature, compute max correlation with all quantiles
    for j, cname in enumerate(col_names):
        x = Xdf.iloc[:, j].to_numpy()
        max_abs = 0.0
        
        for k in range(Y_np.shape[1]):
            y = Y_np[:, k]
            r = abs(_safe_spearman(x, y))
            if r > max_abs:
                max_abs = r
        
        corr_values[cname] = max_abs
        
        # Keep if max correlation >= threshold
        if max_abs >= threshold:
            keep.append(cname)
    
    print(f'  Output: {len(keep)} features kept')
    if len(keep) > 0:
        print(f'  Kept: {", ".join(keep[:10])}{"..." if len(keep) > 10 else ""}')
    
    # Show top correlated features even if not kept
    sorted_corr = sorted(corr_values.items(), key=lambda x: x[1], reverse=True)
    print(f'  Top 5 correlations: {", ".join([f"{v}({c:.3f})" for v, c in sorted_corr[:5]])}')
    
    return keep

# -------------------------------------------------------------------------
# Apply Decorrelation Pipeline
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("STEP 1: STATIC VARIABLES - Station-level decorrelation")
print("-"*100)

# Extract static features
X_train_static_cols = np.array([c for c in static_present if c in X_train.columns])
X_train_static_np = X_train[X_train_static_cols.tolist()].to_numpy(dtype=np.float32)
groups_train = X_train['IDr'].to_numpy()

# Apply station-level decorrelation
static_decorrelated = decorrelate_by_spearman_station_level(
    X_train_static_np,
    groups_train,
    X_train_static_cols.tolist(),
    threshold=SPEARMAN_STATION_THRESHOLD
)

print("\n" + "-"*100)
print("STEP 2: STATIC VARIABLES - Response correlation filtering")
print("-"*100)

if len(static_decorrelated) > 0:
    # Extract decorrelated features and response
    static_decor_idx = np.array([i for i, c in enumerate(X_train_static_cols) if c in static_decorrelated])
    X_train_static_decor_np = X_train_static_np[:, static_decor_idx]
    Y_train_np = Y_train[q_cols].to_numpy(dtype=np.float32)
    
    # Apply response-level filtering
    static_final = filter_static_by_response_spearman_obs_level_keep_high(
        X_train_static_decor_np,
        Y_train_np,
        static_decorrelated,
        threshold=SPEARMAN_RESPONSE_THRESHOLD
    )
else:
    static_final = []
    print("  No features passed station-level decorrelation")

# Dynamic variables - use all available
dynamic_final = dynamic_present.copy()

print("\n" + "="*60)
print("FINAL FEATURE SELECTION SUMMARY")
print("="*60)
print(f"Dynamic variables: {len(dynamic_final)}")
for v in dynamic_final:
    print(f"  • {v}")

print(f"\nStatic variables: {len(static_final)}")
for v in sorted(static_final):
    print(f"  • {v}")

print(f"\nTotal features: {len(dynamic_final) + len(static_final)}")

# =========================================================================
# PHASE 4: DATA PREPARATION & LSTM
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: DATA PREPARATION & LSTM TRAINING")
print("="*100)

# Clean data
def clean_numeric_frame(df):
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

print("Preparing and scaling data...")

# Extract final features
X_train_dyn = clean_numeric_frame(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_numeric_frame(X_test[dynamic_final]).astype('float32')

X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32') if len(static_final) > 0 else pd.DataFrame()
X_test_sta = clean_numeric_frame(X_test[static_final]).astype('float32') if len(static_final) > 0 else pd.DataFrame()

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print(f"  Dynamic: {X_train_dyn.shape[1]} features")
print(f"  Static: {X_train_sta.shape[1] if len(static_final) > 0 else 0} features")
print(f"  Targets: {len(q_cols)} quantiles")

# Scale
print("Scaling with QuantileTransformer...")

qt_dyn = QuantileTransformer(n_quantiles=min(2000, X_train_dyn.shape[0]), 
                             output_distribution='normal', 
                             random_state=RANDOM_STATE, 
                             subsample=int(1e9))
qt_y = QuantileTransformer(n_quantiles=min(2000, Y_train_qdf.shape[0]), 
                           output_distribution='normal', 
                           random_state=RANDOM_STATE, 
                           subsample=int(1e9))

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

if len(static_final) > 0:
    qt_sta = QuantileTransformer(n_quantiles=min(2000, X_train_sta.shape[0]), 
                                 output_distribution='normal', 
                                 random_state=RANDOM_STATE, 
                                 subsample=int(1e9))
    X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
    X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')
else:
    X_train_sta_s = np.zeros((X_train_dyn_s.shape[0], 0), dtype=np.float32)
    X_test_sta_s = np.zeros((X_test_dyn_s.shape[0], 0), dtype=np.float32)

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print("✓ Scaling complete")

# Build sequences
print("\nBuilding LSTM sequences...")

def build_sequences(df_meta, X_dyn_scaled, X_sta_scaled, Y_scaled):
    idr = df_meta['IDr'].to_numpy()
    yyyy = df_meta['YYYY'].to_numpy()
    mm = df_meta['MM'].to_numpy()

    sort_idx = np.lexsort((mm, yyyy, idr))
    idr_s = idr[sort_idx]
    Xd = X_dyn_scaled[sort_idx]
    Xs = X_sta_scaled[sort_idx]
    Yt = Y_scaled[sort_idx]

    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []

    _, start_idx = np.unique(idr_s, return_index=True)
    start_idx = np.sort(start_idx)
    end_idx = np.append(start_idx[1:], len(idr_s))

    for s, e in zip(start_idx, end_idx):
        n = e - s
        if n < SEQ_LEN:
            continue
        for j in range(s + SEQ_LEN - 1, e):
            w0 = j - (SEQ_LEN - 1)
            X_seq_dyn.append(Xd[w0:j+1])
            X_seq_sta.append(Xs[j])
            Y_last.append(Yt[j])
            idx_last.append(sort_idx[j])

    if len(X_seq_dyn) == 0:
        return (
            np.zeros((0, SEQ_LEN, X_dyn_scaled.shape[1]), dtype=np.float32),
            np.zeros((0, X_sta_scaled.shape[1]), dtype=np.float32),
            np.zeros((0, Y_scaled.shape[1]), dtype=np.float32),
            np.zeros((0,), dtype=np.int64),
        )

    return (
        np.asarray(X_seq_dyn, dtype=np.float32),
        np.asarray(X_seq_sta, dtype=np.float32),
        np.asarray(Y_last, dtype=np.float32),
        np.asarray(idx_last, dtype=np.int64),
    )

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']].copy()
Xte_meta = X_test[['IDr', 'YYYY', 'MM']].copy()

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s)

print(f"  Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"  Test sequences: {Xte_seq_dyn.shape[0]:,}")

if Xtr_seq_dyn.shape[0] == 0:
    print("ERROR: No training sequences generated. Check SEQ_LEN and data availability.")
    sys.exit(1)

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# LSTM Model
print("\nDefining LSTM model...")

class LSTMWithContext(nn.Module):
    def __init__(self, n_dyn, n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11):
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
            nn.Linear(n_sta, 64),
            nn.ReLU(),
            nn.Dropout(0.1)
        ) if n_sta > 0 else None
        
        fusion_dim = hidden + (64 if n_sta > 0 else 0)
        self.head = nn.Sequential(
            nn.Linear(fusion_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, out_dim)
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
        return self.X_dyn.shape[0]

    def __getitem__(self, idx):
        return self.X_dyn[idx], self.X_sta[idx], self.Y[idx]

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq)
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)
test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=len(q_cols)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

print(f"  Architecture: {n_dyn} dyn + {n_sta} sta → 128 LSTM × 2 → 256 → {len(q_cols)} quantiles")
print(f"  Device: {DEVICE}, Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}")

# Training
def run_epoch(loader, train=True):
    model.train() if train else model.eval()
    losses, ps = [], []

    for x_dyn, x_sta, y in loader:
        x_dyn = x_dyn.to(DEVICE, non_blocking=True).float()
        x_sta = x_sta.to(DEVICE, non_blocking=True).float()
        y = y.to(DEVICE, non_blocking=True).float()

        if train:
            opt.zero_grad(set_to_none=True)

        with torch.set_grad_enabled(train):
            pred = model(x_dyn, x_sta)
            loss = loss_fn(pred, y)
            if train:
                loss.backward()
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                opt.step()

        losses.append(loss.item())
        ps.append(pred.detach().cpu().numpy())

    p_all = np.concatenate(ps, axis=0) if len(ps) else np.zeros((0, len(q_cols)), dtype=np.float32)
    return float(np.mean(losses)) if len(losses) else np.nan, p_all

print("\nTraining...")
best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)
    te_loss, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == EPOCHS:
        print(f'  Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

print(f"✓ Training complete. Best test loss: {best_val:.5f}")

# Predictions
_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed = qt_y.inverse_transform(Pte_s_all).astype('float32')

# Metrics
def kge_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    if np.all(y_true == y_true[0]) or len(y_true) < 2:
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1] if np.std(y_true) > 0 and np.std(y_pred) > 0 else np.nan
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2) if not np.isnan(r) and not np.isnan(beta) and not np.isnan(gamma) else np.nan

def compute_metrics(Y_true_np, Y_pred_np):
    metrics = {}
    for i in range(len(q_cols)):
        try:
            metrics.setdefault('r', []).append(pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0])
            metrics.setdefault('rho', []).append(spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0])
            metrics.setdefault('mae', []).append(mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]))
            metrics.setdefault('rmse', []).append(np.sqrt(mean_squared_error(Y_true_np[:, i], Y_pred_np[:, i])))
            metrics.setdefault('kge', []).append(kge_1d(Y_true_np[:, i], Y_pred_np[:, i]))
            metrics.setdefault('nse', []).append(1 - np.sum((Y_true_np[:, i] - Y_pred_np[:, i])**2) / np.sum((Y_true_np[:, i] - np.mean(Y_true_np[:, i]))**2))
        except:
            metrics.setdefault('r', []).append(np.nan)
            metrics.setdefault('rho', []).append(np.nan)
            metrics.setdefault('mae', []).append(np.nan)
            metrics.setdefault('rmse', []).append(np.nan)
            metrics.setdefault('kge', []).append(np.nan)
            metrics.setdefault('nse', []).append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true_seq, Q_train_reconstructed)
test_metrics = compute_metrics(Yte_true_seq, Q_test_reconstructed)

# Console Output
print(f"\n{'='*100}")
print("FINAL RESULTS")
print(f"{'='*100}")
print(f"\nTRAINING METRICS:")
print(f"  r:     {train_metrics['r'][0]:7.4f}")
print(f"  ρ:     {train_metrics['rho'][0]:7.4f}")
print(f"  NSE:   {train_metrics['nse'][0]:7.4f}")
print(f"  KGE:   {train_metrics['kge'][0]:7.4f}")
print(f"  RMSE:  {train_metrics['rmse'][0]:7.4f}")
print(f"  MAE:   {train_metrics['mae'][0]:7.4f}")

print(f"\nTESTING METRICS:")
print(f"  r:     {test_metrics['r'][0]:7.4f}")
print(f"  ρ:     {test_metrics['rho'][0]:7.4f}")
print(f"  NSE:   {test_metrics['nse'][0]:7.4f}")
print(f"  KGE:   {test_metrics['kge'][0]:7.4f}")
print(f"  RMSE:  {test_metrics['rmse'][0]:7.4f}")
print(f"  MAE:   {test_metrics['mae'][0]:7.4f}")

print(f"\nPER-QUANTILE TEST PERFORMANCE:")
quantile_perf = pd.DataFrame({
    'Quantile': q_cols,
    'r': test_metrics['r'][1],
    'ρ': test_metrics['rho'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1],
    'RMSE': test_metrics['rmse'][1],
    'MAE': test_metrics['mae'][1]
}).round(4)
print(quantile_perf.to_string())

# Save outputs
print(f"\n{'='*100}")
print("SAVING OUTPUTS")
print(f"{'='*100}")

# Save predictions
np.savetxt('../predict_prediction_red/LSTM_QQpredictTrain_spearman_v1.txt',
            Q_train_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')
np.savetxt('../predict_prediction_red/LSTM_QQpredictTest_spearman_v1.txt',
            Q_test_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

# Save features
with open('../predict_importance_red/LSTM_selected_features_spearman_v1.txt', 'w') as f:
    f.write(f'TRAIN_PERIOD: {TRAIN_START_YEAR}-{TRAIN_END_YEAR} ({TRAIN_YEARS} years)\n')
    f.write(f'TEST_PERIOD: {TEST_START_YEAR}-{TEST_END_YEAR} ({TEST_YEARS} years)\n')
    f.write(f'SPEARMAN_STATION_THRESHOLD: {SPEARMAN_STATION_THRESHOLD}\n')
    f.write(f'SPEARMAN_RESPONSE_THRESHOLD: {SPEARMAN_RESPONSE_THRESHOLD}\n')
    f.write('\nDYNAMIC_VARIABLES\n')
    for d in dynamic_final:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

# Save detailed report
with open('../predict_score_red/LSTM_SPEARMAN_REPORT_v1.txt', 'w') as f:
    f.write('='*100 + '\n')
    f.write('LSTM WITH SPEARMAN DECORRELATION PIPELINE REPORT\n')
    f.write(f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
    f.write('='*100 + '\n\n')
    
    f.write('## TEMPORAL SPLIT\n')
    f.write('-'*60 + '\n')
    f.write(f'Train period: {TRAIN_START_YEAR}-{TRAIN_END_YEAR} ({TRAIN_YEARS} years, {TRAIN_YEARS * 12} months)\n')
    f.write(f'Test period:  {TEST_START_YEAR}-{TEST_END_YEAR} ({TEST_YEARS} years, {TEST_YEARS * 12} months)\n')
    f.write(f'Train observations: {X_train.shape[0]:,}\n')
    f.write(f'Test observations:  {X_test.shape[0]:,}\n')
    f.write(f'Train stations: {X_train["IDr"].nunique()}\n')
    f.write(f'Test stations:  {X_test["IDr"].nunique()}\n\n')
    
    f.write('## FEATURE SELECTION\n')
    f.write('-'*60 + '\n')
    f.write(f'Spearman station-level threshold: {SPEARMAN_STATION_THRESHOLD}\n')
    f.write(f'Spearman response-level threshold: {SPEARMAN_RESPONSE_THRESHOLD}\n')
    f.write(f'Dynamic variables: {len(dynamic_final)}\n')
    f.write(f'Static variables: {len(static_final)}\n')
    f.write(f'Total features: {len(dynamic_final) + len(static_final)}\n\n')
    
    f.write('Dynamic variables:\n')
    for d in dynamic_final:
        f.write(f'  • {d}\n')
    f.write('\nStatic variables:\n')
    for s in sorted(static_final):
        f.write(f'  • {s}\n')
    f.write('\n')
    
    f.write('## LSTM MODEL CONFIGURATION\n')
    f.write('-'*60 + '\n')
    f.write(f'Sequence length: {SEQ_LEN}\n')
    f.write(f'Hidden units: 128\n')
    f.write(f'LSTM layers: 2\n')
    f.write(f'Batch size: {BATCH_SIZE}\n')
    f.write(f'Epochs: {EPOCHS}\n')
    f.write(f'Learning rate: {LR}\n')
    f.write(f'Device: {DEVICE}\n\n')
    
    f.write('## RESULTS\n')
    f.write('-'*60 + '\n')
    f.write(f'Training: r={train_metrics["r"][0]:.4f}, NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}\n')
    f.write(f'Testing:  r={test_metrics["r"][0]:.4f}, NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}\n\n')
    
    f.write('Per-Quantile Test Performance:\n')
    f.write(quantile_perf.to_string() + '\n\n')

print(f"✓ Predictions saved")
print(f"✓ Features saved")
print(f"✓ Report saved")

print(f"\n{'='*100}")
print("PIPELINE COMPLETE")
print(f"{'='*100}")
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"{'='*100}\n")

EOFPYTHON
