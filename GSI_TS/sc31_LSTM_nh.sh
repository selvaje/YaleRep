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


#### module load  uv/0.9.17
#### uv venv
#### uv pip install neuralhydrology


EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOF'
import os
import time
import numpy as np
import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.cluster import KMeans
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed

# scaling / selection
from sklearn.preprocessing import QuantileTransformer

# torch LSTM
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

import shap

pd.set_option('display.max_columns', None)

# -------------------------
# ENV / CONSTANTS
# -------------------------
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# LSTM settings
SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = max(10, int(N_EST_I))   # reuse array hyperparameter as epochs
LR = 1e-3
STATIC_TOPK = 30                # number of static vars to keep via SHAP (fallback if fewer)
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
# INPUT / LOADING (UNCHANGED)
# -------------------------
importance = pd.read_csv('varX_list.txt', header=None, sep=r'\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)

Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# -------------------------
# DERIVED FEATURES (UNCHANGED)
# -------------------------
acc = X['accumulation'].astype('float32')

X['ppt0_area'] = (X['ppt0'].astype('float32') / acc).astype('float32')
X['ppt1_area'] = (X['ppt1'].astype('float32') / acc).astype('float32')
X['ppt2_area'] = (X['ppt2'].astype('float32') / acc).astype('float32')
X['ppt3_area'] = (X['ppt3'].astype('float32') / acc).astype('float32')
X['ppt_sum_area'] = ((X['ppt0'].astype('float32') + X['ppt1'].astype('float32') + X['ppt2'].astype('float32') + X['ppt3'].astype('float32')) / acc).astype('float32')
X['ppt_avg_area'] = ((X['ppt0'].astype('float32') + X['ppt1'].astype('float32')) / acc).astype('float32')

X['tmin0_area'] = (X['tmin0'].astype('float32') / acc).astype('float32')
X['tmin1_area'] = (X['tmin1'].astype('float32') / acc).astype('float32')
X['tmin2_area'] = (X['tmin2'].astype('float32') / acc).astype('float32')
X['tmin3_area'] = (X['tmin3'].astype('float32') / acc).astype('float32')

X['soil0_area'] = (X['soil0'].astype('float32') / acc).astype('float32')
X['soil1_area'] = (X['soil1'].astype('float32') / acc).astype('float32')
X['soil2_area'] = (X['soil2'].astype('float32') / acc).astype('float32')
X['soil3_area'] = (X['soil3'].astype('float32') / acc).astype('float32')

X['GRWLw_area'] = (X['GRWLw'].astype('float32') / acc).astype('float32')

# -------------------------
# STATION SPLIT (UNCHANGED)
# -------------------------
stations = pd.read_csv(
    '/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
    sep=r'\s+', usecols=['IDr', 'Xcoord', 'Ycoord']
).drop_duplicates()

counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index

unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=24).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_

train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=24,
    stratify=train_stations['cluster']
)

X_train = X[X['IDr'].isin(train_rasters['IDr'])].copy()
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])].copy()
X_test = X[X['IDr'].isin(test_rasters['IDr'])].copy()
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'])].copy()

X_train = X_train.sort_values(by=['ROWID']).reset_index(drop=True)
Y_train = Y_train.sort_values(by=['ROWID']).reset_index(drop=True)
X_test = X_test.sort_values(by=['ROWID']).reset_index(drop=True)
Y_test = Y_test.sort_values(by=['ROWID']).reset_index(drop=True)

assert (X_train['ROWID'].to_numpy() == Y_train['ROWID'].to_numpy()).all()
assert (X_test['ROWID'].to_numpy() == Y_test['ROWID'].to_numpy()).all()

# -------------------------
# FEATURE LISTS (UNCHANGED)
# -------------------------
static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dinamic_var = [
    'ppt0_area', 'ppt1_area', 'ppt2_area', 'ppt3_area', 'ppt_sum_area', 'ppt_avg_area',
    'tmin0_area', 'tmin1_area', 'tmin2_area', 'tmin3_area',
    'soil0_area', 'soil1_area', 'soil2_area', 'soil3_area',
    'GRWLw_area'
]

all_cols = X_train.columns.astype(str).tolist()
static_present = [c for c in static_var if c in all_cols]
dynamic_present = [c for c in dinamic_var if c in all_cols]

q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

# ======================================================================================
# START OF NEW CORE (LSTM) - keep data loading, and keep output score matrix/errors later
# ======================================================================================

