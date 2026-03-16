#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_UNIFIED_MONTHLY.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_UNIFIED_MONTHLY.%A_%a.err
#SBATCH --job-name=sc31_LSTM_UNIFIED_MONTHLY
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
from datetime import datetime
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

print("\n" + "="*100)
print("UNIFIED LSTM PIPELINE - MONTHLY TIME-SERIES SPLIT")
print("="*100)
print(f"Start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

# ==========================================================================
# CONFIGURATION
# ==========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

MIN_TRAIN_MONTHS = 132  # 11 years
ALLOW_MONTH_GAP = 1     # Allow up to 3-month gaps (e.g., seasonal)

RHO_LAG_THRESHOLD = 0.15
CV_SPATIAL_THRESHOLD = 0.20
RHO_SPATIAL_THRESHOLD = 0.20
RHO_COLLINEARITY_THRESHOLD = 0.85

SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

DATA_X = 'stationID_x_y_valueALL_predictors_X1_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y1_floredSFD.txt'

# Available columns from Xsample_0.005pct.txt
static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
    'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm',
    'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc'
]

dynamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

# ==========================================================================
# PHASE 1: LOAD DATA & MONTHLY CONTIGUITY ANALYSIS
# ==========================================================================
print("PHASE 1: LOAD DATA & MONTHLY CONTIGUITY ANALYSIS")
print("=" * 100)

# Define dtypes
dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in dynamic_var},
    **{col: 'int32' for col in ['AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
                                 'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
                                 'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo']},
    **{col: 'float32' for col in [c for c in static_var if c not in 
                                   ['AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
                                    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
                                    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo']]}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in q_cols}
}

use_cols_x = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord',
              'ppt0', 'tmin0', 'soil0', 'GRWLw', 'accumulation'] + static_var + dynamic_var

print(f"\nLoading X from {DATA_X}...")
try:
    X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=use_cols_x, dtype=dtypes_X, engine='c', low_memory=False)
except ValueError as e:
    print(f"ERROR: {e}")
    print(f"\nAttempting with only available columns...")
    X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
    print(f"Available columns: {list(X.columns)}")
    sys.exit(1)

print(f"Loading Y from {DATA_Y}...")
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
print(f"✓ Loaded: X {X.shape}, Y {Y.shape}\n")

# Analyze monthly contiguity for each station
def analyze_monthly_contiguity(group_y):
    idr = group_y['IDr'].iloc[0]
    group = group_y.sort_values(by=['YYYY', 'MM']).reset_index(drop=True)
    
    n_obs = len(group)
    
    # Calculate month-to-month differences
    yyyy_diff = group['YYYY'].diff().fillna(0).values[1:]
    mm_diff = group['MM'].diff().values[1:]
    
    # Expected next month: YYYY same, MM+1, unless MM=12 then YYYY+1, MM=1
    expected_mm_diff = np.where(group['MM'].values[:-1] == 12, -11, 1)
    expected_yyyy_diff = np.where(group['MM'].values[:-1] == 12, 1, 0)
    
    month_gaps = []
    for i in range(len(yyyy_diff)):
        if yyyy_diff[i] == expected_yyyy_diff[i] and mm_diff[i] == expected_mm_diff[i]:
            month_gaps.append(0)  # Contiguous
        else:
            # Calculate gap in months
            actual_months = yyyy_diff[i] * 12 + mm_diff[i]
            expected_months = expected_yyyy_diff[i] * 12 + expected_mm_diff[i]
            gap = actual_months - expected_months
            month_gaps.append(gap)
    
    max_gap_months = max(month_gaps) if month_gaps else 0
    n_large_gaps = sum(1 for g in month_gaps if g > ALLOW_MONTH_GAP)
    
    return {
        'IDr': idr,
        'n_obs': n_obs,
        'max_gap_months': max_gap_months,
        'n_large_gaps': n_large_gaps,
        'is_contiguous': n_large_gaps == 0
    }

