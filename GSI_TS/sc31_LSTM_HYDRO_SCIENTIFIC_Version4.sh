#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 0:20:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_HYDRO_V4.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_HYDRO_V4.%A_%a.err
#SBATCH --job-name=sc31_LSTM_HYDRO_V4
#SBATCH --mem=5G

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
print("SC31: HYDROLOGICALLY-INFORMED LSTM PIPELINE v4")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

# Time-Series Split Parameters - RELAXED CONSTRAINTS
MIN_TRAIN_MONTHS = 24  # Reduced from 60
MAX_GAP_DAYS = 90      # Increased from 30
MIN_TRAIN_OBS = 100    # Reduced from 500

# Feature Selection Thresholds - RELAXED
RHO_LAG_THRESHOLD = 0.10          # Reduced from 0.15
CV_SPATIAL_THRESHOLD = 0.10        # Reduced from 0.20
RHO_SPATIAL_THRESHOLD = 0.10       # Reduced from 0.20
RHO_COLLINEARITY_THRESHOLD = 0.90  # Increased from 0.85
RHO_PROCESS_CORRELATION = 0.20     # Reduced from 0.30

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

# Minimum samples for QuantileTransformer
MIN_SAMPLES_FOR_SCALING = 100

# =========================================================================
# HYDROLOGICAL PROCESS GROUPS
# =========================================================================
HYDRO_PROCESS_GROUPS = {
    'CLIMATE_FORCING': {
        'vars': ['ppt0', 'ppt1', 'ppt2', 'ppt3', 
                'tmin0', 'tmin1', 'tmin2', 'tmin3',
                'tmax0', 'tmax1', 'tmax2', 'tmax3',
                'swe0', 'swe1', 'swe2', 'swe3'],
        'importance': 'critical',
        'temporal': True
    },
    'SOIL_MOISTURE': {
        'vars': ['soil0', 'soil1', 'soil2', 'soil3'],
        'importance': 'critical',
        'temporal': True
    },
    'TOPOGRAPHY_DRAINAGE': {
        'vars': ['accumulation', 'cti', 'spi', 'sti', 'slope', 'elev',
                'convergence', 'aspect-cosine', 'aspect-sine'],
        'importance': 'high',
        'temporal': False
    },
    'CHANNEL_GEOMETRY': {
        'vars': ['stream_dist_proximity', 'channel_dist_dw_seg', 'channel_elv_dw_seg',
                'channel_grad_dw_seg', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
                'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc'],
        'importance': 'high',
        'temporal': False
    },
    'STREAM_NETWORK': {
        'vars': ['order_strahler', 'order_shreve', 'order_horton', 'order_hack', 'order_topo'],
        'importance': 'medium',
        'temporal': False
    },
    'SOIL_PROPERTIES': {
        'vars': ['AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP'],
        'importance': 'medium',
        'temporal': False
    },
    'TERRAIN_ROUGHNESS': {
        'vars': ['tri', 'vrm', 'roughness', 'tpi', 'elev-stdev'],
        'importance': 'low',
        'temporal': False
    },
    'SURFACE_WATER': {
        'vars': ['GSWs', 'GSWr', 'GSWo', 'GSWe'],
        'importance': 'low',
        'temporal': False
    }
}

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
            f.write('HYDROLOGICALLY-INFORMED LSTM PIPELINE REPORT\n')
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
# PHASE 1: LOAD DATA & IDENTIFY VARIABLES
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: DATA LOADING & VARIABLE IDENTIFICATION")
print("="*100)

print("Loading data...")
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)

print(f"✓ X shape: {X.shape}, Y shape: {Y.shape}")

# Check for zero/missing discharge values
print("\nChecking discharge data quality...")
q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]
for qc in q_cols[:3]:  # Check first 3 quantiles
    n_zero = (Y[qc] == 0).sum()
    n_missing = Y[qc].isna().sum()
    pct_zero = 100 * n_zero / len(Y)
    pct_missing = 100 * n_missing / len(Y)
    print(f"  {qc}: {n_zero:,} zeros ({pct_zero:.1f}%), {n_missing:,} missing ({pct_missing:.1f}%)")

# Identify available variables by process group
print("\n" + "-"*100)
print("IDENTIFYING AVAILABLE VARIABLES BY HYDROLOGICAL PROCESS")
print("-"*100)