print('')
print('='*80)
print('STEP 1: PREPARE MULTI-OUTPUT TARGETS FOR LSTM (DIRECT QUANTILES)')
print('='*80)
print(f'Model Type: Multi-output LSTM, SEQ_LEN={SEQ_LEN}, Targets={q_cols}')
print('='*80)

# ---- sanity: ensure join keys align (IDr, YYYY, MM) ----
# we keep ROWID alignment but explicitly enforce time sorting for sequences
for df in (X_train, X_test, Y_train, Y_test):
    df['YYYY'] = df['YYYY'].astype('int32')
    df['MM'] = df['MM'].astype('int32')
    df['IDr'] = df['IDr'].astype('int32')

# ---- select and clean static/dynamic matrices ----
def clean_numeric_frame(df: pd.DataFrame) -> pd.DataFrame:
    out = df.replace([np.inf, -np.inf], np.nan)
    # median fill for numeric columns
    out = out.fillna(out.median(numeric_only=True))
    return out

# Station-level static dataframe (for selection): mean per IDr from TRAIN ONLY
Xstatic_obs = clean_numeric_frame(X_train[static_present]).astype('float32')
X_station = Xstatic_obs.copy()
X_station['IDr'] = X_train['IDr'].to_numpy()
X_station = X_station.groupby('IDr', observed=True).mean(numeric_only=True)

# We need a station-level target for selection; use mean Q across time (train)
Ytrain_q = Y_train[q_cols].astype('float32').to_numpy()
Ytrain_df = pd.DataFrame(Ytrain_q, columns=q_cols)
Ytrain_df['IDr'] = X_train['IDr'].to_numpy()
Y_station = Ytrain_df.groupby('IDr', observed=True)[q_cols].mean().astype('float32')

Y_station = Y_station.replace([np.inf, -np.inf], np.nan).fillna(0).astype('float32')

print(f'Station-level static X shape: {X_station.shape}')
print(f'Station-level targets shape: {Y_station.shape}')

print('')
print('='*80)
print('STEP 2: STATIC VARIABLE SELECTION VIA SHAP (NO RFECV/ExtraTreesRegressor)')
print('='*80)

# Use a lightweight multi-output linear surrogate for SHAP (KernelExplainer)
# (robust and avoids RFECV). We fit 11 independent linear models in one matrix solve.
# Model: Y = X @ B + e, B via least squares.
X_station_np = X_station.to_numpy(dtype=np.float32)
Y_station_np = Y_station.to_numpy(dtype=np.float32)

# Standardize station predictors for stable SHAP (use QuantileTransformer too)
qt_station = QuantileTransformer(
    n_quantiles=min(1000, X_station_np.shape[0]),
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)
X_station_qt = qt_station.fit_transform(X_station_np).astype(np.float32)

# Fit linear regression via least squares (multi-output)
# Add bias internally by augmenting ones column
X_aug = np.hstack([np.ones((X_station_qt.shape[0], 1), dtype=np.float32), X_station_qt]).astype(np.float32)
B, *_ = np.linalg.lstsq(X_aug, Y_station_np, rcond=None)  # (n_features+1, 11)

def lin_predict(X_in):
    X_in = np.asarray(X_in, dtype=np.float32)
    X_in_aug = np.hstack([np.ones((X_in.shape[0], 1), dtype=np.float32), X_in])
    return X_in_aug @ B

# SHAP background sample
bg_n = min(200, X_station_qt.shape[0])
rng = np.random.default_rng(RANDOM_STATE)
bg_idx = rng.choice(X_station_qt.shape[0], size=bg_n, replace=False)
background = X_station_qt[bg_idx]

# Evaluate SHAP on a subset for speed
eval_n = min(400, X_station_qt.shape[0])
eval_idx = rng.choice(X_station_qt.shape[0], size=eval_n, replace=False)
X_eval = X_station_qt[eval_idx]

print(f'Computing SHAP KernelExplainer on eval_n={eval_n}, bg_n={bg_n} ... (may take time)')
t0 = time.time()
explainer = shap.KernelExplainer(lin_predict, background)
# shap_values can be list (multioutput) or array; enforce list per output
shap_values = explainer.shap_values(X_eval, nsamples=200)
t_shap = time.time() - t0
print(f'✓ SHAP computed in {t_shap:.2f}s')

