#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_HYDRO_SCI.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_HYDRO_SCI.%A_%a.err
#SBATCH --job-name=sc31_LSTM_HYDRO_SCI
#SBATCH --mem=120G

##### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/GSI_TS/sc31_LSTM_HYDRO_SCIENTIFIC_Version2.sh 

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

# Thread control to prevent CPU oversubscription
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

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
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("HYDROLOGICAL LSTM MODELING WITH SPATIO-TEMPORAL VARIABLE SELECTION")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

# =========================================================================
# CONFIGURATION - HYDROLOGICALLY MOTIVATED
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))
print(f"Available CPUs: {NCPU}")

# Temporal Split Criteria (Based on Hydrological Requirements)
MIN_TRAIN_YEARS = 11                    # 11 years for training
MIN_TEST_YEARS = 11                     # 11 years for testing
MIN_TRAIN_MONTHS = MIN_TRAIN_YEARS * 12 # 132 months
MIN_TEST_MONTHS = MIN_TEST_YEARS * 12   # 132 months

# Feature Selection Thresholds
# Static variables: spatial correlation (between-station) and temporal influence (within-station)
RHO_SPATIAL_THRESHOLD = 0.15      # Minimum Spearman correlation for spatial patterns
RHO_TEMPORAL_THRESHOLD = 0.10     # Minimum correlation for temporal influence
RHO_COLLINEARITY_THRESHOLD = 0.85 # Remove highly correlated static variables

# Dynamic variables: temporal relevance with lag analysis
RHO_DYNAMIC_THRESHOLD = 0.15      # Minimum lag correlation for dynamic variables

# LSTM Parameters
SEQ_LEN = 12              # 12-month sequences (capture annual cycle)
BATCH_SIZE = 256
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

print(f"\nHydrological Modeling Configuration:")
print(f"  - Training stations: ≥{MIN_TRAIN_YEARS} years ({MIN_TRAIN_MONTHS} months)")
print(f"  - Testing stations: <{MIN_TRAIN_YEARS} years")
print(f"  - LSTM sequence length: {SEQ_LEN} months (annual cycle)")
print(f"  - Flow quantiles: QMIN, Q10-Q90 (10% steps), QMAX")

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
            f.write('HYDROLOGICAL LSTM MODELING REPORT\n')
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
# PHASE 1: DATA LOADING
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: DATA LOADING & VALIDATION")
print("="*100)

print("Loading data...")
try:
    X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
    Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)
    print(f"✓ X shape: {X.shape}, Y shape: {Y.shape}")
except Exception as e:
    print(f"ERROR loading data: {e}")
    sys.exit(1)

# Verify required columns
required_cols = ['IDr', 'YYYY', 'MM']
missing_X = [c for c in required_cols if c not in X.columns]
missing_Y = [c for c in required_cols if c not in Y.columns]

if missing_X or missing_Y:
    print(f"ERROR: Missing required columns!")
    if missing_X: print(f"  X missing: {missing_X}")
    if missing_Y: print(f"  Y missing: {missing_Y}")
    sys.exit(1)

print(f"\nData loaded successfully:")
print(f"  - Unique stations: {X['IDr'].nunique()}")
print(f"  - Time range: {X['YYYY'].min()}-{X['YYYY'].max()}")
print(f"  - Total observations: {len(X):,}")

# =========================================================================
# DEFINE VARIABLE CATEGORIES BASED ON HYDROLOGICAL THEORY
# =========================================================================
print("\n" + "="*100)
print("HYDROLOGICAL VARIABLE CLASSIFICATION")
print("="*100)

# STATIC VARIABLES - Control spatial patterns of flow regime
# Topography: drainage area, elevation, slope, aspect
# Channel network: stream order, distance metrics
# Soil properties: texture, water holding capacity
# Land surface: roughness, curvature
# Water bodies: river/lake proximity and characteristics

static_candidates = [
    # Topographic indices
    'cti', 'spi', 'sti', 'accumulation',
    'elev', 'slope', 'aspect-cosine', 'aspect-sine',
    'convergence', 'eastness', 'northness',
    'pcurv', 'tcurv', 'tpi', 'tri', 'vrm',
    
    # Terrain derivatives
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'dev-magnitude', 'dev-scale',
    'elev-stdev', 'rough-magnitude', 'roughness', 'rough-scale',
    
    # Outlet/catchment metrics
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    
    # Stream network metrics
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    
    # Slope/channel elevation gradients
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel',
    
    # Channel characteristics
    'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
    'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    
    # Stream order
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    
    # Soil properties
    'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    
    # Water body characteristics (GRWL = Global River Widths from Landsat)
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    
    # Surface water (GSW = Global Surface Water)
    'GSWs', 'GSWr', 'GSWo', 'GSWe'
]

# DYNAMIC VARIABLES - Control temporal variations in flow
# Precipitation: direct runoff generation (lag 0-3 months)
# Temperature: snowmelt, evapotranspiration (lag 0-3 months)
# Snow water equivalent: delayed snowmelt contribution
# Soil moisture: antecedent wetness conditions

