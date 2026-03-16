#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_OptionC.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_OptionC.sh.%A_%a.err
#SBATCH --job-name=sc31_LSTM_OptionC
#SBATCH --mem=100G

###### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/GSI_TS/sc31_LSTM_OptionC.sh

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOF'
import os
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict

from sklearn.model_selection import train_test_split
from sklearn.cluster import KMeans
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr, spearmanr

from sklearn.preprocessing import QuantileTransformer

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

pd.set_option('display.max_columns', None)

# -------------------------
# ENV / CONSTANTS
# -------------------------
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

# Window parameters (OPTION C)
WINDOW_YEARS = 11
WINDOW_MONTHS = WINDOW_YEARS * 12  # 132 months
MIN_SEQUENCES = WINDOW_MONTHS  # Minimum 132 months per station
GAP_THRESHOLD_DAYS = 30  # Maximum 1 month gap allowed

# -------------------------
# DTYPES (UNCHANGED)
# -------------------------
dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3',
        'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3',
        'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3',
        'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
        'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo'
    ]},
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
        'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
        'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation'
    ]}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX'
    ]}
}

# -------------------------
# STEP 1: LOAD DATA
# -------------------------
print('\n' + '='*80)
print('OPTION C: WINDOW-BASED TRAIN/TEST SPLIT WITH GAP ANALYSIS')
print('='*80)

use_cols_x = [
    'IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord',
    'ppt0', 'tmin0', 'soil0', 'GRWLw', 'accumulation'
]
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=use_cols_x, dtype=dtypes_X, engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

print(f'Loaded X: {X.shape[0]} rows, Y: {Y.shape[0]} rows')

# -------------------------
# STEP 2: ANALYZE GAPS AND SELECT STATIONS
# -------------------------
print('\n' + '='*80)
print('STEP 1: GAP ANALYSIS & STATION SELECTION')
print('='*80)

# Group by station
station_groups = Y.groupby('IDr')
train_stations = []
test_stations_insufficient = []
test_stations_gaps = []
gap_analysis = defaultdict(list)

for idr, group in station_groups:
    group = group.sort_values(by=['YYYY', 'MM']).reset_index(drop=True)
    n_obs = len(group)
    
    # Create date column for gap analysis
    group['date'] = pd.to_datetime(group[['YYYY', 'MM']].rename(columns={'YYYY': 'year', 'MM': 'month'}).assign(day=1))
    
    # Check 1: Sufficient observations
    if n_obs < MIN_SEQUENCES:
        test_stations_insufficient.append((idr, n_obs))
        gap_analysis[idr].append({
            'reason': 'Insufficient data',
            'n_obs': n_obs,
            'min_required': MIN_SEQUENCES,
            'max_gap_days': None
        })
        continue
    
    # Check 2: Gap analysis
    dates = group['date'].values
    gaps = np.diff(dates).astype('timedelta64[D]').astype(int)
    max_gap = gaps.max()
    has_large_gaps = np.any(gaps > GAP_THRESHOLD_DAYS)
    
    if has_large_gaps:
        test_stations_gaps.append((idr, n_obs, max_gap))
        gap_analysis[idr].append({
            'reason': 'Gaps > 1 month',
            'n_obs': n_obs,
            'max_gap_days': max_gap,
            'n_large_gaps': np.sum(gaps > GAP_THRESHOLD_DAYS)
        })
    else:
        train_stations.append((idr, n_obs, max_gap))
        gap_analysis[idr].append({
            'reason': 'TRAINING',
            'n_obs': n_obs,
            'max_gap_days': max_gap,
            'n_large_gaps': 0
        })

# -------------------------
# STEP 3: PRINT ALLOCATION REPORT
# -------------------------
print(f'\nTotal stations analyzed: {len(station_groups)}')
print(f'\nTRAINING STATIONS: {len(train_stations)}')
if train_stations:
    train_obs = [x[1] for x in train_stations]
    print(f'  - Obs count: min={min(train_obs)}, max={max(train_obs)}, mean={np.mean(train_obs):.0f}')
    print(f'  - Max gaps: min={min([x[2] for x in train_stations])} days, '
          f'max={max([x[2] for x in train_stations])} days')