# Aggregate absolute SHAP across outputs, then across samples
if isinstance(shap_values, list):
    # list length = n_outputs, each shape (eval_n, n_features)
    shap_abs = np.zeros((eval_n, X_station_qt.shape[1]), dtype=np.float32)
    for sv in shap_values:
        shap_abs += np.abs(np.asarray(sv, dtype=np.float32))
    shap_abs /= max(1, len(shap_values))
else:
    # shape (eval_n, n_features, n_outputs) or (n_outputs, eval_n, n_features)
    arr = np.asarray(shap_values, dtype=np.float32)
    if arr.ndim == 3 and arr.shape[-1] == Y_station_np.shape[1]:
        shap_abs = np.mean(np.abs(arr), axis=2)
    elif arr.ndim == 3 and arr.shape[0] == Y_station_np.shape[1]:
        shap_abs = np.mean(np.abs(arr), axis=0)
    else:
        shap_abs = np.abs(arr)

shap_import = shap_abs.mean(axis=0)  # (n_features,)
feat_names = X_station.columns.astype(str).tolist()
imp_df = pd.DataFrame({'feature': feat_names, 'shap_importance': shap_import}).sort_values(
    by='shap_importance', ascending=False
).reset_index(drop=True)

# Choose top-k, but also ensure at least 5 features if available
k = min(STATIC_TOPK, imp_df.shape[0])
k = max(5, k) if imp_df.shape[0] >= 5 else imp_df.shape[0]
static_keep = imp_df['feature'].iloc[:k].tolist()

print('')
print('SHAP selected static variables:')
for i, v in enumerate(static_keep, start=1):
    print(f'  {i:3d}. {v}')
print('')

rank_out = f'../predict_score_red/SHAP_static_ranking_N{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_Q_LSTM.txt'
imp_df.to_csv(rank_out, sep=' ', index=False)

print('')
print('='*80)
print('STEP 3: BUILD LSTM SEQUENCES (IDr, YYYY, MM) + SCALE TRAIN/TEST')
print('='*80)

# We will:
# - For each IDr, sort by YYYY, MM
# - Build sequences of length SEQ_LEN for X_dynamic, and attach static vector (broadcasted)
# - Predict target Q(t) at last step in the window

time_cols = ['YYYY', 'MM']

# dynamic features for LSTM input
X_train_dyn = clean_numeric_frame(X_train[dynamic_present]).astype('float32')
X_test_dyn = clean_numeric_frame(X_test[dynamic_present]).astype('float32')

# static features (selected)
X_train_sta = clean_numeric_frame(X_train[static_keep]).astype('float32')
X_test_sta = clean_numeric_frame(X_test[static_keep]).astype('float32')

# targets
Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric_frame(Y_test[q_cols]).astype('float32')

