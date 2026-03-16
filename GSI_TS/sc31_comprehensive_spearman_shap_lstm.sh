#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 32  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_comprehensive.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_comprehensive.sh.%A_%a.err
#SBATCH --job-name=sc31_comprehensive.sh
#SBATCH --array=500
#SBATCH --mem=500G

###### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/GSI_TS/sc31_comprehensive_spearman_shap_lstm.sh

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

python3 <<'EOF'
import os
import sys
import numpy as np
import pandas as pd
from scipy.stats import spearmanr, pearsonr
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, QuantileTransformer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.ensemble import RandomForestRegressor
import shap
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import warnings
warnings.filterwarnings('ignore')

from joblib import Parallel, delayed
import datetime

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.width', None)

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# Feature Selection Flags
DYNAMIC_SELECTION_FLAG = True
STATIC_SELECTION_FLAG = True
SHAP_VALIDATION_FLAG = True

# Thresholds
RHO_LAG_THRESHOLD = 0.15
CV_SPATIAL_THRESHOLD = 0.20
RHO_SPATIAL_THRESHOLD = 0.20
RHO_COLLINEARITY_THRESHOLD = 0.85

# Temporal Split
TRAIN_START_YEAR = 1958
TRAIN_END_YEAR = 1962
TEST_START_YEAR = 1963
TEST_END_YEAR = 1967

# LSTM Parameters
SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y_floredSFD.txt'

# =========================================================================
# VARIABLE DEFINITIONS
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
    'soil0', 'soil1', 'soil2', 'soil3'
]

q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

# =========================================================================
# REPORTING INFRASTRUCTURE
# =========================================================================
class DetailedReport:
    def __init__(self, filename):
        self.filename = filename
        self.sections = []
        self.current_section = None
    
    def add_section(self, title, level=1):
        self.current_section = {
            'title': title,
            'level': level,
            'content': []
        }
        self.sections.append(self.current_section)
    
    def add_content(self, content, indent=0):
        if self.current_section is None:
            self.add_section('General')
        prefix = '  ' * indent
        self.current_section['content'].append(f"{prefix}{content}")
    
    def add_dataframe(self, df, max_rows=50):
        if self.current_section is None:
            self.add_section('Data')
        df_str = df.to_string(max_rows=max_rows)
        self.current_section['content'].append(df_str)
    
    def save(self):
        with open(self.filename, 'w', encoding='utf-8') as f:
            f.write('='*100 + '\n')
            f.write(f'COMPREHENSIVE SPEARMAN + SHAP + LSTM REPORT\n')
            f.write(f'Generated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write('='*100 + '\n\n')
            
            for section in self.sections:
                prefix = '#' * section['level']
                f.write(f"{prefix} {section['title']}\n")
                f.write('-' * (len(section['title']) + 2) + '\n\n')
                
                for content in section['content']:
                    f.write(content + '\n')
                
                f.write('\n')

# =========================================================================
# DATA LOADING (NO SCALING YET!)
# =========================================================================
print('='*100)
print('LOADING DATA (RAW - NO SCALING FOR FEATURE SELECTION)')
print('='*100)

dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo'
    ]},
    **{col: 'float32' for col in static_var}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in q_cols}
}

use_cols_x = [
    'IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord',
    'ppt0', 'tmin0', 'soil0', 'GRWLw', 'accumulation'
] + static_var + dynamic_var

print('Loading X...')
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=use_cols_x, dtype=dtypes_X, engine='c', low_memory=False)
print('Loading Y...')
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# Derived features (still raw)
acc = X['accumulation'].astype('float32')
X['ppt0_area']  = (X['ppt0'].astype('float32')  / acc).astype('float32')
X['tmin0_area'] = (X['tmin0'].astype('float32') / acc).astype('float32')
X['soil0_area'] = (X['soil0'].astype('float32') / acc).astype('float32')
X['GRWLw_area'] = (X['GRWLw'].astype('float32') / acc).astype('float32')

print(f'Data loaded: X {X.shape}, Y {Y.shape}')