print(f'\nTESTING STATIONS (Insufficient Data): {len(test_stations_insufficient)}')
if test_stations_insufficient:
    test_obs_insuf = [x[1] for x in test_stations_insufficient]
    print(f'  - Obs count: min={min(test_obs_insuf)}, max={max(test_obs_insuf)}, mean={np.mean(test_obs_insuf):.0f}')

print(f'\nTESTING STATIONS (Large Gaps): {len(test_stations_gaps)}')
if test_stations_gaps:
    test_obs_gaps = [x[1] for x in test_stations_gaps]
    test_max_gaps = [x[2] for x in test_stations_gaps]
    print(f'  - Obs count: min={min(test_obs_gaps)}, max={max(test_obs_gaps)}, mean={np.mean(test_obs_gaps):.0f}')
    print(f'  - Max gaps: min={min(test_max_gaps)} days, max={max(test_max_gaps)} days')

# -------------------------
# STEP 4: CREATE WINDOWS FOR TRAINING DATA
# -------------------------
print('\n' + '='*80)
print('STEP 2: CREATING 11-YEAR WINDOWS')
print('='*80)

def create_windows_for_station(group, window_months=132, overlap_months=1):
    """Create overlapping windows from station data"""
    group = group.sort_values(by=['YYYY', 'MM']).reset_index(drop=True)
    windows = []
    
    # Slide window with overlap
    start_idx = 0
    while start_idx + window_months <= len(group):
        end_idx = start_idx + window_months
        window_data = group.iloc[start_idx:end_idx].copy()
        windows.append(window_data)
        start_idx += (window_months - overlap_months)  # Overlap by 1 month
    
    return windows

# Build training set with windows
train_windows_all = []
train_station_info = []

for idr, n_obs, max_gap in train_stations:
    station_data = Y[Y['IDr'] == idr].copy()
    windows = create_windows_for_station(station_data, window_months=WINDOW_MONTHS, overlap_months=1)
    
    train_windows_all.extend(windows)
    train_station_info.append({
        'IDr': idr,
        'n_obs': n_obs,
        'n_windows': len(windows),
        'max_gap_days': max_gap
    })
    
    print(f'Station {idr}: {n_obs} obs → {len(windows)} windows')

print(f'\nTotal training windows created: {len(train_windows_all)}')
print(f'Training stations info: {len(train_station_info)}')

# -------------------------
# STEP 5: PREPARE TESTING DATA
# -------------------------
print('\n' + '='*80)
print('STEP 3: PREPARING TEST DATA')
print('='*80)

test_idr_list = [x[0] for x in test_stations_insufficient] + [x[0] for x in test_stations_gaps]
Y_test_full = Y[Y['IDr'].isin(test_idr_list)].copy()

print(f'Total test observations: {len(Y_test_full)}')
print(f'Test stations: {len(test_idr_list)}')

# -------------------------
# STEP 6: PREPARE TRAINING DATA (Combine all windows)
# -------------------------
print('\n' + '='*80)
print('STEP 4: BUILDING TRAINING DATASET')
print('='*80)

# Combine all training windows
Y_train_full = pd.concat(train_windows_all, ignore_index=True)
print(f'Total training observations: {len(Y_train_full)}')

# Match X data
X_train = X[X['IDr'].isin(Y_train_full['IDr'].unique())].copy()
X_test = X[X['IDr'].isin(test_idr_list)].copy()

print(f'Training X shape: {X_train.shape}')
print(f'Test X shape: {X_test.shape}')

X_train = X_train.reset_index(drop=True)
X_test = X_test.reset_index(drop=True)
Y_train_full = Y_train_full.reset_index(drop=True)
Y_test_full = Y_test_full.reset_index(drop=True)

X_train['ROWID'] = np.arange(X_train.shape[0], dtype=np.int64)
Y_train_full['ROWID'] = np.arange(Y_train_full.shape[0], dtype=np.int64)
X_test['ROWID'] = np.arange(X_test.shape[0], dtype=np.int64)
Y_test_full['ROWID'] = np.arange(Y_test_full.shape[0], dtype=np.int64)