available_by_process = {}
all_dynamic_vars = []
all_static_vars = []

for process, config in HYDRO_PROCESS_GROUPS.items():
    available = [v for v in config['vars'] if v in X.columns]
    available_by_process[process] = available
    
    if config['temporal']:
        all_dynamic_vars.extend(available)
    else:
        all_static_vars.extend(available)
    
    print(f"\n{process} ({config['importance']} importance):")
    print(f"  Available: {len(available)}/{len(config['vars'])}")
    if len(available) > 0:
        print(f"  Variables: {', '.join(available[:5])}{' ...' if len(available) > 5 else ''}")

print(f"\n✓ Total dynamic variables: {len(all_dynamic_vars)}")
print(f"✓ Total static variables: {len(all_static_vars)}")
print(f"✓ Target quantiles: {len(q_cols)} - {', '.join(q_cols)}")

# Reset indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# =========================================================================
# PHASE 2: TEMPORAL CONTIGUITY & TRAIN/TEST SPLIT
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
contiguity_data = Parallel(n_jobs=NCPU)(
    delayed(analyze_contiguity)(group) for _, group in Y.groupby('IDr')
)
contiguity_df = pd.DataFrame(contiguity_data)

# Classify stations with RELAXED criteria
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

# CRITICAL: Check if we have sufficient training data
if len(train_idrs) == 0:
    print("\n" + "!"*100)
    print("ERROR: No training stations passed the temporal contiguity filters!")
    print("!"*100)
    print("\nSuggestions:")
    print("  1. Relax MIN_TRAIN_OBS (current: {})".format(MIN_TRAIN_OBS))
    print("  2. Increase MAX_GAP_DAYS (current: {})".format(MAX_GAP_DAYS))
    print("  3. Check data quality and temporal coverage")
    print("\nStation statistics:")
    print(contiguity_df.describe())
    sys.exit(1)

# Create splits
X_train = X[X['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_idrs)].copy().reset_index(drop=True)
X_test = X[X['IDr'].isin(test_idrs)].copy().reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_idrs)].copy().reset_index(drop=True)

print(f"\nDataset shapes:")
print(f"  Train: X {X_train.shape}, Y {Y_train.shape}")
print(f"  Test:  X {X_test.shape}, Y {Y_test.shape}")