dynamic_candidates = [
    # Precipitation (mm) - lag 0 to 3 months
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    
    # Minimum temperature (°C) - controls snowmelt, baseflow
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    
    # Maximum temperature (°C) - controls evapotranspiration
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    
    # Snow water equivalent (mm) - delayed snowmelt
    'swe0', 'swe1', 'swe2', 'swe3',
    
    # Soil moisture (mm) - antecedent wetness
    'soil0', 'soil1', 'soil2', 'soil3'
]

# Filter to available columns
static_var = [v for v in static_candidates if v in X.columns]
dynamic_var = [v for v in dynamic_candidates if v in X.columns]

print(f"\n✓ STATIC variables (control spatial patterns): {len(static_var)}")
print(f"  Categories: topography, channel network, soil, water bodies")
print(f"  Available: {', '.join(static_var[:15])}..." if len(static_var) > 15 else f"  Available: {', '.join(static_var)}")

print(f"\n✓ DYNAMIC variables (control temporal variations): {len(dynamic_var)}")
print(f"  Categories: precipitation, temperature, snow, soil moisture")
print(f"  Available: {', '.join(dynamic_var)}")

# Target quantiles - Flow Duration Curve
q_cols = [col for col in Y.columns if col.startswith('Q')]
if len(q_cols) == 0:
    q_cols = [col for col in Y.columns if any(x in col for x in ['QMIN', 'QMAX'])]

print(f"\n✓ TARGET: Flow quantiles (Flow Duration Curve): {len(q_cols)}")
print(f"  {', '.join(q_cols)}")

if len(q_cols) == 0:
    print("ERROR: No flow quantile columns found!")
    sys.exit(1)

# Reset indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# =========================================================================
# PHASE 2: TEMPORAL-LENGTH BASED TRAIN/TEST SPLIT
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: TRAIN/TEST SPLIT BASED ON TEMPORAL DATA LENGTH")
print("="*100)

# Count observations per station
station_counts = Y.groupby('IDr').size().reset_index(name='n_obs')
station_counts['n_years'] = station_counts['n_obs'] / 12

# Classify stations by data length
train_stations = station_counts[station_counts['n_obs'] >= MIN_TRAIN_MONTHS]['IDr'].tolist()
test_stations = station_counts[station_counts['n_obs'] < MIN_TRAIN_MONTHS]['IDr'].tolist()

print(f"\n✓ Station classification by data length:")
print(f"  TRAINING: {len(train_stations)} stations with ≥{MIN_TRAIN_YEARS} years ({MIN_TRAIN_MONTHS} months)")
print(f"    - Mean observations: {station_counts[station_counts['IDr'].isin(train_stations)]['n_obs'].mean():.0f} months")
print(f"    - Min observations: {station_counts[station_counts['IDr'].isin(train_stations)]['n_obs'].min():.0f} months")
print(f"    - Max observations: {station_counts[station_counts['IDr'].isin(train_stations)]['n_obs'].max():.0f} months")

print(f"\n  TESTING: {len(test_stations)} stations with <{MIN_TRAIN_YEARS} years")
if len(test_stations) > 0:
    print(f"    - Mean observations: {station_counts[station_counts['IDr'].isin(test_stations)]['n_obs'].mean():.0f} months")
    print(f"    - Min observations: {station_counts[station_counts['IDr'].isin(test_stations)]['n_obs'].min():.0f} months")
    print(f"    - Max observations: {station_counts[station_counts['IDr'].isin(test_stations)]['n_obs'].max():.0f} months")

if len(train_stations) == 0:
    print("\nERROR: No stations meet training criteria!")
    print(f"Distribution of station lengths:")
    print(station_counts['n_years'].describe())
    sys.exit(1)

# Create train/test datasets
X_train = X[X['IDr'].isin(train_stations)].copy().reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_stations)].copy().reset_index(drop=True)
X_test = X[X['IDr'].isin(test_stations)].copy().reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_stations)].copy().reset_index(drop=True)

print(f"\n✓ Dataset shapes:")
print(f"  Train: X={X_train.shape}, Y={Y_train.shape}")
print(f"  Test:  X={X_test.shape}, Y={Y_test.shape}")

# =========================================================================
# PHASE 3: HYDROLOGICALLY-MOTIVATED VARIABLE SELECTION
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: SPATIO-TEMPORAL VARIABLE SELECTION")
print("="*100)

# -------------------------------------------------------------------------
# 3A: DYNAMIC VARIABLES - Temporal Relevance with Lag Analysis
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3A: DYNAMIC VARIABLES - Temporal Lag Correlation Analysis")
print("-"*100)
print("Theory: Dynamic variables (precip, temp, etc.) influence flow with time lags")
print("Method: Compute Spearman correlation at lags 0-3 months, keep best lag")

dynamic_present = [v for v in dynamic_var if v in X_train.columns]

if len(dynamic_present) == 0:
    print("WARNING: No dynamic variables available!")
    dynamic_selected = []