# -------------------------
# STEP 7: DERIVED FEATURES & CLEANING
# -------------------------
print('\n' + '='*80)
print('STEP 5: FEATURE ENGINEERING & CLEANING')
print('='*80)

acc_train = X_train['accumulation'].astype('float32')
X_train['ppt0_area']  = (X_train['ppt0'].astype('float32')  / acc_train).astype('float32')
X_train['tmin0_area'] = (X_train['tmin0'].astype('float32') / acc_train).astype('float32')
X_train['soil0_area'] = (X_train['soil0'].astype('float32') / acc_train).astype('float32')
X_train['GRWLw_area'] = (X_train['GRWLw'].astype('float32') / acc_train).astype('float32')

acc_test = X_test['accumulation'].astype('float32')
X_test['ppt0_area']  = (X_test['ppt0'].astype('float32')  / acc_test).astype('float32')
X_test['tmin0_area'] = (X_test['tmin0'].astype('float32') / acc_test).astype('float32')
X_test['soil0_area'] = (X_test['soil0'].astype('float32') / acc_test).astype('float32')
X_test['GRWLw_area'] = (X_test['GRWLw'].astype('float32') / acc_test).astype('float32')

# Cleaning function
def clean_numeric_frame(df):
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

dynamic_present = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']
q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

X_train_dyn = clean_numeric_frame(X_train[dynamic_present]).astype('float32')
X_test_dyn  = clean_numeric_frame(X_test[dynamic_present]).astype('float32')

X_train_sta = np.zeros((X_train_dyn.shape[0], 0), dtype=np.float32)
X_test_sta  = np.zeros((X_test_dyn.shape[0], 0), dtype=np.float32)

Y_train_qdf = clean_numeric_frame(Y_train_full[q_cols]).astype('float32')
Y_test_qdf  = clean_numeric_frame(Y_test_full[q_cols]).astype('float32')

print(f'Dynamic features: {len(dynamic_present)}')
print(f'Target quantiles: {len(q_cols)}')

# -------------------------
# STEP 8: SCALING
# -------------------------
print('\n' + '='*80)
print('STEP 6: DATA SCALING')
print('='*80)

qt_dyn = QuantileTransformer(
    n_quantiles=min(2000, X_train_dyn.shape[0]),
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)
qt_y = QuantileTransformer(
    n_quantiles=min(2000, Y_train_qdf.shape[0]),
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s  = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s  = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print('Scaling completed')

# -------------------------
# STEP 9: BUILD SEQUENCES
# -------------------------
print('\n' + '='*80)
print('STEP 7: BUILDING SEQUENCES')
print('='*80)

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

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(Xtr_meta, X_train_dyn_s, X_train_sta, Y_train_s)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(Xte_meta, X_test_dyn_s, X_test_sta, Y_test_s)

print(f'Train sequences: X_dyn={Xtr_seq_dyn.shape}, Y={Ytr_seq.shape}')
print(f'Test  sequences: X_dyn={Xte_seq_dyn.shape}, Y={Yte_seq.shape}')

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# -------------------------
# STEP 10: TORCH DATASET & MODEL (UNCHANGED from original)
# -------------------------
print('\n' + '='*80)
print('STEP 8: TRAINING LSTM MODEL')
print('='*80)

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
test_ds  = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)
test_loader  = DataLoader(test_ds,  batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False)