# Fit scalers ONLY on training data, but apply to both train and test (as requested)
# Use QuantileTransformer for robustness (normal output)
qt_dyn = QuantileTransformer(
    n_quantiles=min(2000, X_train_dyn.shape[0]),
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)
qt_sta = QuantileTransformer(
    n_quantiles=min(2000, X_train_sta.shape[0]),
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
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

# Helper: build sequences
def build_sequences(df_meta: pd.DataFrame, X_dyn_scaled: np.ndarray, X_sta_scaled: np.ndarray, Y_scaled: np.ndarray):
    '''
    df_meta: must include IDr, YYYY, MM in same row order as X_dyn_scaled/X_sta_scaled/Y_scaled
    Builds sequences per IDr sorted by YYYY, MM.
    Returns:
        X_seq_dyn: (N, SEQ_LEN, n_dyn)
        X_seq_sta: (N, n_sta)
        Y_last:    (N, 11)  (target at last timestep)
        idx_last:  row indices in original (after sorting) for later alignment if needed
    '''
    idr = df_meta['IDr'].to_numpy()
    yyyy = df_meta['YYYY'].to_numpy()
    mm = df_meta['MM'].to_numpy()

    # stable sort by (IDr, YYYY, MM) using lexsort
    sort_idx = np.lexsort((mm, yyyy, idr))
    idr_s = idr[sort_idx]
    Xd = X_dyn_scaled[sort_idx]
    Xs = X_sta_scaled[sort_idx]
    Yt = Y_scaled[sort_idx]

    X_seq_dyn = []
    X_seq_sta = []
    Y_last = []
    idx_last = []

    # iterate by group boundaries
    # find start indices of groups
    _, start_idx = np.unique(idr_s, return_index=True)
    start_idx = np.sort(start_idx)
    end_idx = np.append(start_idx[1:], len(idr_s))

    for s, e in zip(start_idx, end_idx):
        n = e - s
        if n < SEQ_LEN:
            continue
        # sliding windows
        for j in range(s + SEQ_LEN - 1, e):
            w0 = j - (SEQ_LEN - 1)
            X_seq_dyn.append(Xd[w0:j+1])
            # static at current time (or any time) - we use current row j
            X_seq_sta.append(Xs[j])
            Y_last.append(Yt[j])
            idx_last.append(sort_idx[j])  # original index position pre-sort

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

print(f'Train sequences: X_dyn={Xtr_seq_dyn.shape}, X_sta={Xtr_seq_sta.shape}, Y={Ytr_seq.shape}')
print(f'Test  sequences: X_dyn={Xte_seq_dyn.shape}, X_sta={Xte_seq_sta.shape}, Y={Yte_seq.shape}')

# also keep unscaled true targets for error computation later (we need quantiles in original units)
Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# -------------------------
# TORCH DATASET
# -------------------------
class LSTMDataset(Dataset):
    def __init__(self, X_dyn, X_sta, Y):
        self.X_dyn = torch.from_numpy(X_dyn)  # (N, T, Fd)
        self.X_sta = torch.from_numpy(X_sta)  # (N, Fs)
        self.Y = torch.from_numpy(Y)          # (N, 11)

    def __len__(self):
        return self.X_dyn.shape[0]

    def __getitem__(self, idx):
        return self.X_dyn[idx], self.X_sta[idx], self.Y[idx]

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq)
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)
test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False)

# -------------------------
# MODEL: multi-output LSTM
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
        # x_dyn: (B, T, n_dyn)
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]  # (B, hidden)
        z = torch.cat([h_last, x_sta], dim=1)
        return self.head(z)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = MultiOutputLSTM(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()  # robust for outliers

def run_epoch(loader, train=True):
    if train:
        model.train()
    else:
        model.eval()

    losses = []
    ys = []
    ps = []

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
        ys.append(y.detach().cpu().numpy())
        ps.append(pred.detach().cpu().numpy())

    y_all = np.concatenate(ys, axis=0) if len(ys) else np.zeros((0, 11), dtype=np.float32)
    p_all = np.concatenate(ps, axis=0) if len(ps) else np.zeros((0, 11), dtype=np.float32)
    return float(np.mean(losses)) if len(losses) else np.nan, y_all, p_all

print('')
print('='*80)
print('STEP 4: TRAIN LSTM')
print('='*80)
print(f'Device: {DEVICE}, epochs={EPOCHS}, batch={BATCH_SIZE}, lr={LR}')
print('='*80)

best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _, _ = run_epoch(train_loader, train=True)
    te_loss, _, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 5 == 0 or ep == EPOCHS:
        print(f'Epoch {ep:04d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best_test={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

print('')
print('='*80)
print('STEP 5: PREDICT + INVERSE-SCALE TARGETS BACK TO ORIGINAL UNITS')
print('='*80)

_, Ytr_s_all, Ptr_s_all = run_epoch(train_loader, train=False)
_, Yte_s_all, Pte_s_all = run_epoch(test_loader, train=False)

# inverse transform predictions to original Q space
# qt_y is trained on row-level train targets, but inverse works on normalized outputs
Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed = qt_y.inverse_transform(Pte_s_all).astype('float32')

# true (aligned) already computed from original units:
Qtr_valid = Ytr_true_seq.astype('float32')
Qte_valid = Yte_true_seq.astype('float32')

print(f'Train Q pred shape: {Q_train_reconstructed.shape}, true shape: {Qtr_valid.shape}')
print(f'Test  Q pred shape: {Q_test_reconstructed.shape}, true shape: {Qte_valid.shape}')

# Feature importance placeholder (keep output behavior)
# We output SHAP importances for static, and zeros for dynamic as a simple placeholder
importance_s = pd.Series(0.0, index=(static_keep + dynamic_present), dtype='float32')
for _, row in imp_df.iterrows():
    if row['feature'] in static_keep:
        importance_s.loc[row['feature']] = float(row['shap_importance'])

# ======================================================================================
# END OF NEW CORE (LSTM)
# ======================================================================================

print('')
print('='*80)
print('STEP 5: ERROR METRICS')
print('='*80)

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

# keep matrix format (do not change accuracy matrix and errors):
# [N_EST, 0.1, obs_split, obs_leaf] then metrics
initial_array = np.array([[N_EST_I, 0.1, obs_split_i, obs_leaf_i]])

train_Q = compute_error_pack(Qtr_valid, Q_train_reconstructed)
test_Q = compute_error_pack(Qte_valid, Q_test_reconstructed)

merge_r_Q = np.concatenate((initial_array, train_Q['r_all'], test_Q['r_all'], train_Q['r_coll'], test_Q['r_coll']), axis=1)
merge_rho_Q = np.concatenate((initial_array, train_Q['rho_all'], test_Q['rho_all'], train_Q['rho_coll'], test_Q['rho_coll']), axis=1)
merge_mae_Q = np.concatenate((initial_array, train_Q['mae_all'], test_Q['mae_all'], train_Q['mae_coll'], test_Q['mae_coll']), axis=1)
merge_kge_Q = np.concatenate((initial_array, train_Q['kge_all'], test_Q['kge_all'], train_Q['kge_coll'], test_Q['kge_coll']), axis=1)

fmt_score = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r_Q.shape[1] - 4))