else:
    def compute_dynamic_lag_correlation(dyn_var):
        """Compute best lag correlation for a dynamic variable"""
        results = []
        for q_var in q_cols:
            max_rho = 0
            best_lag = -1
            
            for lag in range(4):  # Test lags 0-3 months
                try:
                    # Get dynamic variable values with lag
                    dyn_vals = X_train[dyn_var].shift(lag).values
                    q_vals = Y_train[q_var].values
                    
                    # Remove NaN
                    mask = ~(np.isnan(dyn_vals) | np.isnan(q_vals))
                    if np.sum(mask) > 100:
                        rho, pval = spearmanr(dyn_vals[mask], q_vals[mask])
                        if not np.isnan(rho) and abs(rho) > abs(max_rho):
                            max_rho = rho
                            best_lag = lag
                except:
                    pass
            
            if abs(max_rho) > 0:
                results.append({
                    'Variable': dyn_var,
                    'Target': q_var,
                    'ρ': max_rho,
                    'abs_ρ': abs(max_rho),
                    'best_lag': best_lag
                })
        
        return results
    
    print(f"Computing lag correlations for {len(dynamic_present)} dynamic variables...")
    all_dynamic_results = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
        delayed(compute_dynamic_lag_correlation)(var) for var in dynamic_present
    )
    
    # Flatten results
    dynamic_results = [item for sublist in all_dynamic_results for item in sublist]
    
    if len(dynamic_results) > 0:
        dynamic_df = pd.DataFrame(dynamic_results)
        
        # Aggregate across quantiles: keep variable if it correlates well with ANY quantile
        dynamic_summary = dynamic_df.groupby('Variable').agg({
            'abs_ρ': ['mean', 'max'],
            'best_lag': lambda x: x.mode()[0] if len(x) > 0 else 0
        }).reset_index()
        dynamic_summary.columns = ['Variable', 'mean_abs_ρ', 'max_abs_ρ', 'typical_lag']
        dynamic_summary = dynamic_summary.sort_values('max_abs_ρ', ascending=False)
        
        # Select variables exceeding threshold
        dynamic_selected = dynamic_summary[
            dynamic_summary['max_abs_ρ'] >= RHO_DYNAMIC_THRESHOLD
        ]['Variable'].tolist()
        
        print(f"\n✓ Dynamic variable selection results:")
        print(f"  Threshold: |ρ| ≥ {RHO_DYNAMIC_THRESHOLD}")
        print(f"  Selected: {len(dynamic_selected)}/{len(dynamic_present)}")
        print(f"\n  Top variables by max correlation:")
        print(dynamic_summary.head(10).to_string(index=False))
    else:
        print("WARNING: No dynamic correlations computed!")
        dynamic_selected = []

# -------------------------------------------------------------------------
# 3B: STATIC VARIABLES - Spatial Correlation (Between-Station)
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3B: STATIC VARIABLES - Spatial Correlation Analysis")
print("-"*100)
print("Theory: Static variables control spatial patterns in flow regime")
print("Method: Aggregate by station (IDr), correlate with mean flow quantiles")

static_present = [v for v in static_var if v in X_train.columns]

if len(static_present) == 0:
    print("WARNING: No static variables available!")
    static_spatial_selected = []
else:
    # Aggregate static variables by station (they should be constant within IDr)
    station_static = X_train.groupby('IDr')[static_present].first()
    
    # Aggregate flow quantiles by station (mean over time)
    station_flow = Y_train.groupby('IDr')[q_cols].mean()
    
    # Ensure same stations
    common_stations = station_static.index.intersection(station_flow.index)
    station_static = station_static.loc[common_stations]
    station_flow = station_flow.loc[common_stations]
    
    print(f"  Analyzing {len(common_stations)} stations")
    
    def compute_spatial_correlation(stat_var):
        """Compute spatial (between-station) correlation"""
        results = []
        try:
            stat_vals = station_static[stat_var].values
            
            for q_var in q_cols:
                q_vals = station_flow[q_var].values
                
                # Remove NaN
                mask = ~(np.isnan(stat_vals) | np.isnan(q_vals))
                if np.sum(mask) > 10:
                    rho, pval = spearmanr(stat_vals[mask], q_vals[mask])
                    if not np.isnan(rho):
                        results.append({
                            'Variable': stat_var,
                            'Target': q_var,
                            'ρ': rho,
                            'abs_ρ': abs(rho),
                            'p_value': pval
                        })
        except:
            pass
        return results
    
    print(f"Computing spatial correlations for {len(static_present)} static variables...")
    all_spatial_results = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
        delayed(compute_spatial_correlation)(var) for var in static_present
    )
    
    spatial_results = [item for sublist in all_spatial_results for item in sublist]
    
    if len(spatial_results) > 0:
        spatial_df = pd.DataFrame(spatial_results)
        
        # Aggregate: keep if strong correlation with ANY quantile
        spatial_summary = spatial_df.groupby('Variable').agg({
            'abs_ρ': ['mean', 'max']
        }).reset_index()
        spatial_summary.columns = ['Variable', 'mean_abs_ρ', 'max_abs_ρ']
        spatial_summary = spatial_summary.sort_values('max_abs_ρ', ascending=False)
        
        static_spatial_selected = spatial_summary[
            spatial_summary['max_abs_ρ'] >= RHO_SPATIAL_THRESHOLD
        ]['Variable'].tolist()
        
        print(f"\n✓ Spatial correlation results:")
        print(f"  Threshold: |ρ| ≥ {RHO_SPATIAL_THRESHOLD}")
        print(f"  Selected: {len(static_spatial_selected)}/{len(static_present)}")
        print(f"\n  Top variables by max correlation:")
        print(spatial_summary.head(15).to_string(index=False))
    else:
        print("WARNING: No spatial correlations computed!")
        static_spatial_selected = []

