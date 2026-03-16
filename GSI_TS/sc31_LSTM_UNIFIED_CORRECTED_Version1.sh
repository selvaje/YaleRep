#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_UNIFIED.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_UNIFIED.%A_%a.err
#SBATCH --job-name=sc31_LSTM_UNIFIED
#SBATCH --array=500
#SBATCH --mem=120G

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOFPYTHON'
import os
import sys
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict
from scipy.stats import spearmanr, pearsonr
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, QuantileTransformer
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
print("SC31: UNIFIED LSTM PIPELINE - TIME-SERIES SPLIT + FEATURE SELECTION + TRAINING")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# Time-Series Split Parameters
MIN_TRAIN_MONTHS = 60          # Minimum 5 years for training stations
MAX_GAP_DAYS = 30              # Maximum 30-day gap
MIN_TRAIN_OBS = 500            # Minimum total observations

# Feature Selection Thresholds
RHO_LAG_THRESHOLD = 0.15       # Dynamic temporal relevance
CV_SPATIAL_THRESHOLD = 0.20    # Static spatial variance
RHO_SPATIAL_THRESHOLD = 0.20   # Static spatial correlation
RHO_COLLINEARITY_THRESHOLD = 0.85  # Multicollinearity

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
# REPORTING CLASS
# =========================================================================
class Report:
    def __init__(self, filename):
        self.filename = filename
        self.sections = []
        self.current_section = None
    
    def add_section(self, title, level=1):
        self.current_section = {'title': title, 'level': level, 'content': []}
        self.sections.append(self.current_section)
    
    def add_content(self, content, indent=0):
        if self.current_section is None:
            self.add_section('General')
        prefix = '  ' * indent
        self.current_section['content'].append(f"{prefix}{content}")
    
    def add_dataframe(self, df, max_rows=50):
        if self.current_section is None:
            self.add_section('Data')
        self.current_section['content'].append(df.to_string(max_rows=max_rows))
    
    def save(self):
        with open(self.filename, 'w', encoding='utf-8') as f:
            f.write('='*100 + '\n')
            f.write('UNIFIED LSTM PIPELINE REPORT\n')
            f.write(f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write('='*100 + '\n\n')
            
            for section in self.sections:
                prefix = '#' * section['level']
                f.write(f"{prefix} {section['title']}\n")
                f.write('-' * (len(section['title']) + 2) + '\n\n')
                
                for content in section['content']:
                    f.write(content + '\n')
                f.write('\n')

# =========================================================================
# PHASE 1: LOAD DATA & TEMPORAL CONTIGUITY ANALYSIS
# =========================================================================
print("="*100)
print("PHASE 1: LOAD DATA & TEMPORAL CONTIGUITY ANALYSIS")
print("="*100 + "\n")

# Define available columns (from Xsample_0.005pct.txt)
available_cols_x = [
    'IDs', 'Xsnap', 'Ysnap', 'IDr', 'Xcoord', 'Ycoord', 'YYYY', 'MM',
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'soil0', 'soil1', 'soil2', 'soil3',
    'SNDPPT', 'SLTPPT', 'CLYPPT', 'AWCtS', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
    'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm',
    'accumulation', 'cti', 'spi', 'sti'
]

q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

# Define data types
dtypes_X = {col: 'float32' for col in available_cols_x}
dtypes_X['IDs'] = 'int32'
dtypes_X['IDr'] = 'int32'
dtypes_X['YYYY'] = 'int32'
dtypes_X['MM'] = 'int32'

dtypes_Y = {'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
            'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32'}
dtypes_Y.update({col: 'float32' for col in q_cols})

# Load data
print("Loading data...")
try:
    X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=available_cols_x, 
                    dtype=dtypes_X, engine='c', low_memory=False)
    Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, 
                    engine='c', low_memory=False)
    print(f"✓ Data loaded: X {X.shape}, Y {Y.shape}\n")
except Exception as e:
    print(f"ERROR loading data: {e}")
    sys.exit(1)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# Analyze temporal contiguity
print("Analyzing temporal contiguity for each station...\n")