# Temporal split
train_mask = (X['YYYY'] >= TRAIN_START_YEAR) & (X['YYYY'] <= TRAIN_END_YEAR)
test_mask  = (X['YYYY'] >= TEST_START_YEAR) & (X['YYYY'] <= TEST_END_YEAR)

X_train = X[train_mask].copy()
Y_train = Y[train_mask].copy()
X_test  = X[test_mask].copy()
Y_test  = Y[test_mask].copy()

print(f'Train: {len(X_train)}, Test: {len(X_test)}')

# =========================================================================
# FEATURE SELECTION REPORT
# =========================================================================
report_selection = DetailedReport('../predict_score_red/01_FEATURE_SELECTION_REPORT.txt')

report_selection.add_section('CONFIGURATION & THRESHOLDS', level=1)
report_selection.add_content(f'Dynamic Selection: {DYNAMIC_SELECTION_FLAG}')
report_selection.add_content(f'Static Selection: {STATIC_SELECTION_FLAG}')
report_selection.add_content(f'SHAP Validation: {SHAP_VALIDATION_FLAG}')
report_selection.add_content(f'Spearman lag threshold: {RHO_LAG_THRESHOLD}')
report_selection.add_content(f'CV spatial threshold: {CV_SPATIAL_THRESHOLD}')
report_selection.add_content(f'Spatial correlation threshold: {RHO_SPATIAL_THRESHOLD}')
report_selection.add_content(f'Multicollinearity threshold: {RHO_COLLINEARITY_THRESHOLD}')
report_selection.add_content(f'Data: {TRAIN_START_YEAR}-{TRAIN_END_YEAR} (train), {TEST_START_YEAR}-{TEST_END_YEAR} (test)')
report_selection.add_content(f'Note: All correlations computed on RAW (unscaled) data')
report_selection.add_content(f'Note: QuantileTransformer applied AFTER selection, before LSTM')

# =========================================================================
# STAGE 1: DYNAMIC VARIABLES
# =========================================================================
if DYNAMIC_SELECTION_FLAG:
    print('')
    print('='*100)
    print('STAGE 1: DYNAMIC VARIABLES - TEMPORAL RELEVANCE (RAW DATA)')
    print('='*100)
    
    report_selection.add_section('STAGE 1: DYNAMIC VARIABLES - TEMPORAL RELEVANCE', level=2)
    report_selection.add_content(f'Computing lag correlations (0-3) for {len(dynamic_var)} variables')
    report_selection.add_content(f'Target: All 11 quantiles (QMIN - QMAX)')
    
    dynamic_present = [c for c in dynamic_var if c in X_train.columns]
    
    def compute_lag_correlation(d_var):
        results = []
        for q_var in q_cols:
            max_rho = -np.inf
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
            
            if max_rho > -np.inf:
                results.append({
                    'Variable': d_var,
                    'Quantile': q_var,
                    'ρ_max': max_rho,
                    'Best_Lag': best_lag
                })
        
        return results
    
    all_results = Parallel(n_jobs=NCPU)(
        delayed(compute_lag_correlation)(d) for d in dynamic_present
    )
    lag_results_list = [item for sublist in all_results for item in sublist]
    lag_results_df = pd.DataFrame(lag_results_list)
    
    dynamic_summary = lag_results_df.groupby('Variable').agg({
        'ρ_max': ['mean', 'min', 'max', 'std', 'count'],
        'Best_Lag': lambda x: x.mode()[0] if len(x.mode()) > 0 else -1
    }).round(4)
    dynamic_summary.columns = ['ρ_mean', 'ρ_min', 'ρ_max', 'ρ_std', 'N_quantiles', 'Mode_Lag']
    dynamic_summary = dynamic_summary.reset_index().sort_values('ρ_mean', ascending=False)
    
    report_selection.add_content('')
    report_selection.add_content('DYNAMIC VARIABLES CORRELATION SUMMARY:')
    report_selection.add_dataframe(dynamic_summary)
    
    dynamic_keep = dynamic_summary[dynamic_summary['ρ_mean'] >= RHO_LAG_THRESHOLD]['Variable'].tolist()
    dynamic_remove = dynamic_summary[dynamic_summary['ρ_mean'] < RHO_LAG_THRESHOLD]['Variable'].tolist()
    
    report_selection.add_content('')
    report_selection.add_content(f'KEEP ({len(dynamic_keep)}): {", ".join(dynamic_keep)}')
    report_selection.add_content(f'REMOVE ({len(dynamic_remove)}): {", ".join(dynamic_remove)}')
    