# -------------------------------------------------------------------------
# 3C: STATIC VARIABLES - Temporal Influence (Within-Station)
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3C: STATIC VARIABLES - Temporal Influence Analysis")
print("-"*100)
print("Theory: Static variables can interact with dynamic processes over time")
print("Method: Correlate static×time with flow variations within each station")

if len(static_spatial_selected) == 0:
    print("WARNING: No static variables from spatial selection!")
    static_temporal_selected = []
else:
    def compute_temporal_influence(stat_var):
        """Compute temporal (within-station) correlation"""
        station_correlations = []
        
        for idr in X_train['IDr'].unique():
            # Get station data
            mask = X_train['IDr'] == idr
            if mask.sum() < 24:  # Need at least 2 years
                continue
            
            stat_vals = X_train.loc[mask, stat_var].values
            
            for q_var in q_cols:
                q_vals = Y_train.loc[Y_train['IDr'] == idr, q_var].values
                
                if len(stat_vals) != len(q_vals):
                    continue
                
                # Remove NaN
                valid_mask = ~(np.isnan(stat_vals) | np.isnan(q_vals))
                if np.sum(valid_mask) > 12:
                    # Static var should be constant, but check if small variations matter
                    if np.std(stat_vals[valid_mask]) > 0:
                        try:
                            rho, _ = spearmanr(stat_vals[valid_mask], q_vals[valid_mask])
                            if not np.isnan(rho):
                                station_correlations.append(abs(rho))
                        except:
                            pass
        
        if len(station_correlations) > 0:
            return {
                'Variable': stat_var,
                'mean_abs_ρ': np.mean(station_correlations),
                'median_abs_ρ': np.median(station_correlations),
                'n_stations': len(station_correlations)
            }
        return None
    
    print(f"Computing temporal influence for {len(static_spatial_selected)} variables...")
    temporal_results = Parallel(n_jobs=NCPU, prefer='processes', batch_size='auto')(
        delayed(compute_temporal_influence)(var) for var in static_spatial_selected
    )
    
    temporal_results = [r for r in temporal_results if r is not None]
    
    if len(temporal_results) > 0:
        temporal_df = pd.DataFrame(temporal_results).sort_values('mean_abs_ρ', ascending=False)
        
        static_temporal_selected = temporal_df[
            temporal_df['mean_abs_ρ'] >= RHO_TEMPORAL_THRESHOLD
        ]['Variable'].tolist()
        
        print(f"\n✓ Temporal influence results:")
        print(f"  Threshold: mean |ρ| ≥ {RHO_TEMPORAL_THRESHOLD}")
        print(f"  Selected: {len(static_temporal_selected)}/{len(static_spatial_selected)}")
        print(f"\n  Top variables by mean correlation:")
        print(temporal_df.head(15).to_string(index=False))
    else:
        print("WARNING: No temporal influences computed!")
        static_temporal_selected = []

# -------------------------------------------------------------------------
# 3D: COMBINE SPATIAL AND TEMPORAL SELECTION FOR STATIC VARIABLES
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3D: COMBINING SPATIAL AND TEMPORAL SELECTION")
print("-"*100)

# Union: keep if selected by EITHER spatial OR temporal analysis
static_combined = list(set(static_spatial_selected) | set(static_temporal_selected))
print(f"  Spatial only: {len(static_spatial_selected)}")
print(f"  Temporal only: {len(static_temporal_selected)}")
print(f"  Combined (union): {len(static_combined)}")

# -------------------------------------------------------------------------
# 3E: MULTICOLLINEARITY REMOVAL (DECORRELATION)
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3E: MULTICOLLINEARITY REMOVAL (DECORRELATION)")
print("-"*100)
print("Theory: Highly correlated variables are redundant")
print("Method: Remove one variable from each highly correlated pair (|ρ| > 0.85)")

if len(static_combined) == 0:
    print("WARNING: No static variables to decorrelate!")
    static_final = []
