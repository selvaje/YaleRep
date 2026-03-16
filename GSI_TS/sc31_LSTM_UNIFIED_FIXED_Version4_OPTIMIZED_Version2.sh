#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_UNIFIED_FIXED_V4_OPT.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_UNIFIED_FIXED_V4_OPT.%A_%a.err
#SBATCH --array=500
#SBATCH --mem=120G

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

# CRITICAL: Set thread limits to prevent CPU oversubscription
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

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
from sklearn.ensemble import RandomForestRegressor
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from joblib import Parallel, delayed
import warnings
warnings.filterwarnings('ignore')

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("SC31: UNIFIED LSTM PIPELINE v4 - OPTIMIZED PARALLELIZATION")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))
print(f"Available CPUs: {NCPU}")

# Time-Series Split Parameters
MIN_TRAIN_MONTHS = 60
MAX_GAP_DAYS = 30
MIN_TRAIN_OBS = 500

# Feature Selection Thresholds
RHO_LAG_THRESHOLD = 0.15
CV_SPATIAL_THRESHOLD = 0.20
RHO_SPATIAL_THRESHOLD = 0.20
RHO_COLLINEARITY_THRESHOLD = 0.85

# LSTM Parameters
SEQ_LEN = 12
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

# =========================================================================
# REPORTING INFRASTRUCTURE
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
# PHASE 1: LOAD DATA & INSPECT COLUMNS
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: DATA LOADING & COLUMN INSPECTION")
print("="*100)

print("Loading data...")
try:
    X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
    Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
    print(f"✓ X shape: {X.shape}, Y shape: {Y.shape}")
except Exception as e:
    print(f"ERROR loading data: {e}")
    sys.exit(1)

print(f"\nX columns ({len(X.columns)}): {list(X.columns[:20])}...")
print(f"\nY columns ({len(Y.columns)}): {list(Y.columns)}")

# Verify required columns
required_cols_X = ['IDr', 'YYYY', 'MM']
required_cols_Y = ['IDr', 'YYYY', 'MM']
missing_X = [c for c in required_cols_X if c not in X.columns]
missing_Y = [c for c in required_cols_Y if c not in Y.columns]

if missing_X or missing_Y:
    print(f"ERROR: Missing required columns!")
    if missing_X: print(f"  X missing: {missing_X}")
    if missing_Y: print(f"  Y missing: {missing_Y}")
    sys.exit(1)

# Define available variables based on columns in X
print("\n" + "-"*100)
print("IDENTIFYING AVAILABLE VARIABLES")
print("-"*100)

# Static variables (those that don't change over time)
static_candidates = [
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

# Dynamic variables (time-varying: precipitation, temperature, soil moisture)
dynamic_candidates = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# Filter to available columns
static_var = [v for v in static_candidates if v in X.columns]
dynamic_var = [v for v in dynamic_candidates if v in X.columns]

print(f"Available static variables: {len(static_var)}/{len(static_candidates)}")
print(f"  Present: {', '.join(static_var[:10])}..." if len(static_var) > 10 else f"  Present: {', '.join(static_var)}")

print(f"\nAvailable dynamic variables: {len(dynamic_var)}/{len(dynamic_candidates)}")
print(f"  Present: {', '.join(dynamic_var)}")

# Target quantiles
q_cols = [col for col in Y.columns if col.startswith('Q')]
if len(q_cols) == 0:
    # Fallback: try to find quantile columns differently
    q_cols = [col for col in Y.columns if any(x in col for x in ['QMIN', 'QMAX', 'Q50', 'Q25', 'Q75'])]

print(f"\nTarget quantiles: {len(q_cols)} - {', '.join(q_cols)}")

if len(q_cols) == 0:
    print("ERROR: No target quantile columns found in Y!")
    sys.exit(1)

# Reset indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# =========================================================================
# PHASE 2: TEMPORAL CONTIGUITY ANALYSIS
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: TEMPORAL CONTIGUITY ANALYSIS & TRAIN/TEST SPLIT")
print("="*100)

def analyze_contiguity(group_y):
    idr = group_y['IDr'].iloc[0]
    group = group_y.sort_values(by=['YYYY', 'MM']).reset_index(drop=True)
    group['date'] = pd.to_datetime(group[['YYYY', 'MM']].rename(columns={'YYYY': 'year', 'MM': 'month'}).assign(day=1))
    
    n_obs = len(group)
    dates = group['date'].values
    gaps = np.diff(dates).astype('timedelta64[D]').astype(int) if len(dates) > 1 else np.array([])
    
    max_gap = gaps.max() if len(gaps) > 0 else 0
    mean_gap = gaps.mean() if len(gaps) > 0 else 0
    n_large_gaps = np.sum(gaps > MAX_GAP_DAYS) if len(gaps) > 0 else 0
    span_years = (dates[-1] - dates[0]).astype('timedelta64[D]').astype(int) / 365.25 if len(dates) > 1 else 0
    
    return {
        'IDr': idr,
        'n_obs': n_obs,
        'max_gap_days': max_gap,
        'mean_gap_days': mean_gap,
        'n_large_gaps': n_large_gaps,
        'span_years': span_years
    }

print(f"Analyzing temporal contiguity for {Y['IDr'].nunique()} stations...")
# OPTIMIZED: Use prefer='processes' for CPU-bound tasks
contiguity_data = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
    delayed(analyze_contiguity)(group) for _, group in Y.groupby('IDr')
)
contiguity_df = pd.DataFrame(contiguity_data)