def analyze_contiguity(group_y):
    idr = group_y['IDr'].iloc[0]
    group = group_y.sort_values(by=['YYYY', 'MM']).reset_index(drop=True)
    group['date'] = pd.to_datetime(group[['YYYY', 'MM']].rename(
        columns={'YYYY': 'year', 'MM': 'month'}).assign(day=1))
    
    n_obs = len(group)
    dates = group['date'].values
    gaps = np.diff(dates).astype('timedelta64[D]').astype(int) if len(dates) > 1 else np.array([])
    
    max_gap = gaps.max() if len(gaps) > 0 else 0
    mean_gap = gaps.mean() if len(gaps) > 0 else 0
    n_large_gaps = np.sum(gaps > MAX_GAP_DAYS) if len(gaps) > 0 else 0
    span_years = (dates[-1] - dates[0]).astype('timedelta64[D]').astype(int) / 365.25 if len(dates) > 1 else 0
    
    return {
        'IDr': idr, 'n_obs': n_obs, 'max_gap_days': max_gap, 
        'mean_gap_days': mean_gap, 'n_large_gaps': n_large_gaps, 'span_years': span_years
    }

contiguity_data = Parallel(n_jobs=NCPU)(
    delayed(analyze_contiguity)(group) for _, group in Y.groupby('IDr')
)
contiguity_df = pd.DataFrame(contiguity_data)

# Classify stations
train_stations_df = contiguity_df[
    (contiguity_df['n_obs'] >= MIN_TRAIN_OBS) & 
    (contiguity_df['max_gap_days'] <= MAX_GAP_DAYS) &
    (contiguity_df['n_obs'] >= MIN_TRAIN_MONTHS)
]

test_stations_df = contiguity_df[
    ~contiguity_df['IDr'].isin(train_stations_df['IDr'])
]

train_idrs = train_stations_df['IDr'].tolist()
test_idrs = test_stations_df['IDr'].tolist()

print(f"TRAINING STATIONS: {len(train_idrs)}")
if len(train_stations_df) > 0:
    print(f"  - Mean observations: {train_stations_df['n_obs'].mean():.0f}")
    print(f"  - Mean max gap: {train_stations_df['max_gap_days'].mean():.1f} days")
    print(f"  - Mean span: {train_stations_df['span_years'].mean():.2f} years\n")

print(f"TESTING STATIONS: {len(test_idrs)}")
if len(test_stations_df) > 0:
    print(f"  - Mean observations: {test_stations_df['n_obs'].mean():.0f}")
    print(f"  - Mean max gap: {test_stations_df['max_gap_days'].mean():.1f} days\n")

# Split data
X_train = X[X['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
X_test = X[X['IDr'].isin(test_idrs)].copy().reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_idrs)].copy().reset_index(drop=True)

print(f"Dataset shapes:")
print(f"  Train X: {X_train.shape}, Train Y: {Y_train.shape}")
print(f"  Test X: {X_test.shape}, Test Y: {Y_test.shape}\n")

# =========================================================================
# PHASE 2: FEATURE SELECTION
# =========================================================================
print("="*100)
print("PHASE 2: FEATURE SELECTION (TRAINING DATA ONLY)")
print("="*100 + "\n")

# Dynamic variables (temporal)
dynamic_var = ['ppt0', 'ppt1', 'ppt2', 'ppt3',
               'tmin0', 'tmin1', 'tmin2', 'tmin3',
               'soil0', 'soil1', 'soil2', 'soil3']

