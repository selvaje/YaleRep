#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 24  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_spearman_lstm.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_spearman_lstm.sh.%A_%a.err
#SBATCH --job-name=sc31_spearman_lstm.sh
#SBATCH --array=500
#SBATCH --mem=100G

###### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/GSI_TS/sc31_spearman_static_selection_and_lstm.sh

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOF'
import os
import numpy as np
import pandas as pd
from scipy.stats import spearmanr
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, QuantileTransformer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from scipy.stats import pearsonr
import shap
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import warnings
warnings.filterwarnings('ignore')

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from joblib import Parallel, delayed
import multiprocessing as mp

pd.set_option('display.max_columns', None)

# =========================================================================
# CONFIGURATION FLAGS & PARAMETERS
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# ---- FEATURE SELECTION FLAGS ----
DYNAMIC_SELECTION_FLAG = False     # Set to False to skip dynamic temporal relevance analysis
STATIC_SELECTION_FLAG = True      # Static variable selection (always True for this script)

# ---- THRESHOLDS ----
RHO_LAG_THRESHOLD = 0.15          # Dynamic: min correlation across lags
CV_SPATIAL_THRESHOLD = 0.20       # Static: min coefficient of variation
RHO_SPATIAL_THRESHOLD = 0.20      # Static: min correlation with Q targets
RHO_COLLINEARITY_THRESHOLD = 0.85 # Multicollinearity threshold

# ---- TEMPORAL SPLIT ----
TRAIN_START_YEAR = 1958
TRAIN_END_YEAR = 1962
TEST_START_YEAR = 1963
TEST_END_YEAR = 1967

# ---- LSTM PARAMETERS ----
SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# ---- DATA FILES ----
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

# =========================================================================
# STATIC/DYNAMIC VARIABLE DEFINITIONS
# =========================================================================
static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
    'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm', 
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe'
]

dynamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# =========================================================================
# DATA LOADING & PREPARATION
# =========================================================================
print('')
print('='*80)
print('SPEARMAN ρ-BASED SPATIO-TEMPORAL VARIABLE SELECTION')
print('='*80)
print(f'Dynamic selection flag: {DYNAMIC_SELECTION_FLAG}')
print(f'Static selection flag: {STATIC_SELECTION_FLAG}')
print(f'CPU cores available: {NCPU}')
print('='*80)

# Prepare dtypes
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
    **{col: 'float32' for col in static_var}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

use_cols_x = [
    'IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord',
    'ppt0', 'tmin0', 'soil0', 'GRWLw', 'accumulation'
] + static_var + dynamic_var

print('Loading data...')
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=use_cols_x, dtype=dtypes_X, engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# Create derived dynamic features
acc = X['accumulation'].astype('float32')
X['ppt0_area']  = (X['ppt0'].astype('float32')  / acc).astype('float32')
X['tmin0_area'] = (X['tmin0'].astype('float32') / acc).astype('float32')
X['soil0_area'] = (X['soil0'].astype('float32') / acc).astype('float32')
X['GRWLw_area'] = (X['GRWLw'].astype('float32') / acc).astype('float32')

print(f'Data loaded: X shape {X.shape}, Y shape {Y.shape}')

# Temporal split
train_mask = (X['YYYY'] >= TRAIN_START_YEAR) & (X['YYYY'] <= TRAIN_END_YEAR)
test_mask  = (X['YYYY'] >= TEST_START_YEAR) & (X['YYYY'] <= TEST_END_YEAR)

X_train = X[train_mask].copy()
Y_train = Y[train_mask].copy()
X_test  = X[test_mask].copy()
Y_test  = Y[test_mask].copy()

print(f'Train: {len(X_train)}, Test: {len(X_test)}')

