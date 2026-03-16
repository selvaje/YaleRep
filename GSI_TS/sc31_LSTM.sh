#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM.sh.%A_%a.err
#SBATCH --job-name=sc31_LSTM.sh
#SBATCH --array=500
#SBATCH --mem=100G

###### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/GSI_TS/sc31_LSTM.sh

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOF'
import os
import numpy as np
import pandas as pd

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
# INPUT / LOADING
# -------------------------
# Load minimal columns needed for LSTM + split keys
use_cols_x = [
    'IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord',
    'ppt0', 'tmin0', 'soil0', 'GRWLw', 'accumulation'
]
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=use_cols_x, dtype=dtypes_X, engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# -------------------------
# DERIVED FEATURES (ONLY REQUESTED 4)
# -------------------------
acc = X['accumulation'].astype('float32')

X['ppt0_area']  = (X['ppt0'].astype('float32')  / acc).astype('float32')
X['tmin0_area'] = (X['tmin0'].astype('float32') / acc).astype('float32')
X['soil0_area'] = (X['soil0'].astype('float32') / acc).astype('float32')
X['GRWLw_area'] = (X['GRWLw'].astype('float32') / acc).astype('float32')

# -------------------------
# STATION SPLIT (UNCHANGED)
# -------------------------
stations = pd.read_csv(
    '/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
    sep=r'\s+', usecols=['IDr', 'Xcoord', 'Ycoord']
).drop_duplicates()

counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index

unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=RANDOM_STATE).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_

train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=RANDOM_STATE,
    stratify=train_stations['cluster']
)

X_train = X[X['IDr'].isin(train_rasters['IDr'])].copy()
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])].copy()
X_test  = X[X['IDr'].isin(test_rasters['IDr'])].copy()
Y_test  = Y[Y['IDr'].isin(test_rasters['IDr'])].copy()

X_train = X_train.sort_values(by=['ROWID']).reset_index(drop=True)
Y_train = Y_train.sort_values(by=['ROWID']).reset_index(drop=True)
X_test  = X_test.sort_values(by=['ROWID']).reset_index(drop=True)
Y_test  = Y_test.sort_values(by=['ROWID']).reset_index(drop=True)

assert (X_train['ROWID'].to_numpy() == Y_train['ROWID'].to_numpy()).all()
assert (X_test['ROWID'].to_numpy() == Y_test['ROWID'].to_numpy()).all()

# -------------------------
# TARGETS
# -------------------------
q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
dynamic_present = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']

print('')
print('='*80)
print('LSTM DIRECT QUANTILES (NO VARIABLE SELECTION)')
print('='*80)
print(f'Inputs (dynamic): {dynamic_present}')
print(f'SEQ_LEN={SEQ_LEN}, Targets={q_cols}')
print('='*80)

# ---- enforce types ----
for df in (X_train, X_test, Y_train, Y_test):
    df['YYYY'] = df['YYYY'].astype('int32')
    df['MM'] = df['MM'].astype('int32')
    df['IDr'] = df['IDr'].astype('int32')

# -------------------------
# CLEANING
# -------------------------
def clean_numeric_frame(df: pd.DataFrame) -> pd.DataFrame:
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

X_train_dyn = clean_numeric_frame(X_train[dynamic_present]).astype('float32')
X_test_dyn  = clean_numeric_frame(X_test[dynamic_present]).astype('float32')

# No static inputs requested
X_train_sta = np.zeros((X_train_dyn.shape[0], 0), dtype=np.float32)
X_test_sta  = np.zeros((X_test_dyn.shape[0], 0), dtype=np.float32)

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf  = clean_numeric_frame(Y_test[q_cols]).astype('float32')

# -------------------------
# SCALE (fit on train only, apply to both)
# -------------------------
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

# -------------------------
# BUILD SEQUENCES (IDr, YYYY, MM sorted)
# -------------------------
def build_sequences(df_meta: pd.DataFrame, X_dyn_scaled: np.ndarray, X_sta_scaled: np.ndarray, Y_scaled: np.ndarray):
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

print(f'Train sequences: X_dyn={Xtr_seq_dyn.shape}, X_sta={Xtr_seq_sta.shape}, Y={Ytr_seq.shape}')
print(f'Test  sequences: X_dyn={Xte_seq_dyn.shape}, X_sta={Xte_seq_sta.shape}, Y={Yte_seq.shape}')

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# -------------------------
# TORCH DATASET
# -------------------------
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

# -------------------------
# MODEL
# -------------------------
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
n_sta = Xtr_seq_sta.shape[1]  # 0

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

print('')
print('='*80)
print('TRAIN LSTM')
print('='*80)
print(f'Device: {DEVICE}, epochs={EPOCHS}, batch={BATCH_SIZE}, lr={LR}')
print('='*80)

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

print('')
print('='*80)
print('PREDICT + INVERSE-SCALE')
print('='*80)