else:
    # Compute pairwise correlations between static variables
    station_static_subset = station_static[static_combined].fillna(station_static[static_combined].median())
    
    def compute_pairwise_correlation(var_pair):
        var1, var2 = var_pair
        try:
            v1 = station_static_subset[var1].values
            v2 = station_static_subset[var2].values
            mask = ~(np.isnan(v1) | np.isnan(v2))
            if np.sum(mask) > 10:
                rho, _ = spearmanr(v1[mask], v2[mask])
                if not np.isnan(rho) and abs(rho) > RHO_COLLINEARITY_THRESHOLD:
                    return (var1, var2, abs(rho))
        except:
            pass
        return None
    
    # Generate all unique pairs
    var_pairs = [(static_combined[i], static_combined[j])
                 for i in range(len(static_combined))
                 for j in range(i+1, len(static_combined))]
    
    print(f"  Computing {len(var_pairs)} pairwise correlations...")
    pairwise_results = Parallel(n_jobs=NCPU, prefer='threads', batch_size='auto')(
        delayed(compute_pairwise_correlation)(pair) for pair in var_pairs
    )
    
    # Build collinearity dictionary
    collinear_pairs = {}
    for result in pairwise_results:
        if result is not None:
            var1, var2, rho = result
            collinear_pairs[(var1, var2)] = rho
    
    print(f"  Found {len(collinear_pairs)} highly correlated pairs (|ρ| > {RHO_COLLINEARITY_THRESHOLD})")
    
    # Greedy removal: for each pair, remove the variable with lower spatial correlation
    removed_vars = set()
    spatial_importance = spatial_summary.set_index('Variable')['max_abs_ρ'].to_dict() if len(spatial_results) > 0 else {}
    
    for (var1, var2), rho in sorted(collinear_pairs.items(), key=lambda x: x[1], reverse=True):
        if var1 not in removed_vars and var2 not in removed_vars:
            # Keep variable with higher spatial correlation
            imp1 = spatial_importance.get(var1, 0)
            imp2 = spatial_importance.get(var2, 0)
            
            if imp1 >= imp2:
                removed_vars.add(var2)
                print(f"    Removing {var2} (ρ={rho:.3f} with {var1}, imp={imp2:.3f} < {imp1:.3f})")
            else:
                removed_vars.add(var1)
                print(f"    Removing {var1} (ρ={rho:.3f} with {var2}, imp={imp1:.3f} < {imp2:.3f})")
    
    static_final = [v for v in static_combined if v not in removed_vars]
    print(f"\n✓ Final static variables: {len(static_final)} (removed {len(removed_vars)} collinear)")

# -------------------------------------------------------------------------
# 3F: CREATE DERIVED FEATURES (HYDROLOGICALLY MOTIVATED)
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("3F: DERIVED FEATURES (HYDROLOGICAL THEORY)")
print("-"*100)
print("Theory: Normalize by catchment area to get specific discharge indicators")

derived_features = []

# Precipitation per unit area (runoff coefficient indicator)
if 'ppt0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['ppt0_per_area'] = X_train['ppt0'] / (X_train['accumulation'] + 1)
    X_test['ppt0_per_area'] = X_test['ppt0'] / (X_test['accumulation'] + 1)
    derived_features.append('ppt0_per_area')

# Soil moisture per unit area (baseflow indicator)
if 'soil0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['soil0_per_area'] = X_train['soil0'] / (X_train['accumulation'] + 1)
    X_test['soil0_per_area'] = X_test['soil0'] / (X_test['accumulation'] + 1)
    derived_features.append('soil0_per_area')

# Snow water equivalent per unit area (snowmelt potential)
if 'swe0' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['swe0_per_area'] = X_train['swe0'] / (X_train['accumulation'] + 1)
    X_test['swe0_per_area'] = X_test['swe0'] / (X_test['accumulation'] + 1)
    derived_features.append('swe0_per_area')

# River width per unit area (channel density indicator)
if 'GRWLw' in X_train.columns and 'accumulation' in X_train.columns:
    X_train['GRWLw_per_area'] = X_train['GRWLw'] / (X_train['accumulation'] + 1)
    X_test['GRWLw_per_area'] = X_test['GRWLw'] / (X_test['accumulation'] + 1)
    derived_features.append('GRWLw_per_area')

print(f"✓ Created {len(derived_features)} derived features:")
for feat in derived_features:
    print(f"  - {feat}")

# -------------------------------------------------------------------------
# FINAL FEATURE SET
# -------------------------------------------------------------------------
dynamic_final = dynamic_selected + derived_features
static_final_actual = static_final

print(f"\n" + "="*100)
print("FINAL FEATURE SELECTION SUMMARY")
print("="*100)
print(f"DYNAMIC features: {len(dynamic_final)}")
for f in dynamic_final:
    print(f"  - {f}")
print(f"\nSTATIC features: {len(static_final_actual)}")
for f in sorted(static_final_actual)[:20]:
    print(f"  - {f}")
if len(static_final_actual) > 20:
    print(f"  ... and {len(static_final_actual) - 20} more")

if len(dynamic_final) == 0:
    print("\nERROR: No dynamic features selected!")
    sys.exit(1)