# Classify stations
train_stations_df = contiguity_df[
    (contiguity_df['n_obs'] >= MIN_TRAIN_OBS) & 
    (contiguity_df['max_gap_days'] <= MAX_GAP_DAYS)
]

test_stations_df = contiguity_df[
    ~contiguity_df['IDr'].isin(train_stations_df['IDr'])
]

train_idrs = train_stations_df['IDr'].tolist()
test_idrs = test_stations_df['IDr'].tolist()

print(f"\n✓ TRAINING STATIONS: {len(train_idrs)}")
if len(train_stations_df) > 0:
    print(f"  - Obs per station: {train_stations_df['n_obs'].mean():.0f} (min: {train_stations_df['n_obs'].min()}, max: {train_stations_df['n_obs'].max()})")
    print(f"  - Max gap: {train_stations_df['max_gap_days'].mean():.1f} days (max: {train_stations_df['max_gap_days'].max()})")

print(f"\n✓ TESTING STATIONS: {len(test_idrs)}")
if len(test_stations_df) > 0:
    print(f"  - Obs per station: {test_stations_df['n_obs'].mean():.0f} (min: {test_stations_df['n_obs'].min()}, max: {test_stations_df['n_obs'].max()})")
    print(f"  - Max gap: {test_stations_df['max_gap_days'].mean():.1f} days (max: {test_stations_df['max_gap_days'].max()})")

if len(train_idrs) == 0:
    print("ERROR: No training stations meet criteria!")
    sys.exit(1)

# Create splits
X_train = X[X['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
X_test = X[X['IDr'].isin(test_idrs)].copy().reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_idrs)].copy().reset_index(drop=True)

print(f"\nDataset shapes:")
print(f"  Train: X {X_train.shape}, Y {Y_train.shape}")
print(f"  Test:  X {X_test.shape}, Y {Y_test.shape}")