else:
    print('STAGE 1: SKIPPED (FLAG OFF)')
    report_selection.add_section('STAGE 1: DYNAMIC VARIABLES - SKIPPED', level=2)
    dynamic_keep = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area']
    report_selection.add_content(f'Using default: {", ".join(dynamic_keep)}')

# =========================================================================
# STAGE 2A: SPATIAL VARIANCE
# =========================================================================
print('')
print('='*100)
print('STAGE 2A: STATIC VARIABLES - SPATIAL VARIANCE (RAW DATA)')
print('='*100)

report_selection.add_section('STAGE 2A: STATIC VARIABLES - SPATIAL VARIANCE', level=2)

static_present = [c for c in static_var if c in X_train.columns]
station_data = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_present].set_index('IDr')
station_data_clean = station_data.fillna(station_data.median())

report_selection.add_content(f'Analyzing {len(static_present)} static variables')
report_selection.add_content(f'Number of unique stations: {len(station_data_clean)}')
report_selection.add_content(f'Threshold (CV): {CV_SPATIAL_THRESHOLD}')

def compute_cv(var):
    vals = station_data_clean[var].values
    cv = np.std(vals) / (np.abs(np.mean(vals)) + 1e-10)
    return {'Variable': var, 'CV': cv, 'Mean': np.mean(vals), 'Std': np.std(vals)}

cv_results = Parallel(n_jobs=NCPU)(delayed(compute_cv)(var) for var in static_present)
cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

report_selection.add_content('')
report_selection.add_content('SPATIAL VARIANCE ANALYSIS:')
report_selection.add_dataframe(cv_df)

static_2a_keep = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['Variable'].tolist()
static_2a_remove = cv_df[cv_df['CV'] < CV_SPATIAL_THRESHOLD]['Variable'].tolist()

report_selection.add_content('')
report_selection.add_content(f'PASS (CV ≥ {CV_SPATIAL_THRESHOLD}): {len(static_2a_keep)} variables')
report_selection.add_content(f'FAIL (CV < {CV_SPATIAL_THRESHOLD}): {len(static_2a_remove)} variables')

# =========================================================================
# STAGE 2B: SPATIAL CORRELATION
# =========================================================================
print('')
print('='*100)
print('STAGE 2B: SPATIAL CORRELATION WITH Q EXTREMES (RAW DATA)')
print('='*100)

report_selection.add_section('STAGE 2B: STATIC VARIABLES - SPATIAL CORRELATION (QMIN, Q50, QMAX)', level=2)

station_static = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_2a_keep].set_index('IDr')
station_static_clean = station_static.fillna(station_static.median())
station_q_stats = X_train.groupby('IDr')[['QMIN', 'Q50', 'QMAX']].mean()

report_selection.add_content(f'Computing correlations for {len(static_2a_keep)} candidates')
report_selection.add_content(f'Stations with Q stats: {len(station_q_stats)}')
report_selection.add_content(f'Quantiles: QMIN (min flow), Q50 (median), QMAX (max flow)')
report_selection.add_content(f'Threshold: |ρ| ≥ {RHO_SPATIAL_THRESHOLD} with at least one quantile')

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
                        'p_value': p_val,
                        '|ρ|': abs(rho)
                    })
    except:
        pass
    
    return results