# Save feature selection report
report_fs = Report('../predict_score_red/HYDRO_FEATURE_SELECTION_REPORT.txt')
report_fs.add_section('HYDROLOGICAL FEATURE SELECTION', level=1)
report_fs.add_content(f'Date: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
report_fs.add_content('')
report_fs.add_section('DYNAMIC VARIABLES (Temporal)', level=2)
report_fs.add_content(f'Selected: {len(dynamic_selected)}')
if len(dynamic_results) > 0:
    report_fs.add_dataframe(dynamic_summary)
report_fs.add_section('STATIC VARIABLES (Spatial)', level=2)
report_fs.add_content(f'Spatial selection: {len(static_spatial_selected)}')
report_fs.add_content(f'Temporal influence: {len(static_temporal_selected)}')
report_fs.add_content(f'Combined: {len(static_combined)}')
report_fs.add_content(f'After decorrelation: {len(static_final)}')
if len(spatial_results) > 0:
    report_fs.add_dataframe(spatial_summary.head(30))
report_fs.add_section('DERIVED FEATURES', level=2)
for feat in derived_features:
    report_fs.add_content(f'  {feat}')
report_fs.save()
print(f"\n✓ Feature selection report saved")

# =========================================================================
# PHASE 4: LSTM PREPARATION & TRAINING
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: LSTM MODEL PREPARATION & TRAINING")
print("="*100)

# Clean and scale data
def clean_numeric(df):
    df_clean = df.replace([np.inf, -np.inf], np.nan)
    for col in df_clean.columns:
        if pd.api.types.is_numeric_dtype(df_clean[col]):
            df_clean[col] = df_clean[col].fillna(df_clean[col].median())
    return df_clean

print("Preparing feature matrices...")
X_train_dyn = clean_numeric(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_numeric(X_test[dynamic_final]).astype('float32')

if len(static_final_actual) > 0:
    X_train_sta = clean_numeric(X_train[static_final_actual]).astype('float32')
    X_test_sta = clean_numeric(X_test[static_final_actual]).astype('float32')
else:
    X_train_sta = pd.DataFrame(np.zeros((len(X_train), 1), dtype='float32'))
    X_test_sta = pd.DataFrame(np.zeros((len(X_test), 1), dtype='float32'))

Y_train_clean = clean_numeric(Y_train[q_cols]).astype('float32')
Y_test_clean = clean_numeric(Y_test[q_cols]).astype('float32')

print(f"  Dynamic: {X_train_dyn.shape[1]} features")
print(f"  Static: {X_train_sta.shape[1]} features")
print(f"  Targets: {len(q_cols)} quantiles")

# Scaling
print("Scaling with QuantileTransformer (robust for skewed hydrological data)...")
qt_dyn = QuantileTransformer(n_quantiles=min(2000, len(X_train_dyn)), output_distribution='normal', random_state=RANDOM_STATE)
qt_sta = QuantileTransformer(n_quantiles=min(2000, len(X_train_sta)), output_distribution='normal', random_state=RANDOM_STATE)
qt_y = QuantileTransformer(n_quantiles=min(2000, len(Y_train_clean)), output_distribution='normal', random_state=RANDOM_STATE)

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.values).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.values).astype('float32')

X_train_sta_s = qt_sta.fit_transform(X_train_sta.values).astype('float32')
X_test_sta_s = qt_sta.transform(X_test_sta.values).astype('float32')

Y_train_s = qt_y.fit_transform(Y_train_clean.values).astype('float32')
Y_test_s = qt_y.transform(Y_test_clean.values).astype('float32')

print("✓ Scaling complete")

# Build sequences
print("\nBuilding LSTM sequences...")

def build_sequences(df_meta, X_dyn_s, X_sta_s, Y_s):
    """Build sequences respecting station boundaries"""
    idr = df_meta['IDr'].values
    yyyy = df_meta['YYYY'].values
    mm = df_meta['MM'].values
    
    # Sort by station, year, month
    sort_idx = np.lexsort((mm, yyyy, idr))
    idr_sorted = idr[sort_idx]
    Xd = X_dyn_s[sort_idx]
    Xs = X_sta_s[sort_idx]
    Ys = Y_s[sort_idx]
    
    X_seq_dyn, X_seq_sta, Y_seq, orig_idx = [], [], [], []
    
    # Find station boundaries
    _, start_idx = np.unique(idr_sorted, return_index=True)
    start_idx = np.sort(start_idx)
    end_idx = np.append(start_idx[1:], len(idr_sorted))
    
    # Build sequences within each station
    for start, end in zip(start_idx, end_idx):
        n_obs = end - start
        if n_obs < SEQ_LEN:
            continue
        
        # Create all possible sequences for this station
        for j in range(start + SEQ_LEN - 1, end):
            window_start = j - SEQ_LEN + 1
            X_seq_dyn.append(Xd[window_start:j+1])
            X_seq_sta.append(Xs[j])
            Y_seq.append(Ys[j])
            orig_idx.append(sort_idx[j])
    
    if len(X_seq_dyn) == 0:
        return (np.zeros((0, SEQ_LEN, X_dyn_s.shape[1]), dtype='float32'),
                np.zeros((0, X_sta_s.shape[1]), dtype='float32'),
                np.zeros((0, Y_s.shape[1]), dtype='float32'),
                np.zeros((0,), dtype='int64'))
    
    return (np.array(X_seq_dyn, dtype='float32'),
            np.array(X_seq_sta, dtype='float32'),
            np.array(Y_seq, dtype='float32'),
            np.array(orig_idx, dtype='int64'))

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']].copy()
Xte_meta = X_test[['IDr', 'YYYY', 'MM']].copy()