# Save Phase 2 report
report_ts = Report('../predict_score_red/01_TIMESERIES_SPLIT_REPORT_V4.txt')
report_ts.add_section('TIME-SERIES CONTIGUITY ANALYSIS', level=1)
report_ts.add_content(f'Analysis Date: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
report_ts.add_content(f'Total stations: {len(contiguity_df)}')
report_ts.add_content(f'Training: {len(train_idrs)} stations with ≥{MIN_TRAIN_OBS} obs, max gap ≤{MAX_GAP_DAYS} days')
report_ts.add_content(f'Testing: {len(test_idrs)} stations')
report_ts.add_section('TRAINING STATIONS', level=2)
report_ts.add_dataframe(train_stations_df.describe())
report_ts.add_section('TESTING STATIONS', level=2)
report_ts.add_dataframe(test_stations_df.describe())
report_ts.save()
print(f"✓ Phase 2 report saved")

# =========================================================================
# PHASE 3: FEATURE SELECTION
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: FEATURE SELECTION")
print("="*100)

# Create derived features
print("Creating derived features...")
derived_features_created = []

if 'ppt0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['ppt0_area'] = X_train['ppt0'].astype('float32') / (X_train['accumulation'].astype('float32') + 1e-10)
    X_test['ppt0_area'] = X_test['ppt0'].astype('float32') / (X_test['accumulation'].astype('float32') + 1e-10)
    derived_features_created.append('ppt0_area')

if 'tmin0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['tmin0_area'] = X_train['tmin0'].astype('float32') / (X_train['accumulation'].astype('float32') + 1e-10)
    X_test['tmin0_area'] = X_test['tmin0'].astype('float32') / (X_test['accumulation'].astype('float32') + 1e-10)
    derived_features_created.append('tmin0_area')

if 'soil0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['soil0_area'] = X_train['soil0'].astype('float32') / (X_train['accumulation'].astype('float32') + 1e-10)
    X_test['soil0_area'] = X_test['soil0'].astype('float32') / (X_test['accumulation'].astype('float32') + 1e-10)
    derived_features_created.append('soil0_area')

if 'GRWLw' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['GRWLw_area'] = X_train['GRWLw'].astype('float32') / (X_train['accumulation'].astype('float32') + 1e-10)
    X_test['GRWLw_area'] = X_test['GRWLw'].astype('float32') / (X_test['accumulation'].astype('float32') + 1e-10)
    derived_features_created.append('GRWLw_area')

print(f"✓ Created {len(derived_features_created)} derived features: {', '.join(derived_features_created)}")

# Stage 1: Dynamic variables - temporal relevance
print("\nStage 1: Dynamic variables temporal relevance...")

dynamic_present = [c for c in dynamic_var if c in X_train.columns]

if len(dynamic_present) == 0:
    print("WARNING: No dynamic variables found in data!")
    dynamic_keep = []
else:
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
                        if not np.isnan(rho) and abs(rho) > abs(max_rho):
                            max_rho = abs(rho)
                            best_lag = lag
                except:
                    pass
            if max_rho > -np.inf:
                results.append({'Variable': d_var, 'ρ_max': max_rho, 'best_lag': best_lag})
        return results

    # OPTIMIZED: Use prefer='processes' and batch_size
    all_results = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
        delayed(compute_lag_corr)(d) for d in dynamic_present
    )
    lag_results_list = [item for sublist in all_results for item in sublist]

    if len(lag_results_list) > 0:
        lag_results_df = pd.DataFrame(lag_results_list)
        dynamic_summary = lag_results_df.groupby('Variable')['ρ_max'].agg(['mean', 'min', 'max']).reset_index().sort_values('mean', ascending=False)
        dynamic_keep = dynamic_summary[dynamic_summary['mean'] >= RHO_LAG_THRESHOLD]['Variable'].tolist()
    else:
        print("  WARNING: No dynamic variables passed correlation threshold!")
        dynamic_keep = []

print(f"  KEEP {len(dynamic_keep)}/{len(dynamic_present)}: {', '.join(dynamic_keep) if len(dynamic_keep) > 0 else 'NONE'}")
print(f"  REMOVED {len(dynamic_present) - len(dynamic_keep)}")

# Stage 2A: Spatial variance
print("\nStage 2A: Static variables spatial variance...")

static_present = [c for c in static_var if c in X_train.columns]

if len(static_present) == 0:
    print("WARNING: No static variables found in data!")
    static_2a_keep = []
else:
    station_data = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_present].set_index('IDr')
    station_data_clean = station_data.fillna(station_data.median())

    def compute_cv(var):
        vals = station_data_clean[var].values
        cv = np.std(vals) / (np.abs(np.mean(vals)) + 1e-10)
        return {'Variable': var, 'CV': cv}

    # OPTIMIZED: threads for simple computations
    cv_results = Parallel(n_jobs=NCPU, prefer='threads', batch_size='auto')(
        delayed(compute_cv)(var) for var in static_present
    )
    cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

    static_2a_keep = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['Variable'].tolist()