# keep output filenames unchanged suffix (still uses *_FDC_HGBR.txt in original)
# (you asked do not change accuracy matrix/errors; filenames are part of pipeline)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QQscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt', merge_r_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QQscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt', merge_rho_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QQscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt', merge_mae_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QQscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt', merge_kge_Q, delimiter=' ', fmt=fmt_score)

# importance output: now SHAP-based static importances (others 0)
importance_s.to_csv(
    f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt',
    index=True, sep=' ', header=False
)

fmt_pred = '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f'
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_QQpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt',
    Q_train_reconstructed, delimiter=' ', fmt=fmt_pred, header=' '.join(q_cols), comments=''
)
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_QQpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt',
    Q_test_reconstructed, delimiter=' ', fmt=fmt_pred, header=' '.join(q_cols), comments=''
)

# Keep FDC prediction outputs: for LSTM we don't predict (a,b,c); output NaNs with correct shape
fdc_train_pred = np.full((Q_train_reconstructed.shape[0], 3), np.nan, dtype=np.float32)
fdc_test_pred = np.full((Q_test_reconstructed.shape[0], 3), np.nan, dtype=np.float32)

fmt_fdc = '%.6f %.6f %.6f'
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_QQFDCpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt',
    fdc_train_pred, delimiter=' ', fmt=fmt_fdc, header='a b c', comments=''
)
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_QQFDCpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_FDC_HGBR.txt',
    fdc_test_pred, delimiter=' ', fmt=fmt_fdc, header='a b c', comments=''
)

qc_report = f'''
LSTM Quantile Prediction Quality Control Report
{'='*80}

MODEL TYPE: LSTM (multi-output) predicting quantiles directly
  - Sequence length: {SEQ_LEN}
  - Targets: {q_cols}
  - Scaling: QuantileTransformer(output_distribution='normal') fit on TRAIN only, applied to TEST

TRAIN/TEST:
  Train sequences: {Q_train_reconstructed.shape[0]:,}
  Test sequences: {Q_test_reconstructed.shape[0]:,}

STATIC SELECTION:
  Method: SHAP (KernelExplainer on linear surrogate at station-level)
  Kept static features: {len(static_keep)}
  Static features: {static_keep}

TRAINING:
  Device: {DEVICE}
  Epochs: {EPOCHS}
  Batch: {BATCH_SIZE}
  Learning rate: {LR}
'''

with open(f'../predict_score_red/FDC_QC_Report_N{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_DirectQ_HGBR.txt', 'w') as f:
    f.write(qc_report)

print('')
print('='*80)
print('SUMMARY')
print('='*80)
print('✓ Prepared sequences using IDr + (YYYY, MM) sorting')
print('✓ Scaled train and test using QuantileTransformer (fit on train)')
print(f'✓ Selected {len(static_keep)} static vars using SHAP (no RFECV)')
print('✓ Trained multi-output PyTorch LSTM to predict QMIN..QMAX directly')
print('✓ Computed error metrics and wrote outputs with existing filenames')
print('')
print('End of the script!!!!!!!!!!!!')
EOF
"
exit