_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed  = qt_y.inverse_transform(Pte_s_all).astype('float32')

Qtr_valid = Ytr_true_seq.astype('float32')
Qte_valid = Yte_true_seq.astype('float32')

print(f'Train Q pred shape: {Q_train_reconstructed.shape}, true shape: {Qtr_valid.shape}')
print(f'Test  Q pred shape: {Q_test_reconstructed.shape}, true shape: {Qte_valid.shape}')

# -------------------------
# ERROR METRICS
# -------------------------
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

train_Q = compute_error_pack(Qtr_valid, Q_train_reconstructed)
test_Q  = compute_error_pack(Qte_valid, Q_test_reconstructed)

# Keep "matrix format" but without the removed hyperparameter columns:
# [train_all, test_all, train_11, test_11] -> total 1 + 1 + 11 + 11 = 24 columns
merge_r_Q   = np.concatenate((train_Q['r_all'],   test_Q['r_all'],   train_Q['r_coll'],   test_Q['r_coll']), axis=1)
merge_rho_Q = np.concatenate((train_Q['rho_all'], test_Q['rho_all'], train_Q['rho_coll'], test_Q['rho_coll']), axis=1)
merge_mae_Q = np.concatenate((train_Q['mae_all'], test_Q['mae_all'], train_Q['mae_coll'], test_Q['mae_coll']), axis=1)
merge_kge_Q = np.concatenate((train_Q['kge_all'], test_Q['kge_all'], train_Q['kge_coll'], test_Q['kge_coll']), axis=1)

fmt_score = ' '.join(['%.2f'] * merge_r_Q.shape[1])

# Output filenames simplified (no removed variables embedded)
np.savetxt('../predict_score_red/LSTM_QQscorer_FDC.txt',    merge_r_Q,   delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscorerho_FDC.txt',  merge_rho_Q, delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscoremae_FDC.txt',  merge_mae_Q, delimiter=' ', fmt=fmt_score)
np.savetxt('../predict_score_red/LSTM_QQscorekge_FDC.txt',  merge_kge_Q, delimiter=' ', fmt=fmt_score)

# importance output (no selection): zeros for the 4 inputs
importance_s = pd.Series(0.0, index=dynamic_present, dtype='float32')
importance_s.to_csv(
    '../predict_importance_red/LSTM_Ximportance_FDC.txt',
    index=True, sep=' ', header=False
)

fmt_pred = '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f'
np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTrain_FDC.txt',
    Q_train_reconstructed, delimiter=' ', fmt=fmt_pred, header=' '.join(q_cols), comments=''
)
np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTest_FDC.txt',
    Q_test_reconstructed, delimiter=' ', fmt=fmt_pred, header=' '.join(q_cols), comments=''
)

# Keep FDC (a,b,c) placeholder outputs as NaNs
fdc_train_pred = np.full((Q_train_reconstructed.shape[0], 3), np.nan, dtype=np.float32)
fdc_test_pred  = np.full((Q_test_reconstructed.shape[0], 3), np.nan, dtype=np.float32)

fmt_fdc = '%.6f %.6f %.6f'
np.savetxt(
    '../predict_prediction_red/LSTM_QQFDCpredictTrain_FDC.txt',
    fdc_train_pred, delimiter=' ', fmt=fmt_fdc, header='a b c', comments=''
)
np.savetxt(
    '../predict_prediction_red/LSTM_QQFDCpredictTest_FDC.txt',
    fdc_test_pred, delimiter=' ', fmt=fmt_fdc, header='a b c', comments=''
)

qc_report = f'''
LSTM Quantile Prediction Quality Control Report
{'='*80}

MODEL TYPE: LSTM (multi-output) predicting quantiles directly
  - Sequence length: {SEQ_LEN}
  - Targets: {q_cols}
  - Inputs (dynamic only): {dynamic_present}
  - Scaling: QuantileTransformer(output_distribution='normal') fit on TRAIN only, applied to TEST

TRAIN/TEST:
  Train sequences: {Q_train_reconstructed.shape[0]:,}
  Test sequences: {Q_test_reconstructed.shape[0]:,}

TRAINING:
  Device: {DEVICE}
  Epochs: {EPOCHS}
  Batch: {BATCH_SIZE}
  Learning rate: {LR}
'''

with open('../predict_score_red/LSTM_FDC_QC_Report_DirectQ.txt', 'w') as f:
    f.write(qc_report)

print('')
print('='*80)
print('SUMMARY')
print('='*80)
print('✓ Prepared sequences using IDr + (YYYY, MM) sorting')
print('✓ Scaled train and test using QuantileTransformer (fit on train)')
print(f'✓ Trained multi-output PyTorch LSTM with inputs: {dynamic_present}')
print('✓ Computed error metrics and wrote outputs')
print('')
print('End of the script!!!!!!!!!!!!')
EOF
exit