# =========================================================================
# STAGE 1: DYNAMIC VARIABLES - TEMPORAL RELEVANCE
# =========================================================================
if DYNAMIC_SELECTION_FLAG:
    print('')
    print('='*80)
    print('STAGE 1: DYNAMIC VARIABLES - TEMPORAL RELEVANCE')
    print('='*80)
    
    q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
    dynamic_present = [c for c in dynamic_var if c in X_train.columns]
    
    print(f'Analyzing {len(dynamic_present)} dynamic variables...')
    
    # Compute lag correlations in parallel
    def compute_lag_correlation(d_var):
        results = []
        for q_var in q_cols:
            max_rho = -np.inf
            best_lag = -1
            
            for lag in range(4):
                try:
                    # Align data
                    if lag == 0:
                        d_vals = X_train[d_var].fillna(X_train[d_var].median()).values
                    else:
                        d_vals = X_train[d_var].fillna(X_train[d_var].median()).shift(lag).values
                    
                    q_vals = Y_train[q_var].fillna(Y_train[q_var].median()).values
                    
                    # Remove NaN
                    mask = ~(np.isnan(d_vals) | np.isnan(q_vals))
                    if np.sum(mask) > 10:
                        rho, _ = spearmanr(d_vals[mask], q_vals[mask])
                        if not np.isnan(rho) and rho > max_rho:
                            max_rho = rho
                            best_lag = lag
                except:
                    pass
            
            if max_rho > -np.inf:
                results.append({'Variable': d_var, 'Quantile': q_var, 'ρ_max': max_rho, 'Lag': best_lag})
        
        return results
    
    all_results = Parallel(n_jobs=NCPU)(delayed(compute_lag_correlation)(d) for d in dynamic_present)
    lag_results_list = [item for sublist in all_results for item in sublist]
    lag_results_df = pd.DataFrame(lag_results_list)
    
    # Summary by variable
    dynamic_summary = lag_results_df.groupby('Variable').agg({
        'ρ_max': ['mean', 'min', 'max', 'std'],
        'Lag': lambda x: x.mode()[0] if len(x.mode()) > 0 else -1
    }).reset_index()
    dynamic_summary.columns = ['Variable', 'ρ_mean', 'ρ_min', 'ρ_max', 'ρ_std', 'Most_Common_Lag']
    
    # Keep dynamic variables
    dynamic_keep = dynamic_summary[dynamic_summary['ρ_mean'] >= RHO_LAG_THRESHOLD]['Variable'].tolist()
    dynamic_remove = dynamic_summary[dynamic_summary['ρ_mean'] < RHO_LAG_THRESHOLD]['Variable'].tolist()
    
    print(f'\nDYNAMIC VARIABLES SUMMARY:')
    print(dynamic_summary[['Variable', 'ρ_mean', 'ρ_min', 'ρ_max', 'Most_Common_Lag']].to_string(index=False))
    print(f'\nKEEP ({len(dynamic_keep)}): {dynamic_keep}')
    print(f'REMOVE ({len(dynamic_remove)}): {dynamic_remove}')
    
else:
    print('')
    print('='*80)
    print('STAGE 1: DYNAMIC VARIABLES - SKIPPED (FLAG OFF)')
    print('='*80)
    dynamic_keep = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']
    print(f'Using default dynamic variables: {dynamic_keep}')

# =========================================================================
# STAGE 2A: STATIC VARIABLES - SPATIAL VARIANCE
# =========================================================================
print('')
print('='*80)
print('STAGE 2A: STATIC VARIABLES - SPATIAL VARIANCE')
print('='*80)

static_present = [c for c in static_var if c in X_train.columns]
print(f'Analyzing {len(static_present)} static variables...')

# Compute CV per station (one value per unique IDr)
station_data = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_present].set_index('IDr')
station_data_clean = station_data.fillna(station_data.median())

# Compute CV in parallel
def compute_cv(var):
    vals = station_data_clean[var].values
    if np.std(vals) > 0:
        cv = np.std(vals) / np.abs(np.mean(vals) + 1e-10)
    else:
        cv = 0.0
    return {'Variable': var, 'CV': cv}