Xtr_dyn_seq, Xtr_sta_seq, Ytr_seq, tr_idx = build_sequences(Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s)
Xte_dyn_seq, Xte_sta_seq, Yte_seq, te_idx = build_sequences(Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s)

print(f"  Train sequences: {Xtr_dyn_seq.shape[0]:,}")
print(f"  Test sequences: {Xte_dyn_seq.shape[0]:,}")

if Xtr_dyn_seq.shape[0] == 0:
    print("ERROR: No training sequences! Check data length.")
    sys.exit(1)

# Get original flow values for evaluation
Ytr_true = Y_train_clean.values[tr_idx]
Yte_true = Y_test_clean.values[te_idx] if len(te_idx) > 0 else np.zeros((0, len(q_cols)), dtype='float32')

# LSTM Model
print("\nDefining LSTM model...")

class HydroLSTM(nn.Module):
    """LSTM for hydrological modeling with static catchment features"""
    def __init__(self, n_dyn, n_sta, hidden=128, num_layers=2, dropout=0.2, n_quantiles=11):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=n_dyn,
            hidden_size=hidden,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
            bidirectional=False
        )
        
        # Fusion layer
        fusion_dim = hidden + n_sta
        self.fc = nn.Sequential(
            nn.Linear(fusion_dim, 128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, n_quantiles)
        )
    
    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]  # Last hidden state
        z = torch.cat([h_last, x_sta], dim=1)
        return self.fc(z)

class HydroDataset(Dataset):
    def __init__(self, X_dyn, X_sta, Y):
        self.X_dyn = torch.from_numpy(X_dyn)
        self.X_sta = torch.from_numpy(X_sta)
        self.Y = torch.from_numpy(Y)
    
    def __len__(self):
        return len(self.X_dyn)
    
    def __getitem__(self, idx):
        return self.X_dyn[idx], self.X_sta[idx], self.Y[idx]

train_ds = HydroDataset(Xtr_dyn_seq, Xtr_sta_seq, Ytr_seq)
train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=0)

n_dyn = Xtr_dyn_seq.shape[2]
n_sta = Xtr_sta_seq.shape[1]

model = HydroLSTM(n_dyn=n_dyn, n_sta=n_sta, hidden=128, num_layers=2, dropout=0.2, n_quantiles=len(q_cols)).to(DEVICE)
optimizer = torch.optim.Adam(model.parameters(), lr=LR)
criterion = nn.SmoothL1Loss()  # Robust to outliers

print(f"  Architecture: {n_dyn} dynamic + {n_sta} static → LSTM(128×2) → FC → {len(q_cols)} quantiles")
print(f"  Device: {DEVICE}")
print(f"  Training: {EPOCHS} epochs, batch size {BATCH_SIZE}, LR {LR}")

# Training loop
def run_epoch(loader, train=True):
    model.train() if train else model.eval()
    losses, preds = [], []
    
    for xd, xs, y in loader:
        xd = xd.to(DEVICE).float()
        xs = xs.to(DEVICE).float()
        y = y.to(DEVICE).float()
        
        if train:
            optimizer.zero_grad(set_to_none=True)
        
        with torch.set_grad_enabled(train):
            pred = model(xd, xs)
            loss = criterion(pred, y)
            
            if train:
                loss.backward()
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()
        
        losses.append(loss.item())
        preds.append(pred.detach().cpu().numpy())
    
    pred_all = np.vstack(preds) if preds else np.zeros((0, len(q_cols)), dtype='float32')
    return np.mean(losses) if losses else np.nan, pred_all

print("\nTraining LSTM...")
best_loss = np.inf
best_state = None

for epoch in range(1, EPOCHS + 1):
    train_loss, _ = run_epoch(train_loader, train=True)
    
    if train_loss < best_loss:
        best_loss = train_loss
        best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}
    
    if epoch == 1 or epoch % 10 == 0 or epoch == EPOCHS:
        print(f"  Epoch {epoch:3d}/{EPOCHS} | Loss: {train_loss:.5f} | Best: {best_loss:.5f}")

if best_state:
    model.load_state_dict(best_state)

print(f"✓ Training complete. Best loss: {best_loss:.5f}")

# Predictions
model.eval()
_, Ytr_pred_s = run_epoch(train_loader, train=False)

if Xte_dyn_seq.shape[0] > 0:
    test_ds = HydroDataset(Xte_dyn_seq, Xte_sta_seq, Yte_seq)
    test_loader = DataLoader(test_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)
    _, Yte_pred_s = run_epoch(test_loader, train=False)
else:
    Yte_pred_s = np.zeros((0, len(q_cols)), dtype='float32')

# Inverse transform
Ytr_pred = qt_y.inverse_transform(Ytr_pred_s).astype('float32')
Yte_pred = qt_y.inverse_transform(Yte_pred_s).astype('float32') if len(Yte_pred_s) > 0 else np.zeros((0, len(q_cols)), dtype='float32')

# =========================================================================
# PHASE 5: EVALUATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 5: MODEL EVALUATION")
print("="*100)

def kge(obs, sim):
    """Kling-Gupta Efficiency"""
    r = np.corrcoef(obs, sim)[0, 1]
    beta = np.mean(sim) / np.mean(obs)
    gamma = (np.std(sim) / np.mean(sim)) / (np.std(obs) / np.mean(obs))
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