print("Analyzing monthly contiguity for each station...")
contiguity_data = Parallel(n_jobs=NCPU)(
    delayed(analyze_monthly_contiguity)(group) for _, group in Y.groupby('IDr')
)
contiguity_df = pd.DataFrame(contiguity_data)

# Classify stations
train_mask = (contiguity_df['n_obs'] >= MIN_TRAIN_MONTHS) & (contiguity_df['n_large_gaps'] == 0)
train_stations_df = contiguity_df[train_mask].copy()
test_stations_df = contiguity_df[~train_mask].copy()

train_idrs = train_stations_df['IDr'].tolist()
test_idrs = test_stations_df['IDr'].tolist()

print(f"\n{'='*60}")
print("TIME-SERIES SPLIT RESULTS (MONTHLY BASIS)")
print(f"{'='*60}")
print(f"\nTRAINING STATIONS: {len(train_idrs)}")
if len(train_stations_df) > 0:
    print(f"  Months: min={train_stations_df['n_obs'].min()}, max={train_stations_df['n_obs'].max()}, mean={train_stations_df['n_obs'].mean():.0f}")
    print(f"  Max gap: mean={train_stations_df['max_gap_months'].mean():.1f} months")

print(f"\nTESTING STATIONS: {len(test_idrs)}")
if len(test_stations_df) > 0:
    insufficient = len(test_stations_df[test_stations_df['n_obs'] < MIN_TRAIN_MONTHS])
    has_gaps = len(test_stations_df[test_stations_df['n_large_gaps'] > 0])
    print(f"  Insufficient data (< {MIN_TRAIN_MONTHS}mo): {insufficient}")
    print(f"  Large gaps (> {ALLOW_MONTH_GAP}mo): {has_gaps}")
    print(f"  Months: mean={test_stations_df['n_obs'].mean():.0f}")

# Split data
X_train = X[X['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
X_test = X[X['IDr'].isin(test_idrs)].copy().reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_idrs)].copy().reset_index(drop=True)

print(f"\nDataset: Train X {X_train.shape}, Train Y {Y_train.shape}")
print(f"         Test X {X_test.shape}, Test Y {Y_test.shape}")