print(f"  KEEP {len(static_2a_keep)}/{len(static_present)} variables (CV ≥ {CV_SPATIAL_THRESHOLD})")

# Stage 2B: Spatial correlation
print("\nStage 2B: Static variables spatial correlation...")

if len(static_2a_keep) == 0:
    print("  WARNING: No static variables from Stage 2A!")
    static_2b_keep = []
else:
    station_static = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + static_2a_keep].set_index('IDr')
    station_static_clean = station_static.fillna(station_static.median())
    
    # Use available q_cols for spatial correlation
    available_q_for_spatial = [q for q in q_cols if q in Y_train.columns]
    station_q_stats = Y_train.groupby('IDr')[available_q_for_spatial].mean()

    def compute_spatial_corr(var):
        results = []
        try:
            s_vals = station_static_clean[var].values
            for q_var in available_q_for_spatial:
                q_vals = station_q_stats[q_var].values
                mask = ~(np.isnan(s_vals) | np.isnan(q_vals))
                if np.sum(mask) > 5:
                    rho, _ = spearmanr(s_vals[mask], q_vals[mask])
                    if not np.isnan(rho):
                        results.append({'Variable': var, 'ρ': abs(rho)})
        except:
            pass
        return results

    # OPTIMIZED: prefer='processes' for scipy correlations
    all_spatial_results = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
        delayed(compute_spatial_corr)(var) for var in static_2a_keep
    )
    spatial_results_list = [item for sublist in all_spatial_results for item in sublist]
    
    if len(spatial_results_list) > 0:
        spatial_corr_df = pd.DataFrame(spatial_results_list)
        spatial_pivot = spatial_corr_df.pivot_table(index='Variable', values='ρ', aggfunc='max')
        static_2b_keep = spatial_pivot[spatial_pivot['ρ'] >= RHO_SPATIAL_THRESHOLD].index.tolist()
    else:
        print("  WARNING: No static variables passed spatial correlation threshold!")
        static_2b_keep = static_2a_keep

print(f"  KEEP {len(static_2b_keep)}/{len(static_2a_keep)} variables (|ρ| ≥ {RHO_SPATIAL_THRESHOLD})")

# Stage 3: Multicollinearity (NOW PARALLELIZED!)
print("\nStage 3: Multicollinearity detection...")

if len(static_2b_keep) == 0:
    print("  WARNING: No static variables from Stage 2B!")
    static_final = []
else:
    candidates_stage3 = static_2b_keep.copy()
    
    # OPTIMIZED: Parallelize pairwise correlation computation
    def compute_pairwise_corr(var_pair):
        var1, var2 = var_pair
        try:
            v1 = station_static_clean[var1].values
            v2 = station_static_clean[var2].values
            mask = ~(np.isnan(v1) | np.isnan(v2))
            if np.sum(mask) > 5:
                rho, _ = spearmanr(v1[mask], v2[mask])
                if not np.isnan(rho) and abs(rho) > RHO_COLLINEARITY_THRESHOLD:
                    return (var1, var2, abs(rho))
        except:
            pass
        return None
    
    # Generate all unique pairs
    var_pairs = [(candidates_stage3[i], candidates_stage3[j]) 
                 for i in range(len(candidates_stage3)) 
                 for j in range(i+1, len(candidates_stage3))]
    
    print(f"  Computing {len(var_pairs)} pairwise correlations in parallel...")
    pairwise_results = Parallel(n_jobs=NCPU, prefer='threads', batch_size='auto')(
        delayed(compute_pairwise_corr)(pair) for pair in var_pairs
    )
    
    # Filter out None results and build dictionary
    pairwise_corr = {(v1, v2): rho for result in pairwise_results 
                     if result is not None 
                     for v1, v2, rho in [result]}

    static_final = candidates_stage3.copy()
    removed_vars = set()

    cv_dict = dict(zip(cv_df['Variable'], cv_df['CV']))
    for (var1, var2), _ in sorted(pairwise_corr.items(), key=lambda x: x[1], reverse=True):
        if var1 not in removed_vars and var2 not in removed_vars:
            cv1 = cv_dict.get(var1, 0)
            cv2 = cv_dict.get(var2, 0)
            if cv1 > cv2:
                removed_vars.add(var2)
            else:
                removed_vars.add(var1)

    static_final = [v for v in candidates_stage3 if v not in removed_vars]
    print(f"  REMOVED {len(removed_vars)} collinear variables → {len(static_final)} kept")