# CRITICAL: Validate we have minimum samples
if X_train.shape[0] < MIN_SAMPLES_FOR_SCALING:
    print(f"\n⚠ WARNING: Only {X_train.shape[0]} training samples (minimum: {MIN_SAMPLES_FOR_SCALING})")
    print("Adjusting parameters for small sample size...")
    MIN_SAMPLES_FOR_SCALING = max(10, X_train.shape[0] // 10)

# =========================================================================
# PHASE 3: HYDROLOGICALLY-INFORMED FEATURE SELECTION
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: HYDROLOGICALLY-INFORMED FEATURE SELECTION")
print("="*100)

# Create derived features
print("\nCreating hydrologically-meaningful derived features...")
for df in [X_train, X_test]:
    if 'ppt0' in df.columns and 'accumulation' in df.columns:
        df['ppt0_area'] = df['ppt0'].astype('float32') / (df['accumulation'].astype('float32') + 1)
    if 'tmin0' in df.columns and 'accumulation' in df.columns:
        df['tmin0_area'] = df['tmin0'].astype('float32') / (df['accumulation'].astype('float32') + 1)
    if 'soil0' in df.columns and 'accumulation' in df.columns:
        df['soil0_area'] = df['soil0'].astype('float32') / (df['accumulation'].astype('float32') + 1)
    if 'GRWLw' in df.columns and 'accumulation' in df.columns:
        df['GRWLw_area'] = df['GRWLw'].astype('float32') / (df['accumulation'].astype('float32') + 1)
    if 'ppt0' in df.columns and 'elev' in df.columns:
        df['ppt0_elev'] = df['ppt0'].astype('float32') * df['elev'].astype('float32') / 1000.0

# Add derived features to dynamic vars
derived_features = ['ppt0_area', 'tmin0_area', 'soil0_area', 'GRWLw_area', 'ppt0_elev']
all_dynamic_vars.extend([v for v in derived_features if v in X_train.columns])

print(f"✓ Created {len([v for v in derived_features if v in X_train.columns])} derived features")

# STAGE 1: DYNAMIC VARIABLES - TEMPORAL RELEVANCE
print("\n" + "-"*100)
print("STAGE 1: Dynamic Variables - Temporal Relevance (Lagged Correlation)")
print("-"*100)

def compute_lag_correlation(d_var, max_lag=4):
    """Compute maximum lagged correlation between dynamic var and discharge quantiles"""
    results = []
    
    # Check if variable exists and has variance
    if d_var not in X_train.columns:
        return results
    
    var_vals = X_train[d_var].values
    if np.std(var_vals[~np.isnan(var_vals)]) < 1e-10:
        return results
    
    for q_var in q_cols[:3]:  # Use first 3 quantiles for speed
        max_rho = -np.inf
        best_lag = -1
        
        for lag in range(max_lag):
            try:
                # Create lagged version
                d_vals_lagged = X_train.groupby('IDr')[d_var].shift(lag).values
                q_vals = Y_train[q_var].values
                
                # Remove NaN and inf
                mask = ~(np.isnan(d_vals_lagged) | np.isnan(q_vals) | 
                        np.isinf(d_vals_lagged) | np.isinf(q_vals))
                
                if np.sum(mask) > 50:
                    rho, pval = spearmanr(d_vals_lagged[mask], q_vals[mask])
                    if not np.isnan(rho) and abs(rho) > abs(max_rho):
                        max_rho = rho
                        best_lag = lag
            except:
                pass
        
        if max_rho > -np.inf:
            results.append({
                'variable': d_var,
                'quantile': q_var,
                'rho_max': abs(max_rho),
                'best_lag': best_lag
            })
    
    return results

print(f"Computing lagged correlations for {len(all_dynamic_vars)} dynamic variables...")
dynamic_lag_results = Parallel(n_jobs=NCPU)(
    delayed(compute_lag_correlation)(var) for var in all_dynamic_vars
)

# Flatten results
dynamic_lag_flat = [item for sublist in dynamic_lag_results for item in sublist]
dynamic_lag_df = pd.DataFrame(dynamic_lag_flat)

if len(dynamic_lag_df) > 0:
    # Aggregate by variable
    dynamic_summary = dynamic_lag_df.groupby('variable').agg({
        'rho_max': ['mean', 'max', 'min'],
        'best_lag': 'mean'
    }).reset_index()
    
    dynamic_summary.columns = ['variable', 'rho_mean', 'rho_max', 'rho_min', 'avg_lag']
    dynamic_summary = dynamic_summary.sort_values('rho_mean', ascending=False)
    
    # Select based on threshold
    dynamic_selected = dynamic_summary[dynamic_summary['rho_mean'] >= RHO_LAG_THRESHOLD]['variable'].tolist()
    
    # Ensure we have at least some dynamic variables
    if len(dynamic_selected) < 5 and len(dynamic_summary) >= 5:
        print(f"⚠ Only {len(dynamic_selected)} dynamic vars passed threshold, selecting top 5")
        dynamic_selected = dynamic_summary.head(5)['variable'].tolist()
    
    print(f"\n✓ SELECTED {len(dynamic_selected)} dynamic variables:")
    for var in dynamic_selected[:10]:
        row = dynamic_summary[dynamic_summary['variable'] == var].iloc[0]
        print(f"  {var:20s} | ρ_mean={row['rho_mean']:.3f}, ρ_max={row['rho_max']:.3f}, avg_lag={row['avg_lag']:.1f}")
else:
    # Fallback: use all available dynamic vars
    dynamic_selected = [v for v in all_dynamic_vars if v in X_train.columns][:10]
    print(f"⚠ No correlations computed, using first {len(dynamic_selected)} dynamic variables")

# STAGE 2: STATIC VARIABLES - SPATIAL VARIABILITY
print("\n" + "-"*100)
print("STAGE 2: Static Variables - Spatial Variability (CV across stations)")
print("-"*100)

# Get station-level static data
station_static = X_train.drop_duplicates(subset=['IDr'])[['IDr'] + all_static_vars].set_index('IDr')
station_static_clean = station_static.fillna(station_static.median())

def compute_cv_robust(var):
    """Compute coefficient of variation with robust statistics"""
    if var not in station_static_clean.columns:
        return {'variable': var, 'CV': 0, 'n_valid': 0}
    
    vals = station_static_clean[var].values
    vals = vals[~(np.isnan(vals) | np.isinf(vals))]
    
    if len(vals) < 10:
        return {'variable': var, 'CV': 0, 'n_valid': len(vals)}
    
    # Use median absolute deviation for robustness
    median = np.median(vals)
    mad = np.median(np.abs(vals - median))
    cv = mad / (abs(median) + 1e-10)
    
    return {'variable': var, 'CV': cv, 'n_valid': len(vals)}

cv_results = Parallel(n_jobs=NCPU)(
    delayed(compute_cv_robust)(var) for var in all_static_vars
)
cv_df = pd.DataFrame(cv_results).sort_values('CV', ascending=False)

static_cv_selected = cv_df[cv_df['CV'] >= CV_SPATIAL_THRESHOLD]['variable'].tolist()

# Ensure minimum static variables
if len(static_cv_selected) < 5 and len(cv_df) >= 5:
    print(f"⚠ Only {len(static_cv_selected)} static vars passed CV threshold, selecting top 10")
    static_cv_selected = cv_df.head(10)['variable'].tolist()

print(f"\n✓ SELECTED {len(static_cv_selected)} static variables (CV >= {CV_SPATIAL_THRESHOLD}):")
for _, row in cv_df[cv_df['variable'].isin(static_cv_selected)].head(15).iterrows():
    print(f"  {row['variable']:30s} | CV={row['CV']:.3f}, n={row['n_valid']}")

# STAGE 3: STATIC VARIABLES - SPATIAL CORRELATION WITH DISCHARGE
print("\n" + "-"*100)
print("STAGE 3: Static Variables - Spatial Correlation with Discharge")
print("-"*100)

# Get station-level discharge statistics
station_q_stats = Y_train.groupby('IDr')[q_cols].median()

def compute_spatial_correlation(var):
    """Compute spatial correlation between static var and discharge quantiles"""
    results = []
    
    try:
        if var not in station_static_clean.columns:
            return results
        
        s_vals = station_static_clean[var].values
        
        for q_var in ['QMIN', 'Q50', 'QMAX']:
            if q_var in station_q_stats.columns:
                q_vals = station_q_stats[q_var].values
                
                # Align by index
                common_idx = station_static_clean.index.intersection(station_q_stats.index)
                if len(common_idx) < 10:
                    continue
                
                s_vals_aligned = station_static_clean.loc[common_idx, var].values
                q_vals_aligned = station_q_stats.loc[common_idx, q_var].values
                
                mask = ~(np.isnan(s_vals_aligned) | np.isnan(q_vals_aligned) | 
                         np.isinf(s_vals_aligned) | np.isinf(q_vals_aligned))
                
                if np.sum(mask) > 10:
                    rho, pval = spearmanr(s_vals_aligned[mask], q_vals_aligned[mask])
                    if not np.isnan(rho):
                        results.append({
                            'variable': var,
                            'quantile': q_var,
                            'rho': abs(rho)
                        })
    except Exception as e:
        pass
    
    return results

spatial_corr_results = Parallel(n_jobs=NCPU)(
    delayed(compute_spatial_correlation)(var) for var in static_cv_selected
)

# Flatten results
spatial_corr_flat = [item for sublist in spatial_corr_results for item in sublist]
spatial_corr_df = pd.DataFrame(spatial_corr_flat)

if len(spatial_corr_df) > 0:
    # Aggregate by variable
    spatial_summary = spatial_corr_df.groupby('variable')['rho'].agg(['mean', 'max', 'min']).reset_index()
    spatial_summary = spatial_summary.sort_values('mean', ascending=False)
    
    static_corr_selected = spatial_summary[spatial_summary['mean'] >= RHO_SPATIAL_THRESHOLD]['variable'].tolist()
    
    # Ensure minimum
    if len(static_corr_selected) < 5 and len(spatial_summary) >= 5:
        print(f"⚠ Only {len(static_corr_selected)} passed correlation threshold, selecting top 10")
        static_corr_selected = spatial_summary.head(10)['variable'].tolist()
    
    print(f"\n✓ SELECTED {len(static_corr_selected)} static variables:")
    for _, row in spatial_summary[spatial_summary['variable'].isin(static_corr_selected)].head(15).iterrows():
        print(f"  {row['variable']:30s} | ρ_mean={row['mean']:.3f}, ρ_max={row['max']:.3f}")
else:
    static_corr_selected = static_cv_selected
    print(f"⚠ No spatial correlations computed, using CV-selected: {len(static_corr_selected)}")

# STAGE 4: MULTICOLLINEARITY WITHIN PROCESS GROUPS
print("\n" + "-"*100)
print("STAGE 4: Multicollinearity Removal (within process groups)")
print("-"*100)

static_final = []

for process, config in HYDRO_PROCESS_GROUPS.items():
    if config['temporal']:
        continue  # Skip dynamic variables
    
    # Get variables from this process that passed previous filters
    process_vars = [v for v in config['vars'] if v in static_corr_selected]
    
    if len(process_vars) == 0:
        continue
    
    print(f"\n{process}: {len(process_vars)} candidates")
    
    # Compute pairwise correlations within process group
    pairwise_corr = {}
    for i, var1 in enumerate(process_vars):
        for j, var2 in enumerate(process_vars):
            if i < j and var1 in station_static_clean.columns and var2 in station_static_clean.columns:
                try:
                    v1 = station_static_clean[var1].values
                    v2 = station_static_clean[var2].values
                    mask = ~(np.isnan(v1) | np.isnan(v2) | np.isinf(v1) | np.isinf(v2))
                    
                    if np.sum(mask) > 10:
                        rho, _ = spearmanr(v1[mask], v2[mask])
                        if not np.isnan(rho) and abs(rho) > RHO_COLLINEARITY_THRESHOLD:
                            pairwise_corr[(var1, var2)] = abs(rho)
                except:
                    pass
    
    # Remove redundant variables (keep the one with higher CV)
    cv_dict = dict(zip(cv_df['variable'], cv_df['CV']))
    removed_in_process = set()
    
    for (var1, var2), corr in sorted(pairwise_corr.items(), key=lambda x: x[1], reverse=True):
        if var1 not in removed_in_process and var2 not in removed_in_process:
            # Keep variable with higher spatial variability
            if cv_dict.get(var1, 0) > cv_dict.get(var2, 0):
                removed_in_process.add(var2)
                print(f"  Removing {var2} (collinear with {var1}, ρ={corr:.3f})")
            else:
                removed_in_process.add(var1)
                print(f"  Removing {var1} (collinear with {var2}, ρ={corr:.3f})")
    
    # Add non-removed variables
    kept_vars = [v for v in process_vars if v not in removed_in_process]
    static_final.extend(kept_vars)
    print(f"  ✓ Kept {len(kept_vars)} variables from {process}")

# Ensure minimum features
if len(static_final) < 3:
    print("\n⚠ WARNING: Very few static variables selected, adding top CV vars")
    static_final = cv_df.head(10)['variable'].tolist()

if len(dynamic_selected) < 3:
    print("⚠ WARNING: Very few dynamic variables selected, using all available")
    dynamic_selected = [v for v in all_dynamic_vars if v in X_train.columns][:15]

print(f"\n{'='*60}")
print("FINAL FEATURE SELECTION SUMMARY")
print(f"{'='*60}")
print(f"Dynamic variables: {len(dynamic_selected)}")
for v in dynamic_selected[:10]:
    print(f"  • {v}")
if len(dynamic_selected) > 10:
    print(f"  ... and {len(dynamic_selected) - 10} more")

print(f"\nStatic variables: {len(static_final)}")
for v in sorted(static_final)[:10]:
    print(f"  • {v}")
if len(static_final) > 10:
    print(f"  ... and {len(static_final) - 10} more")

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

X_train_dyn = clean_numeric_frame(X_train[dynamic_selected]).astype('float32')
X_test_dyn = clean_numeric_frame(X_test[dynamic_selected]).astype('float32')

X_train_sta = clean_numeric_frame(X_train[static_final]).astype('float32')
X_test_sta = clean_numeric_frame(X_test[static_final]).astype('float32')

Y_train_qdf = clean_numeric_frame(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_numeric_frame(Y_test[q_cols]).astype('float32')

print(f"  Dynamic: {X_train_dyn.shape[1]} features, {X_train_dyn.shape[0]} samples")
print(f"  Static: {X_train_sta.shape[1]} features, {X_train_sta.shape[0]} samples")
print(f"  Targets: {len(q_cols)} quantiles, {Y_train_qdf.shape[0]} samples")

# CRITICAL: Check sample size before scaling
if X_train_dyn.shape[0] < MIN_SAMPLES_FOR_SCALING:
    print(f"\n⚠ ERROR: Insufficient training samples ({X_train_dyn.shape[0]} < {MIN_SAMPLES_FOR_SCALING})")
    print("Cannot proceed with QuantileTransformer. Suggestions:")
    print("  1. Relax temporal contiguity constraints")
    print("  2. Use StandardScaler instead")
    print("  3. Increase data coverage")
    sys.exit(1)

# Scale with safe n_quantiles
print("Scaling with QuantileTransformer...")

n_quantiles_dyn = min(1000, max(10, X_train_dyn.shape[0]))
n_quantiles_sta = min(1000, max(10, X_train_sta.shape[0]))
n_quantiles_y = min(1000, max(10, Y_train_qdf.shape[0]))

print(f"  n_quantiles: dyn={n_quantiles_dyn}, sta={n_quantiles_sta}, y={n_quantiles_y}")

qt_dyn = QuantileTransformer(
    n_quantiles=n_quantiles_dyn,
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)

qt_sta = QuantileTransformer(
    n_quantiles=n_quantiles_sta,
    output_distribution='normal',
    random_state=RANDOM_STATE,
    subsample=int(1e9)
)

qt_y = QuantileTransformer(
    n_quantiles=n_quantiles_y,
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

X_train['ROWID'] = np.arange(X_train.shape[0], dtype=np.int64)
X_test['ROWID'] = np.arange(X_test.shape[0], dtype=np.int64)

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']].copy()
Xte_meta = X_test[['IDr', 'YYYY', 'MM']].copy()

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_last_idx = build_sequences(Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_last_idx = build_sequences(Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s)

print(f"  Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"  Test sequences: {Xte_seq_dyn.shape[0]:,}")

if Xtr_seq_dyn.shape[0] == 0:
    print("\n⚠ ERROR: No training sequences created (all stations have < SEQ_LEN observations)")
    print(f"Consider reducing SEQ_LEN (current: {SEQ_LEN})")
    sys.exit(1)

Ytr_true_seq = Y_train_qdf.to_numpy(dtype=np.float32)[tr_last_idx]
Yte_true_seq = Y_test_qdf.to_numpy(dtype=np.float32)[te_last_idx] if len(te_last_idx) > 0 else np.zeros((0, len(q_cols)), dtype=np.float32)

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
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq) if Xte_seq_dyn.shape[0] > 0 else None

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0, drop_last=False)
test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0, drop_last=False) if test_ds is not None else None

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = LSTMWithContext(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=len(q_cols)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

print(f"  Architecture: {n_dyn} dyn + {n_sta} sta → 128 LSTM × 2 → 256 → {len(q_cols)} quantiles")
print(f"  Device: {DEVICE}, Epochs: {EPOCHS}, Batch: {BATCH_SIZE}, LR: {LR}")

# Training
def run_epoch(loader, train=True):
    if loader is None:
        return np.nan, np.zeros((0, len(q_cols)), dtype=np.float32)
    
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
    te_loss, _ = run_epoch(test_loader, train=False) if test_loader is not None else (np.nan, None)

    if test_loader is not None and te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == EPOCHS:
        if test_loader is not None:
            print(f'  Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | test_loss={te_loss:.5f} | best={best_val:.5f}')
        else:
            print(f'  Epoch {ep:3d}/{EPOCHS} | train_loss={tr_loss:.5f} | (no test data)')

if best_state is not None:
    model.load_state_dict(best_state)

print(f"✓ Training complete. Best test loss: {best_val:.5f}" if test_loader is not None else "✓ Training complete (no test data)")

# Predictions
_, Ptr_s_all = run_epoch(train_loader, train=False)
_, Pte_s_all = run_epoch(test_loader, train=False) if test_loader is not None else (None, np.zeros((0, len(q_cols)), dtype=np.float32))

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
            metrics.setdefault('r', []).append(np.nan)
            metrics.setdefault('rho', []).append(np.nan)
            metrics.setdefault('mae', []).append(np.nan)
            metrics.setdefault('rmse', []).append(np.nan)
            metrics.setdefault('kge', []).append(np.nan)
            metrics.setdefault('nse', []).append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true_seq, Q_train_reconstructed)
test_metrics = compute_metrics(Yte_true_seq, Q_test_reconstructed) if Yte_true_seq.shape[0] > 0 else {k: (np.nan, [np.nan] * len(q_cols)) for k in ['r', 'rho', 'mae', 'rmse', 'kge', 'nse']}

# Console Output
print(f"\n{'='*100}")
print("FINAL RESULTS")
print(f"{'='*100}")
print(f"\nTRAINING METRICS ({Ytr_true_seq.shape[0]} sequences):")
print(f"  r:     {train_metrics['r'][0]:7.4f}")
print(f"  ρ:     {train_metrics['rho'][0]:7.4f}")
print(f"  NSE:   {train_metrics['nse'][0]:7.4f}")
print(f"  KGE:   {train_metrics['kge'][0]:7.4f}")
print(f"  RMSE:  {train_metrics['rmse'][0]:7.4f}")
print(f"  MAE:   {train_metrics['mae'][0]:7.4f}")

if Yte_true_seq.shape[0] > 0:
    print(f"\nTESTING METRICS ({Yte_true_seq.shape[0]} sequences):")
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
else:
    print("\n(No test data available)")

# Save outputs
print(f"\n{'='*100}")
print("SAVING OUTPUTS")
print(f"{'='*100}")

# Save predictions
np.savetxt('../predict_prediction_red/LSTM_QQpredictTrain_hydro_v4.txt',
            Q_train_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')
if Q_test_reconstructed.shape[0] > 0:
    np.savetxt('../predict_prediction_red/LSTM_QQpredictTest_hydro_v4.txt',
                Q_test_reconstructed, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

# Save features
with open('../predict_importance_red/LSTM_selected_features_hydro_v4.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for d in dynamic_selected:
        f.write(f'{d}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')

# Save detailed report
report = Report('../predict_score_red/LSTM_HYDRO_REPORT_v4.txt')
report.add_section('HYDROLOGICALLY-INFORMED LSTM PIPELINE', level=1)
report.add_content(f'Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
report.add_content(f'Total stations: {len(contiguity_df)}')
report.add_content(f'Training: {len(train_idrs)} stations, {Ytr_true_seq.shape[0]} sequences')
report.add_content(f'Testing: {len(test_idrs)} stations, {Yte_true_seq.shape[0]} sequences')

report.add_section('FEATURE SELECTION SUMMARY', level=2)
report.add_content(f'Dynamic variables selected: {len(dynamic_selected)}')
report.add_content(f'Static variables selected: {len(static_final)}')
report.add_content(f'Total features: {len(dynamic_selected) + len(static_final)}')

if len(dynamic_lag_df) > 0:
    report.add_section('Dynamic Variables - Lagged Correlations', level=3)
    if 'dynamic_summary' in locals():
        report.add_dataframe(dynamic_summary)

report.add_section('Static Variables - Spatial Variability', level=3)
report.add_dataframe(cv_df.head(30))

if len(spatial_corr_df) > 0:
    report.add_section('Static Variables - Spatial Correlations', level=3)
    if 'spatial_summary' in locals():
        report.add_dataframe(spatial_summary.head(30))

report.add_section('LSTM MODEL RESULTS', level=2)
report.add_content(f'Training: r={train_metrics["r"][0]:.4f}, NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}')
if Yte_true_seq.shape[0] > 0:
    report.add_content(f'Testing:  r={test_metrics["r"][0]:.4f}, NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}')

if Yte_true_seq.shape[0] > 0:
    report.add_section('Per-Quantile Performance', level=3)
    report.add_dataframe(quantile_perf)

report.save()

print(f"✓ Predictions saved")
print(f"✓ Features saved")
print(f"✓ Report saved")

print(f"\n{'='*100}")
print("PIPELINE COMPLETE")
print(f"{'='*100}")
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"{'='*100}\n")

EOFPYTHON
exit