def nse(obs, sim):
    """Nash-Sutcliffe Efficiency"""
    return 1 - np.sum((obs - sim)**2) / np.sum((obs - np.mean(obs))**2)

def compute_metrics(y_true, y_pred):
    if len(y_true) == 0:
        return {k: (np.nan, [np.nan]*len(q_cols)) for k in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']}
    
    metrics = {k: [] for k in ['r', 'rho', 'nse', 'kge', 'rmse', 'mae']}
    
    for i in range(len(q_cols)):
        try:
            metrics['r'].append(pearsonr(y_true[:, i], y_pred[:, i])[0])
            metrics['rho'].append(spearmanr(y_true[:, i], y_pred[:, i])[0])
            metrics['nse'].append(nse(y_true[:, i], y_pred[:, i]))
            metrics['kge'].append(kge(y_true[:, i], y_pred[:, i]))
            metrics['rmse'].append(np.sqrt(mean_squared_error(y_true[:, i], y_pred[:, i])))
            metrics['mae'].append(mean_absolute_error(y_true[:, i], y_pred[:, i]))
        except:
            for k in metrics:
                metrics[k].append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true, Ytr_pred)
test_metrics = compute_metrics(Yte_true, Yte_pred)

print("\nTRAINING PERFORMANCE:")
print(f"  Pearson r:   {train_metrics['r'][0]:.4f}")
print(f"  Spearman ρ:  {train_metrics['rho'][0]:.4f}")
print(f"  NSE:         {train_metrics['nse'][0]:.4f}")
print(f"  KGE:         {train_metrics['kge'][0]:.4f}")
print(f"  RMSE:        {train_metrics['rmse'][0]:.4f}")
print(f"  MAE:         {train_metrics['mae'][0]:.4f}")

if len(Yte_true) > 0:
    print("\nTESTING PERFORMANCE:")
    print(f"  Pearson r:   {test_metrics['r'][0]:.4f}")
    print(f"  Spearman ρ:  {test_metrics['rho'][0]:.4f}")
    print(f"  NSE:         {test_metrics['nse'][0]:.4f}")
    print(f"  KGE:         {test_metrics['kge'][0]:.4f}")
    print(f"  RMSE:        {test_metrics['rmse'][0]:.4f}")
    print(f"  MAE:         {test_metrics['mae'][0]:.4f}")

print("\nPER-QUANTILE PERFORMANCE (Training):")
perf_df = pd.DataFrame({
    'Quantile': q_cols,
    'r': train_metrics['r'][1],
    'ρ': train_metrics['rho'][1],
    'NSE': train_metrics['nse'][1],
    'KGE': train_metrics['kge'][1],
    'RMSE': train_metrics['rmse'][1],
    'MAE': train_metrics['mae'][1]
}).round(4)
print(perf_df.to_string(index=False))

# Save outputs
print("\n" + "="*100)
print("SAVING OUTPUTS")
print("="*100)

# Predictions
np.savetxt('../predict_prediction_red/HYDRO_LSTM_Train.txt', Ytr_pred, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')
if len(Yte_pred) > 0:
    np.savetxt('../predict_prediction_red/HYDRO_LSTM_Test.txt', Yte_pred, delimiter=' ', fmt='%.6f', header=' '.join(q_cols), comments='')

# Features
with open('../predict_importance_red/HYDRO_LSTM_features.txt', 'w') as f:
    f.write('DYNAMIC_VARIABLES\n')
    for v in dynamic_final:
        f.write(f'{v}\n')
    f.write('\nSTATIC_VARIABLES\n')
    for v in sorted(static_final_actual):
        f.write(f'{v}\n')

# Report
report = Report('../predict_score_red/HYDRO_LSTM_REPORT.txt')
report.add_section('HYDROLOGICAL LSTM MODEL', level=1)
report.add_section('Configuration', level=2)
report.add_content(f'Training stations: {len(train_stations)} (≥{MIN_TRAIN_YEARS} years)')
report.add_content(f'Testing stations: {len(test_stations)} (<{MIN_TRAIN_YEARS} years)')
report.add_content(f'Sequence length: {SEQ_LEN} months')
report.add_content(f'Dynamic features: {len(dynamic_final)}')
report.add_content(f'Static features: {len(static_final_actual)}')
report.add_section('Performance', level=2)
report.add_content(f'Training: NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}')
if len(Yte_true) > 0:
    report.add_content(f'Testing: NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}')
report.add_section('Per-Quantile Performance', level=2)
report.add_dataframe(perf_df)
report.save()

print(f"✓ Predictions saved: ../predict_prediction_red/HYDRO_LSTM_*.txt")
print(f"✓ Features saved: ../predict_importance_red/HYDRO_LSTM_features.txt")
print(f"✓ Report saved: ../predict_score_red/HYDRO_LSTM_REPORT.txt")

print(f"\n{'='*100}")
print("HYDROLOGICAL LSTM MODELING COMPLETE")
print(f"{'='*100}")
print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"{'='*100}\n")

EOFPYTHON
exit