# Combine dynamic + derived features
dynamic_keep_with_derived = dynamic_keep + derived_features_created

print(f"\n{'='*60}")
print("FINAL FEATURE SELECTION")
print(f"{'='*60}")
print(f"Dynamic: {len(dynamic_keep_with_derived)} variables")
print(f"  {', '.join(dynamic_keep_with_derived) if len(dynamic_keep_with_derived) > 0 else 'NONE'}")
print(f"Static: {len(static_final)} variables")
if len(static_final) > 0:
    if len(static_final) > 15:
        print(f"  {', '.join(sorted(static_final)[:15])}...")
    else:
        print(f"  {', '.join(sorted(static_final))}")
else:
    print(f"  NONE")

# CRITICAL: Check if we have enough features
if len(dynamic_keep_with_derived) == 0:
    print("\n" + "!"*100)
    print("ERROR: NO DYNAMIC FEATURES SELECTED! Cannot proceed with LSTM.")
    print("!"*100)
    sys.exit(1)

# Save Phase 3 report
report_fs = Report('../predict_score_red/02_FEATURE_SELECTION_REPORT_V4.txt')
report_fs.add_section('FEATURE SELECTION', level=1)
report_fs.add_content(f'Date: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
report_fs.add_content(f'')
report_fs.add_section('STAGE 1: DYNAMIC TEMPORAL RELEVANCE', level=2)
report_fs.add_content(f'Candidates: {len(dynamic_present)}')
report_fs.add_content(f'Threshold: ρ ≥ {RHO_LAG_THRESHOLD}')
report_fs.add_content(f'Selected: {len(dynamic_keep)}')
for d in dynamic_keep:
    report_fs.add_content(f'  {d}', indent=1)
report_fs.add_content(f'')
report_fs.add_section('DERIVED FEATURES', level=2)
report_fs.add_content(f'Created: {len(derived_features_created)}')
for d in derived_features_created:
    report_fs.add_content(f'  {d}', indent=1)
report_fs.add_content(f'')
report_fs.add_section('STAGE 2A: STATIC SPATIAL VARIANCE', level=2)
report_fs.add_content(f'Candidates: {len(static_present)}')
report_fs.add_content(f'Threshold: CV ≥ {CV_SPATIAL_THRESHOLD}')
report_fs.add_content(f'Selected: {len(static_2a_keep)}')
report_fs.add_content(f'')
report_fs.add_section('STAGE 2B: STATIC SPATIAL CORRELATION', level=2)
report_fs.add_content(f'Candidates: {len(static_2a_keep)}')
report_fs.add_content(f'Threshold: |ρ| ≥ {RHO_SPATIAL_THRESHOLD}')
report_fs.add_content(f'Selected: {len(static_2b_keep)}')
report_fs.add_content(f'')
report_fs.add_section('STAGE 3: MULTICOLLINEARITY REMOVAL', level=2)
report_fs.add_content(f'Candidates: {len(static_2b_keep)}')
report_fs.add_content(f'Threshold: |ρ| < {RHO_COLLINEARITY_THRESHOLD}')
report_fs.add_content(f'Pairwise correlations computed: {len(var_pairs)}')
report_fs.add_content(f'Final: {len(static_final)}')
for s in sorted(static_final)[:30]:
    report_fs.add_content(f'  {s}', indent=1)
if len(static_final) > 30:
    report_fs.add_content(f'  ... and {len(static_final) - 30} more', indent=1)
report_fs.save()
print(f"\n✓ Phase 3 report saved")

# =========================================================================
# PHASE 4: DATA PREPARATION & LSTM
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: DATA PREPARATION & LSTM TRAINING")
print("="*100)

# Clean data
def clean_numeric_frame(df):
    out = df.replace([np.inf, -np.inf], np.nan)
    for col in out.columns:
        if pd.api.types.is_numeric_dtype(out[col]):
            out[col] = out[col].fillna(out[col].median())
    return out

print("Preparing and scaling data...")

# Extract feature matrices
X_train_dyn = clean_numeric_frame(X_train[dynamic_keep_with_derived]).astype('float32')
X_test_dyn = clean_numeric_frame(X_test[dynamic_keep_with_derived]).astype('float32')

if len(static_final) > 0:
    X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32')
    X_test_sta = clean_numeric_frame(X_test[static_final]).astype('float32')
else:
    # Create dummy static features if none selected
    X_train_sta = pd.DataFrame(np.zeros((len(X_train), 1), dtype=np.float32))
    X_test_sta = pd.DataFrame(np.zeros((len(X_test), 1), dtype=np.float32))

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print(f"  Dynamic: {X_train_dyn.shape[1]} features")
print(f"  Static: {X_train_sta.shape[1]} features")
print(f"  Targets: {len(q_cols)} quantiles")

# Scale
print("Scaling with QuantileTransformer...")

qt_dyn = QuantileTransformer(n_quantiles=min(2000, X_train_dyn.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_sta = QuantileTransformer(n_quantiles=min(2000, X_train_sta.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))
qt_y = QuantileTransformer(n_quantiles=min(2000, Y_train_qdf.shape[0]), output_distribution='normal', random_state=RANDOM_STATE, subsample=int(1e9))

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')

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
    print("ERROR: No training sequences created! Check SEQ_LEN and data.")
    sys.exit(1)

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx] if len(te_last_idx) > 0 else np.zeros((0, len(q_cols)), dtype=np.float32)

# LSTM Model (SIMPLE VERSION)
print("\nDefining simple LSTM model...")

class SimpleLSTM(nn.Module):
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
        
        # Simple fusion with static features
        fusion_dim = hidden + n_sta
        self.fc = nn.Sequential(
            nn.Linear(fusion_dim, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        z = torch.cat([h_last, x_sta], dim=1)
        return self.fc(z)

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
train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = SimpleLSTM(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=len(q_cols)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

print(f"  Architecture: {n_dyn} dyn + {n_sta} sta → LSTM(128×2) → FC(128) → {len(q_cols)} quantiles")
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
best_train_loss = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, train=True)

    if tr_loss < best_train_loss:
        best_train_loss = tr_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == EPOCHS:
        print(f'  Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | best={best_train_loss:.5f}')

if best_state is not None:
    model.load_state_dict(best_state)

print(f"✓ Training complete. Best train loss: {best_train_loss:.5f}")

# Predictions
model.eval()
_, Ptr_s_all = run_epoch(train_loader, train=False)

if Xte_seq_dyn.shape[0] > 0:
    test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)
    test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False)
    _, Pte_s_all = run_epoch(test_loader, train=False)
else:
    Pte_s_all = np.zeros((0, len(q_cols)), dtype=np.float32)

Q_train_reconstructed = qt_y.inverse_transform(Ptr_s_all).astype('float32')
Q_test_reconstructed = qt_y.inverse_transform(Pte_s_all).astype('float32') if Pte_s_all.shape[0] > 0 else np.zeros((0, len(q_cols)), dtype=np.float32)

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
    if Y_true_np.shape[0] == 0:
        return {k: (np.nan, [np.nan] * len(q_cols)) for k in ['r', 'rho', 'mae', 'rmse', 'kge', 'nse']}
    
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
            for k in ['r', 'rho', 'mae', 'rmse', 'kge', 'nse']:
                metrics.setdefault(k, []).append(np.nan)
    
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

if Yte_true_seq.shape[0] > 0:
    print(f"\nTESTING METRICS:")
    print(f"  r:     {test_metrics['r'][0]:7.4f}")
    print(f"  ρ:     {test_metrics['rho'][0]:7.4f}")
    print(f"  NSE:   {test_metrics['nse'][0]:7.4f}")
    print(f"  KGE:   {test_metrics['kge'][0]:7.4f}")
    print(f"  RMSE:  {test_metrics['rmse'][0]:7.4f}")
    print(f"  MAE:   {test_metrics['mae'][0]:7.4f}")
else:
    print(f"\nTESTING: No test sequences available")

print(f"\nPER-QUANTILE TRAIN PERFORMANCE:")
quantile_perf_train = pd.DataFrame({
    'Quantile': q_cols,
    'r': train_metrics['r'][1],
    'ρ': train_metrics['rho'][1],
    'NSE': train_metrics['nse'][1],
    'KGE': train_metrics['kge'][1],
    'RMSE': train_metrics['rmse'][1],
    'MAE': train_metrics['mae'][1]
}).round(4)
print(quantile_perf_train.to_string(index=False))

if Yte_true_seq.shape[0] > 0:
    print(f"\nPER-QUANTILE TEST PERFORMANCE:")
    quantile_perf_test = pd.DataFrame({
        'Quantile': q_cols,
        'r': test_metrics['r'][1],
        'ρ': test_metrics['rho'][1],
        'NSE': test_metrics['nse'][1],
        'KGE': test_metrics['kge'][1],
        'RMSE': test_metrics['rmse'][1],
        'MAE': test_metrics['mae'][1]
    }).round(4)
    print(quantile_perf_test.to_string(index=False))

# Save LSTM report
report_lstm = Report('../predict_score_red/03_LSTM_TRAINING_REPORT_V4.txt')
report_lstm.add_section('LSTM MODEL TRAINING & EVALUATION', level=1)
report_lstm.add_section('Configuration', level=2)
report_lstm.add_content(f'Sequence length: {SEQ_LEN} months')
report_lstm.add_content(f'Dynamic features: {n_dyn}')
report_lstm.add_content(f'Static features: {n_sta}')
report_lstm.add_content(f'LSTM: 2 layers × 128 hidden (simple architecture)')
report_lstm.add_content(f'Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}')

report_lstm.add_section('Dataset', level=2)
report_lstm.add_content(f'Train sequences: {Xtr_seq_dyn.shape[0]:,}')
report_lstm.add_content(f'Test sequences: {Xte_seq_dyn.shape[0]:,}')

report_lstm.add_section('Training Results', level=2)
report_lstm.add_content(f'r={train_metrics["r"][0]:.4f}, ρ={train_metrics["rho"][0]:.4f}')
report_lstm.add_content(f'NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}')
report_lstm.add_content(f'RMSE={train_metrics["rmse"][0]:.4f}, MAE={train_metrics["mae"][0]:.4f}')

if Yte_true_seq.shape[0] > 0:
    report_lstm.add_section('Testing Results', level=2)
    report_lstm.add_content(f'r={test_metrics["r"][0]:.4f}, ρ={test_metrics["rho"][0]:.4f}')
    report_lstm.add_content(f'NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}')
    report_lstm.add_content(f'RMSE={test_metrics["rmse"][0]:.4f}, MAE={test_metrics["mae"][0]:.4f}')

report_lstm.add_section('Per-Quantile Training Performance', level=2)
report_lstm.add_dataframe(quantile_perf_train)

if Yte_true_seq.shape[0] > 0:
    report_lstm.add_section('Per-Quantile Testing Performance', level=2)
    report_lstm.add_dataframe(quantile_perf_test)

report_lstm.save()

# Save predictions
np.savetxt('../predict_prediction_red/LSTM_QQpredictTrain_V4.txt',
            Q_train_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

if Q_test_reconstructed.shape[0] > 0:
    np.savetxt('../predict_prediction_red/LSTM_QQpredictTest_V4.txt',
                Q_test_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

# Save selected features
with open('../predict_importance_red/LSTM_selected_features_V4.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_keep_with_derived:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

print(f"\n{'='*100}")
print("PIPELINE COMPLETE")
print(f"{'='*100}")
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Output files:")
print(f"  - Reports: ../predict_score_red/*_V4.txt")
print(f"  - Predictions: ../predict_prediction_red/LSTM_QQpredict*_V4.txt")
print(f"  - Features: ../predict_importance_red/LSTM_selected_features_V4.txt")
print(f"{'='*100}\n")

EOFPYTHON
exit