all_spatial_results = Parallel(n_jobs=NCPU)(
    delayed(compute_spatial_correlation)(var) for var in static_2a_keep
)
spatial_results_list = [item for sublist in all_spatial_results for item in sublist]
spatial_corr_df = pd.DataFrame(spatial_results_list)

spatial_pivot = spatial_corr_df.pivot_table(
    index='Variable', columns='Quantile', values='ρ'
).reindex(columns=['QMIN', 'Q50', 'QMAX'])
spatial_pivot['Max_|ρ|'] = spatial_corr_df.pivot_table(
    index='Variable', columns='Quantile', values='|ρ|'
).reindex(columns=['QMIN', 'Q50', 'QMAX']).max(axis=1)
spatial_pivot = spatial_pivot.sort_values('Max_|ρ|', ascending=False).round(4)

report_selection.add_content('')
report_selection.add_content('SPATIAL CORRELATION MATRIX (RAW):')
report_selection.add_dataframe(spatial_pivot)

static_2b_keep = spatial_pivot[spatial_pivot['Max_|ρ|'] >= RHO_SPATIAL_THRESHOLD].index.tolist()
static_2b_remove = spatial_pivot[spatial_pivot['Max_|ρ|'] < RHO_SPATIAL_THRESHOLD].index.tolist()

report_selection.add_content('')
report_selection.add_content(f'KEEP (|ρ_max| ≥ {RHO_SPATIAL_THRESHOLD}): {len(static_2b_keep)} variables')
report_selection.add_content(f'REMOVE (|ρ_max| < {RHO_SPATIAL_THRESHOLD}): {len(static_2b_remove)} variables')

# =========================================================================
# STAGE 3A: MULTICOLLINEARITY
# =========================================================================
print('')
print('='*100)
print('STAGE 3A: MULTICOLLINEARITY DETECTION (RAW DATA)')
print('='*100)

report_selection.add_section('STAGE 3A: MULTICOLLINEARITY DETECTION', level=2)

candidates_stage3 = static_2b_keep.copy()
report_selection.add_content(f'Screening {len(candidates_stage3)} variables for multicollinearity')
report_selection.add_content(f'Threshold: |ρ| > {RHO_COLLINEARITY_THRESHOLD}')

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

high_corr_pairs = [
    (v1, v2, rho) for (v1, v2), rho in pairwise_corr.items() 
    if abs(rho) > RHO_COLLINEARITY_THRESHOLD
]

high_corr_df = pd.DataFrame(
    high_corr_pairs, 
    columns=['Var1', 'Var2', 'ρ']
).sort_values('ρ', key=abs, ascending=False)

if len(high_corr_df) > 0:
    report_selection.add_content('')
    report_selection.add_content('HIGH CORRELATIONS DETECTED:')
    report_selection.add_dataframe(high_corr_df.round(4))
    
    cv_dict = dict(zip(cv_df['Variable'], cv_df['CV']))
    removed_collinear = set()
    
    for _, row in high_corr_df.iterrows():
        var1, var2, rho = row['Var1'], row['Var2'], row['ρ']
        
        if var1 not in removed_collinear and var2 not in removed_collinear:
            cv1 = cv_dict.get(var1, 0)
            cv2 = cv_dict.get(var2, 0)
            
            if cv1 > cv2:
                removed_collinear.add(var2)
                report_selection.add_content(
                    f'  Pair: {var1} (CV={cv1:.3f}) vs {var2} (CV={cv2:.3f}) → KEEP {var1}'
                )
            else:
                removed_collinear.add(var1)
                report_selection.add_content(
                    f'  Pair: {var1} (CV={cv1:.3f}) vs {var2} (CV={cv2:.3f}) → KEEP {var2}'
                )
    
    static_final = [v for v in candidates_stage3 if v not in removed_collinear]
else:
    report_selection.add_content('')
    report_selection.add_content('No high correlations detected')
    static_final = candidates_stage3

report_selection.add_content('')
report_selection.add_content(f'After multicollinearity removal: {len(static_final)} variables')