# Save Phase 1 report
with open('../predict_score_red/01_TIMESERIES_SPLIT_REPORT.txt', 'w') as f:
    f.write("="*100 + "\n")
    f.write("TIME-SERIES SPLIT REPORT (MONTHLY BASIS)\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("="*100 + "\n\n")
    f.write(f"Configuration:\n")
    f.write(f"  Min training months: {MIN_TRAIN_MONTHS} (11 years)\n")
    f.write(f"  Allow month gaps: ≤ {ALLOW_MONTH_GAP} months\n\n")
    f.write(f"Results:\n")
    f.write(f"  Training stations: {len(train_idrs)}\n")
    f.write(f"  Testing stations: {len(test_idrs)}\n")
    f.write(f"  Training observations: {len(Y_train)}\n")
    f.write(f"  Testing observations: {len(Y_test)}\n\n")
    f.write(contiguity_df.to_string())

print("\n✓ Phase 1 complete. Report saved: 01_TIMESERIES_SPLIT_REPORT.txt")

# ==========================================================================
# PHASE 2: FEATURE SELECTION (ON TRAINING DATA ONLY)
# ==========================================================================
print("\n" + "="*100)
print("PHASE 2: FEATURE SELECTION (TRAINING DATA)")
print("="*100)

# Add derived features
acc_train = X_train['accumulation'].astype('float32')
X_train['ppt0_area'] = (X_train['ppt0'].astype('float32') / (acc_train + 1e-8)).astype('float32')
X_train['tmin0_area'] = (X_train['tmin0'].astype('float32') / (acc_train + 1e-8)).astype('float32')
X_train['soil0_area'] = (X_train['soil0'].astype('float32') / (acc_train + 1e-8)).astype('float32')
X_train['GRWLw_area'] = (X_train['GRWLw'].astype('float32') / (acc_train + 1e-8)).astype('float32')

acc_test = X_test['accumulation'].astype('float32')
X_test['ppt0_area'] = (X_test['ppt0'].astype('float32') / (acc_test + 1e-8)).astype('float32')
X_test['tmin0_area'] = (X_test['tmin0'].astype('float32') / (acc_test + 1e-8)).astype('float32')
X_test['soil0_area'] = (X_test['soil0'].astype('float32') / (acc_test + 1e-8)).astype('float32')
X_test['GRWLw_area'] = (X_test['GRWLw'].astype('float32') / (acc_test + 1e-8)).astype('float32')

print(f"\nStage 1: Dynamic variables - temporal relevance (lag 0-3)...")

dynamic_present = [c for c in dynamic_var if c in X_train.columns]

def compute_lag_corr(d_var):
    results = []
    for q_var in q_cols:
        max_rho = -2.0
        best_lag = -1
        for lag in range(4):
            try:
                if lag == 0:
                    d_vals = X_train[d_var].fillna(X_train[d_var].median()).values
                else:
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
        if max_rho > -2.0:
            results.append({'Variable': d_var, 'ρ_max': max_rho, 'Best_Lag': best_lag})
    return results

all_results = Parallel(n_jobs=NCPU)(delayed(compute_lag_corr)(d) for d in dynamic_present)
lag_results_list = [item for sublist in all_results for item in sublist]

if lag_results_list:
    lag_results_df = pd.DataFrame(lag_results_list)
    dynamic_summary = lag_results_df.groupby('Variable')['ρ_max'].mean().sort_values(ascending=False)
    dynamic_keep = dynamic_summary[dynamic_summary >= RHO_LAG_THRESHOLD].index.tolist()
else:
    dynamic_keep = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']

print(f"\n✓ Dynamic variables selected: {len(dynamic_keep)}")
for d in dynamic_keep:
    print(f"    {d}")

print(f"\nStage 2: Static variables - spatial variance & correlation...")

static_present = [c for c in static_var if c in X_train.columns]
station_data = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_present].set_index('IDr')
station_data_clean = station_data.fillna(station_data.median())

cv_results = []
for var in static_present:
    vals = station_data_clean[var].values
    cv = np.std(vals) / (np.abs(np.mean(vals)) + 1e-10)
    cv_results.append({'Variable': var, 'CV': cv})
cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

static_2a_keep = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['Variable'].tolist()