# Static variables (spatial/topographic)
static_var = [col for col in available_cols_x 
              if col not in dynamic_var and col not in ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']]

dynamic_present = [c for c in dynamic_var if c in X_train.columns]
static_present = [c for c in static_var if c in X_train.columns]

print(f"Dynamic variables available: {len(dynamic_present)}")
print(f"Static variables available: {len(static_present)}\n")

# STAGE 1: Dynamic - temporal relevance
print("Stage 1: Temporal relevance of dynamic variables...")

def compute_lag_corr(d_var):
    results = []
    for q_var in q_cols:
        max_rho = -np.inf
        best_lag = -1
        for lag in range(4):
            try:
                d_vals = X_train[d_var].fillna(X_train[d_var].median()).shift(lag).values
                q_vals = Y_train[q_var].fillna(Y_train[q_var].median()).values
                mask = ~(np.isnan(d_vals) | np.isnan(q_vals))
                if np.sum(mask) > 10:
                    rho, _ = spearmanr(d_vals[mask], q_vals[mask])
                    if not np.isnan(rho) and rho > max_rho:
                        max_rho = rho
                        best_lag = lag
            except:
                pass
        if max_rho > -np.inf:
            results.append({'Variable': d_var, 'Quantile': q_var, 'ρ_max': max_rho, 'Best_Lag': best_lag})
    return results

all_results = Parallel(n_jobs=NCPU)(delayed(compute_lag_corr)(d) for d in dynamic_present)
lag_results_list = [item for sublist in all_results for item in sublist]
lag_results_df = pd.DataFrame(lag_results_list)

if len(lag_results_df) > 0:
    dynamic_summary = lag_results_df.groupby('Variable').agg({
        'ρ_max': ['mean', 'min', 'max', 'count'],
        'Best_Lag': lambda x: x.mode()[0] if len(x.mode()) > 0 else -1
    }).round(4)
    dynamic_summary.columns = ['ρ_mean', 'ρ_min', 'ρ_max', 'N_quantiles', 'Mode_Lag']
    dynamic_summary = dynamic_summary.reset_index().sort_values('ρ_mean', ascending=False)
    
    dynamic_keep = dynamic_summary[dynamic_summary['ρ_mean'] >= RHO_LAG_THRESHOLD]['Variable'].tolist()
    print(f"  Keep: {len(dynamic_keep)} variables → {dynamic_keep}\n")
else:
    dynamic_keep = dynamic_present[:4]  # Default to first 4
    print(f"  Keep: {len(dynamic_keep)} variables (default)\n")

# STAGE 2: Static - spatial variance
print("Stage 2: Spatial variance of static variables...")

station_data = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_present].set_index('IDr')
station_data_clean = station_data.fillna(station_data.median())

def compute_cv(var):
    vals = station_data_clean[var].values
    cv = np.std(vals) / (np.abs(np.mean(vals)) + 1e-10)
    return {'Variable': var, 'CV': cv}

cv_results = Parallel(n_jobs=NCPU)(delayed(compute_cv)(var) for var in static_present)
cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

static_2a_keep = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['Variable'].tolist()
print(f"  Keep: {len(static_2a_keep)} variables (CV >= {CV_SPATIAL_THRESHOLD})\n")

# STAGE 3: Multicollinearity
print("Stage 3: Multicollinearity detection...")

candidates_stage3 = static_2a_keep.copy()
pairwise_corr = {}

for i, var1 in enumerate(candidates_stage3):
    for j, var2 in enumerate(candidates_stage3):
        if i < j:
            try:
                v1 = station_data_clean[var1].values
                v2 = station_data_clean[var2].values
                mask = ~(np.isnan(v1) | np.isnan(v2))
                if np.sum(mask) > 5:
                    rho, _ = spearmanr(v1[mask], v2[mask])
                    if not np.isnan(rho) and abs(rho) > RHO_COLLINEARITY_THRESHOLD:
                        pairwise_corr[(var1, var2)] = rho
            except:
                pass

static_final = candidates_stage3.copy()
removed_vars = set()

cv_dict = dict(zip(cv_df['Variable'], cv_df['CV']))
for (var1, var2), rho in sorted(pairwise_corr.items(), key=lambda x: abs(x[1]), reverse=True):
    if var1 not in removed_vars and var2 not in removed_vars:
        cv1 = cv_dict.get(var1, 0)
        cv2 = cv_dict.get(var2, 0)
        if cv1 > cv2:
            removed_vars.add(var2)
        else:
            removed_vars.add(var1)

static_final = [v for v in candidates_stage3 if v not in removed_vars]

print(f"  Removed: {len(removed_vars)} variables")
print(f"  Final: {len(static_final)} static variables\n")

print(f"FEATURE SELECTION SUMMARY:")
print(f"  Dynamic inputs: {len(dynamic_keep)} → {dynamic_keep}")
print(f"  Static inputs: {len(static_final)}\n")

# =========================================================================
# PHASE 3: DATA PREPARATION & SCALING
# =========================================================================
print("="*100)
print("PHASE 3: DATA PREPARATION & SCALING")
print("="*100 + "\n")