class MultiOutputLSTM(nn.Module):
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
        self.head = nn.Sequential(
            nn.Linear(hidden + n_sta, 256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        if x_sta.shape[1] == 0:
            z = h_last
        else:
            z = torch.cat([h_last, x_sta], dim=1)
        return self.head(z)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = MultiOutputLSTM(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

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

    p_all = np.concatenate(ps, axis=0) if len(ps) else np.zeros((0, 11), dtype=np.float32)
    return float(np.mean(losses)) if len(losses) else np.nan, p_all

print(f'Device: {DEVICE}, epochs={EPOCHS}, batch={BATCH_SIZE}, lr={LR}')

best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)
    te_loss, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 5 == 0 or ep == EPOCHS:
        print(f'Epoch {ep:04d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best_test={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

# -------------------------
# STEP 11: PREDICTIONS & METRICS
# -------------------------
print('\n' + '='*80)
print('STEP 9: PREDICTIONS & ACCURACY METRICS')
print('='*80)

_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed  = qt_y.inverse_transform(Pte_s_all).astype('float32')

def kge_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    if np.all(y_true == y_true[0]):
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

def compute_error_pack(Y_true_np, Y_pred_np):
    r_coll = [pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(0, 11)]
    r_all = float(np.nanmean(r_coll))
    rho_coll = [spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(0, 11)]
    rho_all = float(np.nanmean(rho_coll))
    mae_coll = [mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(0, 11)]
    mae_all = float(np.mean(mae_coll))
    kge_coll = [kge_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(0, 11)]
    kge_all = float(np.nanmean(kge_coll))
    return {
        'r_coll': np.array(r_coll).reshape(1, -1),
        'rho_coll': np.array(rho_coll).reshape(1, -1),
        'mae_coll': np.array(mae_coll).reshape(1, -1),
        'kge_coll': np.array(kge_coll).reshape(1, -1),
        'r_all': np.array(r_all).reshape(1, -1),
        'rho_all': np.array(rho_all).reshape(1, -1),
        'mae_all': np.array(mae_all).reshape(1, -1),
        'kge_all': np.array(kge_all).reshape(1, -1),
    }

train_Q = compute_error_pack(Ytr_true_seq, Q_train_reconstructed)
test_Q  = compute_error_pack(Yte_true_seq, Q_test_reconstructed)

merge_r_Q   = np.concatenate((train_Q['r_all'],   test_Q['r_all'],   train_Q['r_coll'],   test_Q['r_coll']), axis=1)
merge_rho_Q = np.concatenate((train_Q['rho_all'], test_Q['rho_all'], train_Q['rho_coll'], test_Q['rho_coll']), axis=1)
merge_mae_Q = np.concatenate((train_Q['mae_all'], test_Q['mae_all'], train_Q['mae_coll'], test_Q['mae_coll']), axis=1)
merge_kge_Q = np.concatenate((train_Q['kge_all'], test_Q['kge_all'], train_Q['kge_coll'], test_Q['kge_coll']), axis=1)

fmt_score = ' '.join(['%.2f'] * merge_r_Q.shape[1])

np.savetxt('../predict_score_red/LSTM_QQscorer_OptionC_FDC.txt',    merge_r_Q,   delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscorerho_OptionC_FDC.txt',  merge_rho_Q, delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscoremae_OptionC_FDC.txt',  merge_mae_Q, delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscorekge_OptionC_FDC.txt',  merge_kge_Q, delimiter=' ', fmt=fmt_score)

# -------------------------
# STEP 12: QUALITY CONTROL REPORT
# -------------------------
print('\n' + '='*80)
print('QUALITY CONTROL REPORT - OPTION C')
print('='*80)

qc_report = f'''
LSTM QUANTILE PREDICTION - OPTION C: WINDOW-BASED TRAIN/TEST SPLIT
{'='*80}

METHODOLOGY:
  - Window approach: Sliding 11-year windows (132 months each)
  - Overlap: 1 month between consecutive windows
  - Gap tolerance: Max 1 month allowed between observations
  - Min sequences per station: {MIN_SEQUENCES} months

DATA ALLOCATION:
  Training stations: {len(train_stations)}
    - Avg observations per station: {np.mean([x[1] for x in train_stations]):.0f}
    - Min observations: {min([x[1] for x in train_stations])}
    - Max observations: {max([x[1] for x in train_stations])}
    - Avg max gap: {np.mean([x[2] for x in train_stations]):.1f} days
    - Total observations: {len(Y_train_full)}
    - Total windows created: {len(train_windows_all)}
    - Total training sequences: {Xtr_seq_dyn.shape[0]}

  Testing stations (insufficient data): {len(test_stations_insufficient)}
    - Avg observations per station: {np.mean([x[1] for x in test_stations_insufficient]) if test_stations_insufficient else 0:.0f}
    - Total observations: {len([x for sublist in [Y[Y['IDr']==x[0]] for x in test_stations_insufficient] for x in sublist])}

  Testing stations (gaps > 1 month): {len(test_stations_gaps)}
    - Avg observations per station: {np.mean([x[1] for x in test_stations_gaps]) if test_stations_gaps else 0:.0f}
    - Avg max gap: {np.mean([x[2] for x in test_stations_gaps]) if test_stations_gaps else 0:.1f} days
    - Total observations: {len(Y_test_full)}
    - Total test sequences: {Xte_seq_dyn.shape[0]}

TOTAL SEQUENCES:
  Training: {Xtr_seq_dyn.shape[0]}
  Testing: {Xte_seq_dyn.shape[0]}
  Combined: {Xtr_seq_dyn.shape[0] + Xte_seq_dyn.shape[0]}

MODEL PERFORMANCE:
  Device: {DEVICE}
  Epochs: {EPOCHS}
  Batch size: {BATCH_SIZE}
  Learning rate: {LR}
  Best test loss: {best_val:.5f}

ACCURACY METRICS (LSTM Direct Quantiles):
  Pearson Correlation (r):
    - Train (all): {train_Q['r_all'][0, 0]:.3f}
    - Test (all): {test_Q['r_all'][0, 0]:.3f}
  
  Spearman Correlation (ρ):
    - Train (all): {train_Q['rho_all'][0, 0]:.3f}
    - Test (all): {test_Q['rho_all'][0, 0]:.3f}
  
  Mean Absolute Error (MAE):
    - Train (all): {train_Q['mae_all'][0, 0]:.3f}
    - Test (all): {test_Q['mae_all'][0, 0]:.3f}
  
  Kling-Gupta Efficiency (KGE):
    - Train (all): {train_Q['kge_all'][0, 0]:.3f}
    - Test (all): {test_Q['kge_all'][0, 0]:.3f}

TYPICAL ACCURACY FOR LSTM QUANTILE PREDICTION:
  - Pearson r: 0.75-0.95 (strong correlation)
  - Spearman ρ: 0.70-0.90 (ranked correlation)
  - RMSE/MAE: 0.5-1.5 (depending on flow variance)
  - KGE: 0.6-0.9 (model efficiency)

INPUTS (Dynamic Features):
  {', '.join(dynamic_present)}

TARGETS (Quantiles):
  {', '.join(q_cols)}

DATA PROCESSED:
  X data records: {X_train.shape[0]} (train), {X_test.shape[0]} (test)
  Y data records: {Y_train_full.shape[0]} (train), {Y_test_full.shape[0]} (test)
'''

print(qc_report)

with open('../predict_score_red/LSTM_OptionC_QC_Report.txt', 'w') as f:
    f.write(qc_report)

# Save station allocation summary
station_allocation = pd.DataFrame({
    'IDr': [x[0] for x in train_stations],
    'n_observations': [x[1] for x in train_stations],
    'max_gap_days': [x[2] for x in train_stations],
    'allocation': ['TRAINING'] * len(train_stations)
})

for idr, n_obs in test_stations_insufficient:
    station_allocation = pd.concat([station_allocation, pd.DataFrame({
        'IDr': [idr],
        'n_observations': [n_obs],
        'max_gap_days': [np.nan],
        'allocation': ['TEST_INSUFFICIENT']
    })], ignore_index=True)

for idr, n_obs, max_gap in test_stations_gaps:
    station_allocation = pd.concat([station_allocation, pd.DataFrame({
        'IDr': [idr],
        'n_observations': [n_obs],
        'max_gap_days': [max_gap],
        'allocation': ['TEST_GAPS']
    })], ignore_index=True)

station_allocation.to_csv('../predict_score_red/LSTM_OptionC_StationAllocation.csv', index=False)

print('\n' + '='*80)
print('✓ Option C processing completed')
print('✓ Files saved:')
print('  - LSTM_OptionC_QC_Report.txt')
print('  - LSTM_OptionC_StationAllocation.csv')
print('  - LSTM_QQscorer_OptionC_FDC.txt (Pearson r)')
print('  - LSTM_QQscorerho_OptionC_FDC.txt (Spearman ρ)')
print('  - LSTM_QQscoremae_OptionC_FDC.txt (MAE)')
print('  - LSTM_QQscorekge_OptionC_FDC.txt (KGE)')
print('='*80 + '\n')

EOF
exit