# Spatial correlation with Q
station_static = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_2a_keep].set_index('IDr')
station_static_clean = station_static.fillna(station_static.median())
station_q_stats = Y_train.groupby([['IDr']][['QMIN', 'Q50', 'QMAX']].mean()

spatial_results = []
for var in static_2a_keep:
    s_vals = station_static_clean[var].values
    for q_var in ['QMIN', 'Q50', 'QMAX']:
        q_vals = station_q_stats[q_var].values
        mask = ~(np.isnan(s_vals) | np.isnan(q_vals))
        if np.sum(mask) > 5:
            try:
                rho, _ = spearmanr(s_vals[mask], q_vals[mask])
                if not np.isnan(rho):
                    spatial_results.append({'Variable': var, 'Quantile': q_var, '|ρ|': abs(rho)})
            except:
                pass

if spatial_results:
    spatial_corr_df = pd.DataFrame(spatial_results)
    spatial_pivot = spatial_corr_df.pivot_table(index='Variable', columns='Quantile', values='|ρ|', aggfunc='max')
    spatial_pivot['Max_ρ'] = spatial_pivot.max(axis=1)
    static_2b_keep = spatial_pivot[spatial_pivot['Max_ρ'] >= RHO_SPATIAL_THRESHOLD].index.tolist()
else:
    static_2b_keep = static_2a_keep

print(f"\n✓ Static variables after CV & correlation filters: {len(static_2b_keep)}")

# Multicollinearity
print(f"\nStage 3: Multicollinearity check...")

candidates_stage3 = static_2b_keep.copy()
pairwise_corr = {}

for i, var1 in enumerate(candidates_stage3):
    for j, var2 in enumerate(candidates_stage3):
        if i < j:
            try:
                v1 = station_static_clean[var1].values
                v2 = station_static_clean[var2].values
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

print(f"✓ Removed {len(removed_vars)} collinear variables")
print(f"✓ Final static variables: {len(static_final)}")
for s in sorted(static_final)[:15]:
    print(f"    {s}")
if len(static_final) > 15:
    print(f"    ... ({len(static_final)-15} more)")

# Save Phase 2 report
with open('../predict_score_red/02_FEATURE_SELECTION_REPORT.txt', 'w') as f:
    f.write("="*100 + "\n")
    f.write("FEATURE SELECTION REPORT\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("="*100 + "\n\n")
    f.write(f"DYNAMIC VARIABLES: {len(dynamic_keep)} selected\n")
    for d in dynamic_keep:
        f.write(f"  {d}\n")
    f.write(f"\nSTATIC VARIABLES: {len(static_final)} selected\n")
    for s in sorted(static_final):
        f.write(f"  {s}\n")

print("\n✓ Phase 2 complete. Report saved: 02_FEATURE_SELECTION_REPORT.txt")

# ==========================================================================
# PHASE 3: DATA PREPARATION & LSTM TRAINING
# ==========================================================================
print("\n" + "="*100)
print("PHASE 3: DATA PREPARATION & LSTM TRAINING")
print("="*100)

def clean_numeric_frame(df):
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

print(f"\nPreparing features...")

X_train_dyn = clean_numeric_frame(X_train[dynamic_keep]).astype('float32')
X_test_dyn = clean_numeric_frame(X_test[dynamic_keep]).astype('float32')

X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32')
X_test_sta = clean_numeric_frame(X_test[static_final]).astype('float32')

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print(f"Dynamic features: {X_train_dyn.shape[1]}")
print(f"Static features: {X_train_sta.shape[1]}")

print(f"\nScaling data...")

qt_dyn = QuantileTransformer(n_quantiles=min(2000, X_train_dyn.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_sta = QuantileTransformer(n_quantiles=min(2000, X_train_sta.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_y = QuantileTransformer(n_quantiles=min(2000, Y_train_qdf.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')
X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')
Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print(f"✓ Data scaled")

print(f"\nBuilding sequences (SEQ_LEN={SEQ_LEN})...")

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

X_train['ROWID'] = np.arange(X_train.shape[0], dtype=np.int64)
X_test['ROWID'] = np.arange(X_test.shape[0], dtype=np.int64)
Y_train['ROWID'] = np.arange(Y_train.shape[0], dtype=np.int64)
Y_test['ROWID'] = np.arange(Y_test.shape[0], dtype=np.int64)

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(
    X_train[['IDr', 'YYYY', 'MM']], X_train_dyn_s, X_train_sta_s, Y_train_s
)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(
    X_test[['IDr', 'YYYY', 'MM']], X_test_dyn_s, X_test_sta_s, Y_test_s
)

print(f"✓ Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"✓ Test sequences: {Xte_seq_dyn.shape[0]:,}")

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# LSTM Model
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

print(f"\nLSTM Model:")
print(f"  Dynamic inputs: {n_dyn}")
print(f"  Static inputs: {n_sta}")
print(f"  LSTM: 128 hidden × 2 layers")
print(f"  Device: {DEVICE}")
print(f"  Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}")

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

print(f"\nTraining...")
best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)
    te_loss, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep % 10 == 0 or ep == EPOCHS:
        print(f'  Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

print(f"✓ Training complete")

# ==========================================================================
# PHASE 4: PREDICTIONS & METRICS
# ==========================================================================
print("\n" + "="*100)
print("PHASE 4: PREDICTIONS & ACCURACY METRICS")
print("="*100)

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
    beta = np.mean(y_pred) / (np.mean(y_true) + 1e-10)
    gamma = np.std(y_pred) / (np.std(y_true) + 1e-10)
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

def compute_metrics(Y_true_np, Y_pred_np):
    r_vals = [pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    rho_vals = [spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    mae_vals = [mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    rmse_vals = [np.sqrt(mean_squared_error(Y_true_np[:, i], Y_pred_np[:, i])) for i in range(11)]
    kge_vals = [kge_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    nse_vals = [1 - (np.sum((Y_true_np[:, i] - Y_pred_np[:, i])**2) / (np.sum((Y_true_np[:, i] - np.mean(Y_true_np[:, i]))**2) + 1e-10)) for i in range(11)]
    
    return {
        'r': (np.nanmean(r_vals), r_vals),
        'rho': (np.nanmean(rho_vals), rho_vals),
        'mae': (np.mean(mae_vals), mae_vals),
        'rmse': (np.mean(rmse_vals), rmse_vals),
        'kge': (np.nanmean(kge_vals), kge_vals),
        'nse': (np.nanmean(nse_vals), nse_vals),
    }

train_metrics = compute_metrics(Ytr_true_seq, Q_train_reconstructed)
test_metrics = compute_metrics(Yte_true_seq, Q_test_reconstructed)

print(f"\n{'='*60}")
print("TRAINING SET METRICS")
print(f"{'='*60}")
for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
    val, _ = train_metrics[metric]
    print(f"  {metric.upper():8s}: {val:8.4f}")

print(f"\n{'='*60}")
print("TESTING SET METRICS")
print(f"{'='*60}")
for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
    val, _ = test_metrics[metric]
    print(f"  {metric.upper():8s}: {val:8.4f}")

print(f"\n{'='*60}")
print("PER-QUANTILE PERFORMANCE (TEST SET)")
print(f"{'='*60}")
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

# Save Phase 4 report
with open('../predict_score_red/03_LSTM_TRAINING_REPORT.txt', 'w') as f:
    f.write("="*100 + "\n")
    f.write("LSTM TRAINING & EVALUATION REPORT\n")
    f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("="*100 + "\n\n")
    f.write("CONFIGURATION:\n")
    f.write(f"  Sequence length: {SEQ_LEN} months\n")
    f.write(f"  Dynamic features: {n_dyn}\n")
    f.write(f"  Static features: {n_sta}\n")
    f.write(f"  LSTM: 128 hidden × 2 layers\n")
    f.write(f"  Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}\n\n")
    f.write("DATASET:\n")
    f.write(f"  Train sequences: {Xtr_seq_dyn.shape[0]:,}\n")
    f.write(f"  Test sequences: {Xte_seq_dyn.shape[0]:,}\n\n")
    f.write("OVERALL METRICS:\n")
    f.write("TRAINING:\n")
    for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
        val, _ = train_metrics[metric]
        f.write(f"  {metric.upper()}: {val:.4f}\n")
    f.write("\nTESTING:\n")
    for metric in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']:
        val, _ = test_metrics[metric]
        f.write(f"  {metric.upper()}: {val:.4f}\n")
    f.write("\nPER-QUANTILE (TEST):\n")
    f.write(quantile_perf.to_string())

# Save predictions
np.savetxt('../predict_prediction_red/LSTM_QQpredictTrain_monthly.txt', Q_train_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')
np.savetxt('../predict_prediction_red/LSTM_QQpredictTest_monthly.txt', Q_test_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

# Save selected features
with open('../predict_importance_red/LSTM_selected_features_monthly.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_keep:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

print("\n" + "="*100)
print("UNIFIED LSTM PIPELINE COMPLETE")
print("="*100)
print(f"End: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("="*100 + "\n")

EOFPYTHON
exit