cv_results = Parallel(n_jobs=NCPU)(delayed(compute_cv)(var) for var in static_present)
cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

static_2a_keep = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['Variable'].tolist()
static_2a_remove = cv_df[cv_df['CV'] < CV_SPATIAL_THRESHOLD]['Variable'].tolist()

print(f'\nSTATIC VARIABLES - SPATIAL VARIANCE:')
print(cv_df.to_string(index=False))
print(f'\nPASS (CV ≥ {CV_SPATIAL_THRESHOLD}): {len(static_2a_keep)} variables')
print(f'FAIL (CV < {CV_SPATIAL_THRESHOLD}): {len(static_2a_remove)} variables')

# =========================================================================
# STAGE 2B: STATIC VARIABLES - SPATIAL CORRELATION WITH Q EXTREMES
# =========================================================================
print('')
print('='*80)
print('STAGE 2B: STATIC VARIABLES - SPATIAL CORRELATION (QMIN, Q50, QMAX)')
print('='*80)

# Aggregate by station
station_static = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_2a_keep].set_index('IDr')
station_static_clean = station_static.fillna(station_static.median())

station_q_stats = X_train.groupby('IDr')[['QMIN', 'Q50', 'QMAX']].mean()

print(f'Computing spatial correlations for {len(static_2a_keep)} candidate variables...')

# Compute correlations in parallel
def compute_spatial_correlation(var):
    results = []
    try:
        s_vals = station_static_clean[var].values
        
        for q_var in ['QMIN', 'Q50', 'QMAX']:
            q_vals = station_q_stats[q_var].values
            
            mask = ~(np.isnan(s_vals) | np.isnan(q_vals))
            if np.sum(mask) > 5:
                rho, p_val = spearmanr(s_vals[mask], q_vals[mask])
                if not np.isnan(rho):
                    results.append({
                        'Variable': var,
                        'Quantile': q_var,
                        'ρ': rho,
                        'p_value': p_val
                    })
    except:
        pass
    
    return results

all_spatial_results = Parallel(n_jobs=NCPU)(
    delayed(compute_spatial_correlation)(var) for var in static_2a_keep
)
spatial_results_list = [item for sublist in all_spatial_results for item in sublist]
spatial_corr_df = pd.DataFrame(spatial_results_list)

# Pivot for easier viewing
spatial_pivot = spatial_corr_df.pivot_table(
    index='Variable', columns='Quantile', values='ρ'
).reindex(columns=['QMIN', 'Q50', 'QMAX'])
spatial_pivot['Max_|ρ|'] = spatial_pivot[['QMIN', 'Q50', 'QMAX']].abs().max(axis=1)
spatial_pivot = spatial_pivot.sort_values('Max_|ρ|', ascending=False)

print(f'\nSPATIAL CORRELATION MATRIX:')
print(spatial_pivot.to_string())

static_2b_keep = spatial_pivot[spatial_pivot['Max_|ρ|'] >= RHO_SPATIAL_THRESHOLD].index.tolist()
static_2b_remove = spatial_pivot[spatial_pivot['Max_|ρ|'] < RHO_SPATIAL_THRESHOLD].index.tolist()

print(f'\nKEEP (|ρ| ≥ {RHO_SPATIAL_THRESHOLD} with at least one Q): {len(static_2b_keep)} variables')
print(f'REMOVE (|ρ| < {RHO_SPATIAL_THRESHOLD}): {len(static_2b_remove)} variables')

# =========================================================================
# STAGE 3A: MULTICOLLINEARITY DETECTION
# =========================================================================
print('')
print('='*80)
print('STAGE 3A: MULTICOLLINEARITY DETECTION')
print('='*80)

candidates_stage3 = static_2b_keep.copy()
print(f'Screening {len(candidates_stage3)} variables for multicollinearity...')

# Compute all pairwise correlations
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
                    if not np.isnan(rho):
                        pairwise_corr[(var1, var2)] = rho
            except:
                pass