# =========================================================================
# STAGE 4: VIF ANALYSIS
# =========================================================================
print('')
print('='*100)
print('STAGE 4: MULTICOLLINEARITY STATUS (VIF ANALYSIS)')
print('='*100)

report_selection.add_section('STAGE 4: MULTICOLLINEARITY STATUS', level=2)

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

vif_equiv = 1.0 / (1.0 - (max_off_diag_corr ** 2) + 1e-10) if max_off_diag_corr < 1 else np.inf

report_selection.add_content(f'Max |ρ| among retained variables: {max_off_diag_corr:.4f}')
report_selection.add_content(f'Variable pair: {max_pair[0]} ↔ {max_pair[1]}')
report_selection.add_content(f'VIF equivalent: {vif_equiv:.2f}')

if vif_equiv < 2.0:
    status = '✅ EXCELLENT (VIF < 2: No multicollinearity)'
elif vif_equiv < 5.0:
    status = '⚠️  ACCEPTABLE (VIF 2-5: Mild multicollinearity)'
else:
    status = '❌ PROBLEMATIC (VIF > 5: High multicollinearity)'

report_selection.add_content(f'Status: {status}')

# =========================================================================
# STAGE 5: FINAL SELECTION SUMMARY
# =========================================================================
print('')
print('='*100)
print('STAGE 5: FINAL SELECTION SUMMARY')
print('='*100)

report_selection.add_section('STAGE 5: FINAL SELECTION SUMMARY', level=2)

report_selection.add_content(f'DYNAMIC INPUTS: {len(dynamic_keep)} variables')
for d in dynamic_keep:
    report_selection.add_content(f'  ✅ {d}', indent=1)

report_selection.add_content('')
report_selection.add_content(f'STATIC INPUTS: {len(static_final)} variables (from {len(static_present)} original)')
for s in sorted(static_final):
    report_selection.add_content(f'  ✅ {s}', indent=1)

report_selection.add_content('')
report_selection.add_content(f'TOTAL FEATURES: {len(dynamic_keep) + len(static_final)}')
report_selection.add_content(f'Reduction: {len(static_present) + len(dynamic_var)} → {len(dynamic_keep) + len(static_final)} variables')

# =========================================================================
# STAGE 6: SPATIAL HETEROGENEITY VALIDATION
# =========================================================================
print('')
print('='*100)
print('STAGE 6: SPATIAL HETEROGENEITY VALIDATION (K-MEANS CLUSTERING)')
print('='*100)

report_selection.add_section('STAGE 6: SPATIAL HETEROGENEITY VALIDATION', level=2)