# Add derived features
acc_train = X_train['accumulation'].astype('float32')
X_train['ppt0_area'] = (X_train['ppt0'].astype('float32') / (acc_train + 1e-6)).astype('float32')
X_train['tmin0_area'] = (X_train['tmin0'].astype('float32') / (acc_train + 1e-6)).astype('float32')
X_train['soil0_area'] = (X_train['soil0'].astype('float32') / (acc_train + 1e-6)).astype('float32')
X_train['GRWLw_area'] = (X_train['GRWLw'].astype('float32') / (acc_train + 1e-6)).astype('float32')

acc_test = X_test['accumulation'].astype('float32')
X_test['ppt0_area'] = (X_test['ppt0'].astype('float32') / (acc_test + 1e-6)).astype('float32')
X_test['tmin0_area'] = (X_test['tmin0'].astype('float32') / (acc_test + 1e-6)).astype('float32')
X_test['soil0_area'] = (X_test['soil0'].astype('float32') / (acc_test + 1e-6)).astype('float32')
X_test['GRWLw_area'] = (X_test['GRWLw'].astype('float32') / (acc_test + 1e-6)).astype('float32')

# Update dynamic_keep with derived features if needed
if 'ppt0_area' not in dynamic_keep:
    dynamic_keep_final = dynamic_keep + ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']
else:
    dynamic_keep_final = dynamic_keep

def clean_numeric(df):
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

X_train_dyn = clean_numeric(X_train[dynamic_keep_final]).astype('float32')
X_test_dyn = clean_numeric(X_test[dynamic_keep_final]).astype('float32')

X_train_sta = clean_numeric(X_train[static_final]).astype('float32')
X_test_sta = clean_numeric(X_test[static_final]).astype('float32')