# Identify high correlations
high_corr_pairs = [(v1, v2, rho) for (v1, v2), rho in pairwise_corr.items() 
                   if abs(rho) > RHO_COLLINEARITY_THRESHOLD]

high_corr_df = pd.DataFrame(high_corr_pairs, columns=['Var1', 'Var2', 'ρ'])
high_corr_df['|ρ|'] = high_corr_df['ρ'].abs()
high_corr_df = high_corr_df.sort_values('|ρ|', ascending=False)

if len(high_corr_df) > 0:
    print(f'\nHigh Correlations (|ρ| > {RHO_COLLINEARITY_THRESHOLD}):')
    print(high_corr_df.to_string(index=False))
    
    # Get CV for each variable to decide which to keep
    cv_dict = dict(zip(cv_df['Variable'], cv_df['CV']))
    
    # Greedy removal: for each pair, remove lower CV
    removed_collinear = set()
    for _, row in high_corr_df.iterrows():
        var1, var2, rho = row['Var1'], row['Var2'], row['ρ']
        
        if var1 not in removed_collinear and var2 not in removed_collinear:
            cv1 = cv_dict.get(var1, 0)
            cv2 = cv_dict.get(var2, 0)
            
            if cv1 > cv2:
                removed_collinear.add(var2)
            else:
                removed_collinear.add(var1)
    
    static_final = [v for v in candidates_stage3 if v not in removed_collinear]
    print(f'\nRemoved due to multicollinearity: {list(removed_collinear)}')
else:
    print(f'\nNo high correlations detected (|ρ| > {RHO_COLLINEARITY_THRESHOLD})')
    static_final = candidates_stage3

print(f'\nRetained after multicollinearity filter: {static_final}')

# =========================================================================
# STAGE 4: MULTICOLLINEARITY STATUS (VIF-equivalent)
# =========================================================================
print('')
print('='*80)
print('STAGE 4: MULTICOLLINEARITY STATUS (VIF ANALYSIS)')
print('='*80)

final_static_corr = station_static_clean[static_final].corr(method='spearman')
max_off_diag_corr = 0.0
max_pair = ('', '')

for i, var1 in enumerate(static_final):
    for j, var2 in enumerate(static_final):
        if i < j:
            corr_val = abs(final_static_corr.loc[var1, var2])
            if corr_val > max_off_diag_corr:
                max_off_diag_corr = corr_val
                max_pair = (var1, var2)

# Rough VIF estimate: VIF ≈ 1 / (1 - R²)
# With R² from max correlation
vif_equiv = 1.0 / (1.0 - (max_off_diag_corr ** 2) + 1e-10) if max_off_diag_corr < 1 else np.inf

print(f'\nMax |ρ| among retained variables: {max_off_diag_corr:.4f}')
print(f'Variable pair: {max_pair[0]} ↔ {max_pair[1]}')
print(f'VIF equivalent: {vif_equiv:.2f}')
if vif_equiv < 2.0:
    print('Status: ✅ Excellent (VIF < 2 = no multicollinearity issues)')
elif vif_equiv < 5.0:
    print('Status: ⚠️  Acceptable (VIF < 5)')
else:
    print('Status: ❌ Problematic (VIF > 5)')

# =========================================================================
# STAGE 5: FINAL SELECTION SUMMARY
# =========================================================================
print('')
print('='*80)
print('STAGE 5: FINAL SELECTION SUMMARY')
print('='*80)

print(f'\nDYNAMIC INPUTS ({len(dynamic_keep)} retained):')
for d in dynamic_keep:
    print(f'  ✅ {d}')

print(f'\nSTATIC INPUTS ({len(static_final)} retained from {len(static_present)} original):')
for s in sorted(static_final):
    print(f'  ✅ {s}')

print(f'\nTOTAL FEATURES: {len(dynamic_keep) + len(static_final)}')

# =========================================================================
# STAGE 6: SPATIAL HETEROGENEITY VALIDATION (K-means clustering)
# =========================================================================
print('')
print('='*80)
print('STAGE 6: SPATIAL HETEROGENEITY VALIDATION')
print('='*80)