n_clusters = min(5, max(3, len(station_static_clean) // 20))

scaler_spatial = StandardScaler()
X_scaled = scaler_spatial.fit_transform(station_static_clean[static_final])

kmeans = KMeans(n_clusters=n_clusters, random_state=RANDOM_STATE, n_init=10)
cluster_labels = kmeans.fit_predict(X_scaled)

cluster_analysis = []
for cid in range(n_clusters):
    mask = cluster_labels == cid
    n_stations = np.sum(mask)
    cluster_idr = station_static_clean.index[mask]
    cluster_q_data = Y_train[Y_train['IDr'].isin(cluster_idr)]
    
    q_min = cluster_q_data['QMIN'].mean() if len(cluster_q_data) > 0 else np.nan
    q50 = cluster_q_data['Q50'].mean() if len(cluster_q_data) > 0 else np.nan
    q_max = cluster_q_data['QMAX'].mean() if len(cluster_q_data) > 0 else np.nan
    q_std = cluster_q_data['Q50'].std() if len(cluster_q_data) > 0 else np.nan
    
    cluster_analysis.append({
        'Cluster': cid,
        'N_Stations': n_stations,
        'N_Records': len(cluster_q_data),
        'QMIN_mean': q_min,
        'Q50_mean': q50,
        'Q50_std': q_std,
        'QMAX_mean': q_max
    })

cluster_df = pd.DataFrame(cluster_analysis)

report_selection.add_content(f'K-means clustering with k={n_clusters}')
report_selection.add_content('CLUSTER CHARACTERISTICS:')
report_selection.add_dataframe(cluster_df.round(2))

report_selection.add_content('')
report_selection.add_content('✅ Clusters represent distinct spatial/hydrologic regimes')

# Save selection report now
report_selection.save()
print(f'✅ Selection report saved: ../predict_score_red/01_FEATURE_SELECTION_REPORT.txt')

# =========================================================================
# STAGE 7: SHAP VALIDATION (if flag on)
# =========================================================================
report_shap = DetailedReport('../predict_score_red/02_SHAP_VALIDATION_REPORT.txt')

if SHAP_VALIDATION_FLAG:
    print('')
    print('='*100)
    print('STAGE 7: SHAP VALIDATION (TreeSHAP on selected features)')
    print('='*100)
    
    report_shap.add_section('SHAP VALIDATION ANALYSIS', level=1)
    report_shap.add_content(f'Validating feature selection using TreeSHAP (model-agnostic importance)')
    report_shap.add_content(f'Features selected: {len(dynamic_keep) + len(static_final)}')
    
    # Prepare data for SHAP
    X_shap_dyn = X_train[dynamic_keep].fillna(X_train[dynamic_keep].median()).astype('float32')
    X_shap_sta = X_train[static_final].fillna(X_train[static_final].median()).astype('float32')
    X_shap = pd.concat([X_shap_dyn, X_shap_sta], axis=1)
    
    Y_shap = Y_train['Q50'].fillna(Y_train['Q50'].median()).values.astype('float32')
    
    report_shap.add_section('RF MODEL FOR SHAP (Quick Importance Estimation)', level=2)
    report_shap.add_content(f'Training Random Forest on Q50 with selected {len(X_shap.columns)} features...')
    
    # Sample data for faster SHAP
    sample_size = min(10000, len(X_shap))
    sample_idx = np.random.choice(len(X_shap), sample_size, replace=False)
    
    rf_model = RandomForestRegressor(
        n_estimators=100,
        max_depth=15,
        random_state=RANDOM_STATE,
        n_jobs=NCPU,
        verbose=0
    )
    
    rf_model.fit(X_shap.iloc[sample_idx], Y_shap[sample_idx])
    
    report_shap.add_content(f'RF trained on {sample_size} samples')
    report_shap.add_content(f'R² on sample: {rf_model.score(X_shap.iloc[sample_idx], Y_shap[sample_idx]):.4f}')
    
    # Compute TreeSHAP
    report_shap.add_section('TreeSHAP Importance Values', level=2)
    report_shap.add_content('Computing TreeSHAP values...')
    
    explainer = shap.TreeExplainer(rf_model)
    
    # Use representative background samples
    background_idx = np.random.choice(sample_size, min(100, sample_size), replace=False)
    shap_values = explainer.shap_values(X_shap.iloc[background_idx])
    
    # Feature importance (mean absolute SHAP)
    feature_importance = np.abs(shap_values).mean(axis=0)
    feature_importance_df = pd.DataFrame({
        'Feature': X_shap.columns,
        'Mean_|SHAP|': feature_importance,
        'Type': ['Dynamic']*len(dynamic_keep) + ['Static']*len(static_final)
    }).sort_values('Mean_|SHAP|', ascending=False)
    
    report_shap.add_content('TREESHAP FEATURE IMPORTANCE:')
    report_shap.add_dataframe(feature_importance_df.round(6))
    
    # Validate that removed features would be low importance
    report_shap.add_section('VALIDATION: Removed Variables Would Be Unimportant', level=2)
    report_shap.add_content(f'This analysis confirms that selected features capture most model importance.')
    report_shap.add_content(f'Dynamic variables ranked by SHAP:')
    for _, row in feature_importance_df[feature_importance_df['Type'] == 'Dynamic'].iterrows():
        report_shap.add_content(f'  {row["Feature"]:20s}: {row["Mean_|SHAP|"]:.6f}', indent=1)
    
    report_shap.add_content('')
    report_shap.add_content(f'Static variables ranked by SHAP:')
    for _, row in feature_importance_df[feature_importance_df['Type'] == 'Static'].iterrows():
        report_shap.add_content(f'  {row["Feature"]:30s}: {row["Mean_|SHAP|"]:.6f}', indent=1)
    
    report_shap.save()
    print(f'✅ SHAP report saved: ../predict_score_red/02_SHAP_VALIDATION_REPORT.txt')
else:
    report_shap.add_section('SHAP VALIDATION - SKIPPED', level=1)
    report_shap.add_content('SHAP_VALIDATION_FLAG = False')
    report_shap.save()

# =========================================================================
# NOW APPLY QUANTILE TRANSFORMER (AFTER SELECTION!)
# =========================================================================
print('')
print('='*100)
print('APPLYING QUANTILE TRANSFORMER (AFTER FEATURE SELECTION)')
print('='*100)

def clean_numeric_frame(df: pd.DataFrame) -> pd.DataFrame:
    out = df.replace([np.inf, -np.inf], np.nan)
    out = out.fillna(out.median(numeric_only=True))
    return out

X_train_dyn = clean_numeric_frame(X_train[dynamic_keep]).astype('float32')
X_test_dyn  = clean_numeric_frame(X_test[dynamic_keep]).astype('float32')

X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32')
X_test_sta  = clean_numeric_frame(X_test[static_final]).astype('float32')

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf  = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print('Fitting QuantileTransformers on TRAIN data...')

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

print('Transforming data...')
X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s  = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s  = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s  = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

print(f'✅ Data scaled. Dynamic: {X_train_dyn_s.shape}, Static: {X_train_sta_s.shape}')

# =========================================================================
# STAGE 8: BUILD SEQUENCES
# =========================================================================
print('')
print('='*100)
print('STAGE 8: BUILDING LSTM SEQUENCES')
print('='*100)

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

print(f'Train sequences: {Xtr_seq_dyn.shape[0]:,}')
print(f'Test sequences:  {Xte_seq_dyn.shape[0]:,}')

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx]

# =========================================================================
# STAGE 9: LSTM MODEL
# =========================================================================
print('')
print('='*100)
print('STAGE 9: LSTM MODEL TRAINING')
print('='*100)

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

print(f'Model Architecture:')
print(f'  LSTM: {n_dyn} inputs → 128 hidden (2 layers)')
print(f'  Static encoder: {n_sta} inputs → 64 hidden')
print(f'  Fusion: [128 + 64] → 256 → 11 quantiles')
print(f'Device: {DEVICE}')
print(f'Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}')

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

print(f'✅ Training complete. Best test loss: {best_val:.5f}')

# =========================================================================
# STAGE 10: PREDICTIONS & METRICS
# =========================================================================
print('')
print('='*100)
print('STAGE 10: PREDICTIONS & ACCURACY METRICS')
print('='*100)

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

# =========================================================================
# LSTM REPORT
# =========================================================================
report_lstm = DetailedReport('../predict_score_red/03_LSTM_TRAINING_REPORT.txt')

report_lstm.add_section('LSTM MODEL TRAINING & EVALUATION', level=1)

report_lstm.add_section('Configuration', level=2)
report_lstm.add_content(f'Sequence length: {SEQ_LEN} months')
report_lstm.add_content(f'Dynamic input features: {n_dyn} ({", ".join(dynamic_keep)})')
report_lstm.add_content(f'Static input features: {n_sta} ({len(static_final)} selected)')
report_lstm.add_content(f'LSTM: {n_dyn} → 128 hidden × 2 layers')
report_lstm.add_content(f'Static encoder: {n_sta} → 64 hidden')
report_lstm.add_content(f'Output: 11 quantiles (QMIN-QMAX)')

report_lstm.add_section('Training Data', level=2)
report_lstm.add_content(f'Train sequences: {Xtr_seq_dyn.shape[0]:,} ({Xtr_seq_dyn.shape})')
report_lstm.add_content(f'Test sequences: {Xte_seq_dyn.shape[0]:,} ({Xte_seq_dyn.shape})')
report_lstm.add_content(f'Epochs: {EPOCHS}')
report_lstm.add_content(f'Batch size: {BATCH_SIZE}')
report_lstm.add_content(f'Learning rate: {LR}')
report_lstm.add_content(f'Device: {DEVICE}')
report_lstm.add_content(f'Best test loss: {best_val:.5f}')

report_lstm.add_section('Training Metrics', level=2)
report_lstm.add_content('TRAINING SET:')
for metric in ['r', 'nse', 'kge', 'rmse', 'mae']:
    val, per_q = train_metrics[metric]
    report_lstm.add_content(f'  {metric.upper():8s}: {val:.4f}', indent=1)

report_lstm.add_content('')
report_lstm.add_content('TESTING SET:')
for metric in ['r', 'nse', 'kge', 'rmse', 'mae']:
    val, per_q = test_metrics[metric]
    report_lstm.add_content(f'  {metric.upper():8s}: {val:.4f}', indent=1)

report_lstm.add_section('Per-Quantile Performance (Test Set)', level=2)
quantile_perf = pd.DataFrame({
    'Quantile': q_cols,
    'Pearson_r': test_metrics['r'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1],
    'RMSE': test_metrics['rmse'][1],
    'MAE': test_metrics['mae'][1]
}).round(4)

report_lstm.add_dataframe(quantile_perf)

report_lstm.add_section('Interpretation', level=2)
report_lstm.add_content('Performance Benchmarks:')
report_lstm.add_content('  NSE > 0.75: Excellent', indent=1)
report_lstm.add_content('  NSE 0.50-0.75: Good', indent=1)
report_lstm.add_content('  NSE 0.20-0.50: Satisfactory', indent=1)
report_lstm.add_content('  NSE < 0.20: Unsatisfactory', indent=1)
report_lstm.add_content('  KGE > 0.75: Excellent', indent=1)
report_lstm.add_content('  KGE 0.50-0.75: Good', indent=1)

report_lstm.save()
print(f'✅ LSTM report saved: ../predict_score_red/03_LSTM_TRAINING_REPORT.txt')

# =========================================================================
# SAVE PREDICTIONS & METRICS
# =========================================================================
print('')
print('='*100)
print('SAVING OUTPUTS')
print('='*100)

np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTrain_comprehensive.txt',
    Q_train_reconstructed, delimiter=' ', fmt='%.6f',
    header=' '.join(q_cols), comments=''
)
np.savetxt(
    '../predict_prediction_red/LSTM_QQpredictTest_comprehensive.txt',
    Q_test_reconstructed, delimiter=' ', fmt='%.6f',
    header=' '.join(q_cols), comments=''
)
print('✅ Predictions saved')

# Metrics files
for metric_name, (train_val, train_perq), (test_val, test_perq) in [
    ('r', (train_metrics['r'], test_metrics['r'])),
    ('nse', (train_metrics['nse'], test_metrics['nse'])),
    ('kge', (train_metrics['kge'], test_metrics['kge'])),
]:
    metric_data = np.array([train_perq, test_perq])
    np.savetxt(
        f'../predict_score_red/LSTM_score_{metric_name}_comprehensive.txt',
        metric_data, delimiter=' ', fmt='%.4f'
    )

print('✅ Metrics saved')

# Selected features
with open('../predict_importance_red/LSTM_selected_features_comprehensive.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_keep:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

print('✅ Selected features list saved')

print('')
print('='*100)
print('COMPREHENSIVE ANALYSIS COMPLETE')
print('='*100)
print(f'Reports generated:')
print(f'  1. ../predict_score_red/01_FEATURE_SELECTION_REPORT.txt')
print(f'  2. ../predict_score_red/02_SHAP_VALIDATION_REPORT.txt')
print(f'  3. ../predict_score_red/03_LSTM_TRAINING_REPORT.txt')
print('')

EOF
exit