Y_train_qdf = clean_numeric(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric(Y_test[q_cols]).astype('float32')

print(f"Feature matrices prepared:")
print(f"  X_train_dyn: {X_train_dyn.shape}")
print(f"  X_train_sta: {X_train_sta.shape}")
print(f"  Y_train: {Y_train_qdf.shape}\n")

# Scale data
print("Applying QuantileTransformer...")
qt_dyn = QuantileTransformer(n_quantiles=min(2000, X_train_dyn.shape[0]),
                             output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_sta = QuantileTransformer(n_quantiles=min(2000, X_train_sta.shape[0]),
                             output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_y = QuantileTransformer(n_quantiles=min(2000, Y_train_qdf.shape[0]),
                           output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print("✓ Data scaled\n")

# =========================================================================
# PHASE 4: BUILD SEQUENCES & LSTM
# =========================================================================
print("="*100)
print("PHASE 4: BUILD SEQUENCES & LSTM TRAINING")
print("="*100 + "\n")

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
        return (np.zeros((0, SEQ_LEN, X_dyn_scaled.shape[1]), dtype=np.float32),
                np.zeros((0, X_sta_scaled.shape[1]), dtype=np.float32),
                np.zeros((0, Y_scaled.shape[1]), dtype=np.float32),
                np.zeros((0,), dtype=np.int64))

    return (np.asarray(X_seq_dyn, dtype=np.float32),
            np.asarray(X_seq_sta, dtype=np.float32),
            np.asarray(Y_last, dtype=np.float32),
            np.asarray(idx_last, dtype=np.int64))

X_train['ROWID'] = np.arange(X_train.shape[0], dtype=np.int64)
X_test['ROWID'] = np.arange(X_test.shape[0], dtype=np.int64)
Y_train['ROWID'] = np.arange(Y_train.shape[0], dtype=np.int64)
Y_test['ROWID'] = np.arange(Y_test.shape[0], dtype=np.int64)

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']].copy()
Xte_meta = X_test[['IDr', 'YYYY', 'MM']].copy()

print("Building sequences...")
Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s)

print(f"Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"Test sequences: {Xte_seq_dyn.shape[0]:,}\n")

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# LSTM Model
class LSTMWithContext(nn.Module):
    def __init__(self, n_dyn, n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11):
        super().__init__()
        self.lstm = nn.LSTM(input_size=n_dyn, hidden_size=hidden, num_layers=num_layers,
                           batch_first=True, dropout=dropout if num_layers > 1 else 0.0)
        self.static_encoder = nn.Sequential(
            nn.Linear(n_sta, 64), nn.ReLU(), nn.Dropout(0.1)
        ) if n_sta > 0 else None
        
        fusion_dim = hidden + (64 if n_sta > 0 else 0)
        self.head = nn.Sequential(
            nn.Linear(fusion_dim, 256), nn.ReLU(), nn.Dropout(0.2),
            nn.Linear(256, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        if self.static_encoder is not None:
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

model = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

print(f"Model Configuration:")
print(f"  LSTM input (dynamic): {n_dyn}")
print(f"  Static context: {n_sta}")
print(f"  LSTM: 2×128 hidden")
print(f"  Device: {DEVICE}")
print(f"  Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}\n")

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

print("Training LSTM...\n")
best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)
    te_loss, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == EPOCHS:
        print(f'Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

print(f"\n✓ Training complete. Best test loss: {best_val:.5f}\n")

# =========================================================================
# PHASE 5: PREDICTIONS & METRICS
# =========================================================================
print("="*100)
print("PHASE 5: PREDICTIONS & ACCURACY METRICS")
print("="*100 + "\n")

_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed = qt_y.inverse_transform(Pte_s_all).astype('float32')

def kge_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    if np.all(y_true == y_true[0]):
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

def compute_metrics(Y_true_np, Y_pred_np):
    r_vals = [pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    rho_vals = [spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    mae_vals = [mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    rmse_vals = [np.sqrt(mean_squared_error(Y_true_np[:, i], Y_pred_np[:, i])) for i in range(11)]
    kge_vals = [kge_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    nse_vals = [1 - (np.sum((Y_true_np[:, i] - Y_pred_np[:, i])**2) / 
                     np.sum((Y_true_np[:, i] - np.mean(Y_true_np[:, i]))**2)) for i in range(11)]
    
    return {
        'r': (np.nanmean(r_vals), r_vals),
        'rho': (np.nanmean(rho_vals), rho_vals),
        'mae': (np.mean(mae_vals), mae_vals),
        'rmse': (np.mean(rmse_vals), rmse_vals),
        'kge': (np.nanmean(kge_vals), kge_vals),
        'nse': (np.nanmean(nse_vals), nse_vals)
    }

train_metrics = compute_metrics(Ytr_true_seq, Q_train_reconstructed)
test_metrics = compute_metrics(Yte_true_seq, Q_test_reconstructed)

print("TRAINING METRICS:")
print("-" * 60)
for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
    val, _ = train_metrics[metric]
    print(f"  {metric.upper():8s}: {val:7.4f}")

print("\nTESTING METRICS:")
print("-" * 60)
for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
    val, _ = test_metrics[metric]
    print(f"  {metric.upper():8s}: {val:7.4f}")

print("\nPER-QUANTILE PERFORMANCE (TEST SET):")
print("-" * 60)
quantile_perf = pd.DataFrame({
    'Quantile': q_cols,
    'Pearson_r': test_metrics['r'][1],
    'Spearman_ρ': test_metrics['rho'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1],
    'MAE': test_metrics['mae'][1],
    'RMSE': test_metrics['rmse'][1]
}).round(4)
print(quantile_perf.to_string(index=False))

print("\n" + "="*100)
print("TYPICAL LSTM ACCURACY BENCHMARKS:")
print("="*100)
print("  Pearson r:  0.75-0.95 (excellent correlation)")
print("  Spearman ρ: 0.70-0.90 (ranked correlation)")
print("  NSE:        0.6-0.9 (model efficiency)")
print("  KGE:        0.6-0.9 (complex skill)")
print("  MAE:        0.5-1.5 (depends on flow magnitude)")
print("="*100 + "\n")

# Save outputs
print("Saving outputs...")
np.savetxt('../predict_prediction_red/LSTM_QQpredictTrain_unified.txt',
            Q_train_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')
np.savetxt('../predict_prediction_red/LSTM_QQpredictTest_unified.txt',
            Q_test_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

with open('../predict_importance_red/LSTM_selected_features_unified.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_keep_final:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

print("✓ Predictions saved")
print("✓ Feature list saved\n")

print("="*100)
print("UNIFIED LSTM PIPELINE COMPLETE")
print("="*100)
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

EOFPYTHON
exit