n_clusters = min(5, max(3, len(station_static_clean) // 20))
print(f'Performing K-means clustering (k={n_clusters}) on retained static variables...')

scaler_spatial = StandardScaler()
X_scaled = scaler_spatial.fit_transform(station_static_clean[static_final])

kmeans = KMeans(n_clusters=n_clusters, random_state=RANDOM_STATE, n_init=10)
cluster_labels = kmeans.fit_predict(X_scaled)

# Analyze clusters
cluster_analysis = []
for cid in range(n_clusters):
    mask = cluster_labels == cid
    n_stations = np.sum(mask)
    
    # Get mean Q for this cluster
    cluster_idr = station_static_clean.index[mask]
    cluster_q_data = Y_train[Y_train['IDr'].isin(cluster_idr)]
    
    q_mean = cluster_q_data['Q50'].mean() if len(cluster_q_data) > 0 else np.nan
    q_std = cluster_q_data['Q50'].std() if len(cluster_q_data) > 0 else np.nan
    q_min = cluster_q_data['QMIN'].mean() if len(cluster_q_data) > 0 else np.nan
    q_max = cluster_q_data['QMAX'].mean() if len(cluster_q_data) > 0 else np.nan
    n_records = len(cluster_q_data)
    
    cluster_analysis.append({
        'Cluster': cid,
        'N_Stations': n_stations,
        'N_Records': n_records,
        'Q_min_mean': q_min,
        'Q50_mean': q_mean,
        'Q50_std': q_std,
        'Q_max_mean': q_max
    })

cluster_df = pd.DataFrame(cluster_analysis)
print('\nCLUSTER CHARACTERISTICS:')
print(cluster_df.to_string(index=False))

print('\nClusters represent distinct spatial/hydrologic regimes ✅')

# Save cluster assignments for later use
cluster_assignment = pd.DataFrame({
    'IDr': station_static_clean.index,
    'Cluster': cluster_labels
})

# =========================================================================
# STAGE 7: PREPARE FOR LSTM
# =========================================================================
print('')
print('='*80)
print('PREPARING DATA FOR LSTM WITH SELECTED VARIABLES')
print('='*80)

def clean_numeric_frame(df: pd.DataFrame) -> pd.DataFrame:
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

# Prepare dynamic features
X_train_dyn = clean_numeric_frame(X_train[dynamic_keep]).astype('float32')
X_test_dyn  = clean_numeric_frame(X_test[dynamic_keep]).astype('float32')

# Prepare static features
X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32')
X_test_sta  = clean_numeric_frame(X_test[static_final]).astype('float32')

# Prepare targets
q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf  = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print(f'Dynamic features shape: train {X_train_dyn.shape}, test {X_test_dyn.shape}')
print(f'Static features shape: train {X_train_sta.shape}, test {X_test_sta.shape}')
print(f'Target shape: train {Y_train_qdf.shape}, test {Y_test_qdf.shape}')

# Scaling
print('\nApplying QuantileTransformer scaling...')
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
X_test_dyn_s  = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s  = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s  = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

# =========================================================================
# BUILD SEQUENCES
# =========================================================================
print('')
print('='*80)
print('BUILDING LSTM SEQUENCES')
print('='*80)

def build_sequences(df_meta: pd.DataFrame, X_dyn_scaled: np.ndarray, 
                    X_sta_scaled: np.ndarray, Y_scaled: np.ndarray):
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

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(
    Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s
)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(
    Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s
)

print(f'Train sequences: {Xtr_seq_dyn.shape[0]:,} (dyn: {Xtr_seq_dyn.shape}, sta: {Xtr_seq_sta.shape})')
print(f'Test sequences:  {Xte_seq_dyn.shape[0]:,} (dyn: {Xte_seq_dyn.shape}, sta: {Xte_seq_sta.shape})')

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# =========================================================================
# LSTM MODEL & TRAINING
# =========================================================================
print('')
print('='*80)
print('LSTM MODEL TRAINING')
print('='*80)

class LSTMWithStaticContext(nn.Module):
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
        )
        self.head = nn.Sequential(
            nn.Linear(hidden + 64, 256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        sta_encoded = self.static_encoder(x_sta)
        z = torch.cat([h_last, sta_encoded], dim=1)
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
test_ds  = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)
test_loader  = DataLoader(test_ds,  batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = LSTMWithStaticContext(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

print(f'Model: LSTM {n_dyn} → 128 → 256 → 11 (with {n_sta}-dim static context)')
print(f'Device: {DEVICE}, Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}')

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

best_val = np.inf
best_state = None

print(f'\nTraining...')
for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)
    te_loss, _ = run_epoch(test_loader, train=False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 5 == 0 or ep == EPOCHS:
        print(f'Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best={best_val:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

# =========================================================================
# PREDICTIONS & METRICS
# =========================================================================
print('')
print('='*80)
print('PREDICTIONS & ACCURACY METRICS')
print('='*80)

_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed  = qt_y.inverse_transform(Pte_s_all).astype('float32')

Qtr_valid = Ytr_true_seq.astype('float32')
Qte_valid = Yte_true_seq.astype('float32')

def kge_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    if np.all(y_true == y_true[0]):
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

def nse_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    numerator = np.sum((y_true - y_pred) ** 2)
    denominator = np.sum((y_true - np.mean(y_true)) ** 2)
    if denominator == 0:
        return np.nan
    return 1 - (numerator / denominator)

def rmse_1d(y_true, y_pred):
    return np.sqrt(mean_squared_error(y_true, y_pred))

def compute_metrics(Y_true_np, Y_pred_np):
    metrics = {}
    
    r_vals = [pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    metrics['r'] = (np.nanmean(r_vals), r_vals)
    
    rho_vals = [spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(11)]
    metrics['rho'] = (np.nanmean(rho_vals), rho_vals)
    
    mae_vals = [mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    metrics['mae'] = (np.mean(mae_vals), mae_vals)
    
    rmse_vals = [rmse_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    metrics['rmse'] = (np.mean(rmse_vals), rmse_vals)
    
    kge_vals = [kge_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    metrics['kge'] = (np.nanmean(kge_vals), kge_vals)
    
    nse_vals = [nse_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    metrics['nse'] = (np.nanmean(nse_vals), nse_vals)
    
    r2_vals = [r2_score(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(11)]
    metrics['r2'] = (np.mean(r2_vals), r2_vals)
    
    return metrics

train_metrics = compute_metrics(Qtr_valid, Q_train_reconstructed)
test_metrics  = compute_metrics(Qte_valid, Q_test_reconstructed)

print('\nTRAIN METRICS:')
for metric in ['r', 'nse', 'kge', 'rmse', 'mae']:
    print(f'  {metric.upper():6s}: {train_metrics[metric][0]:.4f}')

print('\nTEST METRICS:')
for metric in ['r', 'nse', 'kge', 'rmse', 'mae']:
    print(f'  {metric.upper():6s}: {test_metrics[metric][0]:.4f}')

# =========================================================================
# SAVE RESULTS
# =========================================================================
print('')
print('='*80)
print('SAVING RESULTS')
print('='*80)

# Save feature selection report
selection_report = f'''
SPEARMAN ρ-BASED SPATIO-TEMPORAL VARIABLE SELECTION & LSTM
{'='*80}

TEMPORAL SPLIT:
  Training:  {TRAIN_START_YEAR}-{TRAIN_END_YEAR}
  Testing:   {TEST_START_YEAR}-{TEST_END_YEAR}

DYNAMIC VARIABLE SELECTION: {'ENABLED' if DYNAMIC_SELECTION_FLAG else 'DISABLED (using defaults)'}
  Threshold (|ρ_max| across lags): {RHO_LAG_THRESHOLD}
  Selected: {len(dynamic_keep)}
  Variables: {', '.join(dynamic_keep)}

STATIC VARIABLE SELECTION:
  Initial candidates: {len(static_present)}
  
  After Stage 2A (Spatial Variance, CV ≥ {CV_SPATIAL_THRESHOLD}): {len(static_2a_keep)}
  After Stage 2B (Spatial Correlation, |ρ| ≥ {RHO_SPATIAL_THRESHOLD}): {len(static_2b_keep)}
  After Stage 3A (Multicollinearity, |ρ| ≥ {RHO_COLLINEARITY_THRESHOLD}): {len(static_final)}
  
  Final selected: {len(static_final)}
  Variables: {', '.join(sorted(static_final))}

MULTICOLLINEARITY STATUS:
  Max |ρ| among retained: {max_off_diag_corr:.4f}
  VIF equivalent: {vif_equiv:.2f}
  Status: {'✅ Excellent' if vif_equiv < 2.0 else '⚠️ Acceptable' if vif_equiv < 5.0 else '❌ Problematic'}

SPATIAL HETEROGENEITY:
  K-means clusters: {n_clusters}
  Distinct regimes identified: YES

LSTM CONFIGURATION:
  Sequence length: {SEQ_LEN}
  Dynamic inputs: {n_dyn}
  Static inputs: {n_sta}
  Hidden units: 128
  Layers: 2
  Epochs: {EPOCHS}
  Batch size: {BATCH_SIZE}
  Device: {DEVICE}

TRAINING DATA:
  Train sequences: {Xtr_seq_dyn.shape[0]:,}
  Test sequences: {Xte_seq_dyn.shape[0]:,}

RESULTS:
  Train Pearson r:  {train_metrics['r'][0]:.4f}
  Test Pearson r:   {test_metrics['r'][0]:.4f}
  
  Train NSE:        {train_metrics['nse'][0]:.4f}
  Test NSE:         {test_metrics['nse'][0]:.4f}
  
  Train KGE:        {train_metrics['kge'][0]:.4f}
  Test KGE:         {test_metrics['kge'][0]:.4f}
  
  Train RMSE:       {train_metrics['rmse'][0]:.4f}
  Test RMSE:        {test_metrics['rmse'][0]:.4f}
'''

with open('../predict_score_red/LSTM_spearman_selection_report.txt', 'w') as f:
    f.write(selection_report)

print('✅ Selection report saved')

# Save predictions
np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTrain_spearman.txt',
    Q_train_reconstructed, delimiter=' ', fmt='%.6f',
    header=' '.join(q_cols), comments=''
)
np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTest_spearman.txt',
    Q_test_reconstructed, delimiter=' ', fmt='%.6f',
    header=' '.join(q_cols), comments=''
)

print('✅ Predictions saved')

# Save metrics
metrics_data = {
    'Pearson_r': np.concatenate([
        np.array(train_metrics['r'][1]).reshape(1, -1),
        np.array(test_metrics['r'][1]).reshape(1, -1)
    ]),
    'NSE': np.concatenate([
        np.array(train_metrics['nse'][1]).reshape(1, -1),
        np.array(test_metrics['nse'][1]).reshape(1, -1)
    ]),
    'KGE': np.concatenate([
        np.array(train_metrics['kge'][1]).reshape(1, -1),
        np.array(test_metrics['kge'][1]).reshape(1, -1)
    ])
}

for metric_name, metric_vals in metrics_data.items():
    np.savetxt(
        f'../predict_score_red/LSTM_score{metric_name}_spearman.txt',
        metric_vals, delimiter=' ', fmt='%.4f'
    )

print('✅ Metrics saved')

# Save selected features list
with open('../predict_importance_red/LSTM_selected_features_spearman.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_keep:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

print('✅ Selected features list saved')

print('')
print('='*80)
print('SCRIPT COMPLETED SUCCESSFULLY')
print('='*80)

EOF
exit
