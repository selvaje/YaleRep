#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500
#SBATCH --mem=100G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd "$EXTRACT"

module load StdEnv

export obs_leaf="$obs_leaf" ; export obs_split="$obs_split" ;  export sample="$sample" ; export depth="$depth" ; export N_EST="$SLURM_ARRAY_TASK_ID"
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth"
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf="$obs_leaf",obs_split="$obs_split",depth="$depth",sample="$sample",N_EST="$N_EST" /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'PYTHON_EOF'
import os
import gc
import warnings
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GroupKFold 
from sklearn.feature_selection import RFECV
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor
from sklearn.base import RegressorMixin, BaseEstimator
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy.stats import pearsonr, spearmanr, skew, kurtosis
from scipy.spatial.distance import cdist
from joblib import Parallel, delayed
import psutil

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

# ============================================================================
# CONFIGURATION & INPUT PARSING
# ============================================================================

obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_i = int(os.environ['obs_split'])
depth_i = int(os.environ['depth'])
sample_f = float(os.environ['sample'])
N_EST_I = int(os.environ['N_EST'])

obs_leaf_s = str(obs_leaf_i)
obs_split_s = str(obs_split_i)
depth_s = str(depth_i)
sample_s = str(int(sample_f * 100))
N_EST_S = str(N_EST_I)

print(f'Config: N_EST={N_EST_I}, leaf={obs_leaf_i}, split={obs_split_i}, depth={depth_i}, sample={sample_f}')

# ============================================================================
# STATIC/DYNAMIC VARIABLE DEFINITIONS
# ============================================================================

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
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine',
    'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev',
    'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dynamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# ============================================================================
# DATA TYPE DEFINITIONS
# ============================================================================

dtypes_X = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
}

climate_soil_cols = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
]

feature_cols = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine',
    'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev',
    'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dtypes_X.update({col: 'int32' for col in climate_soil_cols if col not in dtypes_X})
dtypes_X.update({col: 'float32' for col in feature_cols})

dtypes_Y = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
}
dtypes_Y.update({col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']})

# ============================================================================
# DATA LOADING (Chunked for memory efficiency)
# ============================================================================

def load_with_dtypes(filepath, usecols=None, dtype_dict=None, chunksize=50000):
    chunks = []
    for chunk in pd.read_csv(filepath, header=0, sep='\s+', 
                             usecols=usecols, dtype=dtype_dict, 
                             engine='c', chunksize=chunksize):
        chunks.append(chunk)
        if len(chunks) % 10 == 0:
            gc.collect()
    return pd.concat(chunks, ignore_index=True) if chunks else pd.DataFrame()

print('Loading predictor importance...')
importance = pd.read_csv('varX_list.txt', header=None, sep='\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)

print('Loading Y data...')
Y = load_with_dtypes('stationID_x_y_valueALL_predictors_Y_floredSFD.txt', dtype_dict=dtypes_Y)

print('Loading X data...')
X = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', usecols=lambda col: col in include_variables, dtype_dict=dtypes_X)

print(f'X shape: {X.shape}, Y shape: {Y.shape}')

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# ============================================================================
# SPATIO-TEMPORAL STATISTICAL ANALYSIS FOR RF MODEL DESIGN
# ============================================================================

print('Starting Focused Spatio-Temporal Statistical Analysis...')

# Create merged dataset for analysis
df_analysis = pd.merge(X, Y, on=['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'], how='inner')
print(f'Merged data shape: {df_analysis.shape}')

# Initialize results list
analysis_results = []

# ============================================================================
# 1. GLOBAL STATISTICS
# ============================================================================
print('1. Computing global statistics...')

output_vars = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
for output_var in output_vars:
    if output_var in df_analysis.columns:
        q_data = df_analysis[output_var].dropna()
        analysis_results.append({
            'Category': 'Global_Output_Statistics',
            'Metric': output_var,
            'Mean': q_data.mean(),
            'Std': q_data.std(),
            'Min': q_data.min(),
            'Max': q_data.max(),
            'Median': q_data.median(),
            'Skewness': skew(q_data),
            'Kurtosis': kurtosis(q_data),
            'CV': q_data.std() / q_data.mean() if q_data.mean() != 0 else np.nan,
            'Q10': q_data.quantile(0.1),
            'Q90': q_data.quantile(0.9),
            'Detail': 'Distribution shape and normality indicators'
        })

# ============================================================================
# 2. TEMPORAL PATTERN ANALYSIS (Seasonal & Annual Variability)
# ============================================================================
print('2. Computing temporal patterns...')

seasonal_agg_dict = {
    'Q50': ['mean', 'std', 'count'],
    'Q10': 'mean',
    'Q90': 'mean',
}

if 'ppt0' in df_analysis.columns:
    seasonal_agg_dict['ppt0'] = 'mean'
if 'tmin0' in df_analysis.columns:
    seasonal_agg_dict['tmin1'] = 'mean'
if 'soil0' in df_analysis.columns:
    seasonal_agg_dict['soil0'] = 'mean'

seasonal_stats = df_analysis.groupby('MM').agg(seasonal_agg_dict).reset_index()

for _, row in seasonal_stats.iterrows():
    month = int(row['MM'])
    result_dict = {
        'Category': 'Temporal_Seasonal_Pattern',
        'Temporal_Level': f'Month_{month:02d}',
        'Q50_Mean': row[('Q50', 'mean')],
        'Q50_Std': row[('Q50', 'std')],
        'Q50_Range': row[('Q90', 'mean')] - row[('Q10', 'mean')],
        'Num_Observations': int(row[('Q50', 'count')]),
    }
    
    if 'ppt0' in df_analysis.columns:
        result_dict['Ppt_Mean'] = row[('ppt0', 'mean')]
    if 'tmin1' in df_analysis.columns:
        result_dict['Temp_Mean'] = row[('tmin1', 'mean')]
    if 'soil0' in df_analysis.columns:
        result_dict['Soil_Mean'] = row[('soil0', 'mean')]
    
    result_dict['Detail'] = 'Seasonal variability - indicates if temporal features needed'
    analysis_results.append(result_dict)

# ============================================================================
# 3. SPATIAL HETEROGENEITY ANALYSIS
# ============================================================================
print('3. Computing spatial heterogeneity...')

spatial_summary = df_analysis.groupby('IDr').agg({
    'Xcoord': 'first',
    'Ycoord': 'first',
    'Q50': ['mean', 'std', 'count'],
    'YYYY': ['min', 'max'],
}).reset_index()

spatial_summary.columns = ['IDr', 'Xcoord', 'Ycoord', 'Q50_mean', 'Q50_std', 'Num_obs', 'Year_min', 'Year_max']
spatial_summary['Temporal_Years'] = spatial_summary['Year_max'] - spatial_summary['Year_min'] + 1

print('  - Performing spatial clustering...')
static_features_for_clustering = [col for col in static_var if col in df_analysis.columns]
if static_features_for_clustering:
    from sklearn.preprocessing import StandardScaler
    
    station_static = df_analysis.drop_duplicates(subset=['IDr'])[['IDr'] + static_features_for_clustering].set_index('IDr')
    station_static_clean = station_static.fillna(station_static.mean())
    
    scaler = StandardScaler()
    station_static_normalized = scaler.fit_transform(station_static_clean)
    
    n_clusters = min(5, max(3, len(station_static_clean) // 20))
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    clusters = kmeans.fit_predict(station_static_normalized)
    
    for cluster_id in range(n_clusters):
        cluster_stations = station_static_clean.index[clusters == cluster_id]
        cluster_data = df_analysis[df_analysis['IDr'].isin(cluster_stations)]
        cluster_spatial = spatial_summary[spatial_summary['IDr'].isin(cluster_stations)]
        
        analysis_results.append({
            'Category': 'Spatial_Regional_Cluster',
            'Cluster_ID': cluster_id,
            'Num_Stations': len(cluster_stations),
            'Num_Observations': len(cluster_data),
            'Q50_Mean': cluster_data['Q50'].mean(),
            'Q50_Std': cluster_data['Q50'].std(),
            'Q50_CV': cluster_data['Q50'].std() / cluster_data['Q50'].mean() if cluster_data['Q50'].mean() != 0 else np.nan,
            'QMAX_Mean': cluster_data['QMAX'].mean() if 'QMAX' in cluster_data.columns else np.nan,
            'QMIN_Mean': cluster_data['QMIN'].mean() if 'QMIN' in cluster_data.columns else np.nan,
            'Avg_Elevation': cluster_data['elev'].mean() if 'elev' in cluster_data.columns else np.nan,
            'Avg_Slope': cluster_data['slope'].mean() if 'slope' in cluster_data.columns else np.nan,
            'Xcoord_Range': cluster_spatial['Xcoord'].max() - cluster_spatial['Xcoord'].min(),
            'Ycoord_Range': cluster_spatial['Ycoord'].max() - cluster_spatial['Ycoord'].min(),
            'Detail': 'Spatial grouping - indicates if regionalization helps'
        })

# ============================================================================
# 4. PREDICTOR IMPORTANCE INDICATORS (Ranked for RF Feature Selection)
# ============================================================================
print('4. Computing predictor importance indicators...')

print('  - Analyzing static predictors...')
static_importance = []
for static_var_name in static_var:
    if static_var_name in df_analysis.columns:
        valid_data = df_analysis[[static_var_name, 'Q50']].dropna()
        if len(valid_data) > 2:
            pearson_r, pearson_p = pearsonr(valid_data[static_var_name], valid_data['Q50'])
            static_importance.append({
                'Predictor_Type': 'Static',
                'Predictor': static_var_name,
                'Pearson_r': abs(pearson_r),
                'Pearson_pvalue': pearson_p,
                'Num_Samples': len(valid_data),
                'Spatial_Variation': df_analysis.groupby('IDr')[static_var_name].std().mean() / df_analysis[static_var_name].mean() if df_analysis[static_var_name].mean() != 0 else np.nan
            })

print('  - Analyzing dynamic predictors...')
for dynamic_var_name in dynamic_var:
    if dynamic_var_name in df_analysis.columns:
        valid_data = df_analysis[[dynamic_var_name, 'Q50']].dropna()
        if len(valid_data) > 2:
            pearson_r, pearson_p = pearsonr(valid_data[dynamic_var_name], valid_data['Q50'])
            static_importance.append({
                'Predictor_Type': 'Dynamic',
                'Predictor': dynamic_var_name,
                'Pearson_r': abs(pearson_r),
                'Pearson_pvalue': pearson_p,
                'Num_Samples': len(valid_data),
                'Temporal_Variation': df_analysis.groupby(['YYYY', 'MM'])[dynamic_var_name].std().mean() / df_analysis[dynamic_var_name].mean() if df_analysis[dynamic_var_name].mean() != 0 else np.nan
            })

static_importance_df = pd.DataFrame(static_importance).sort_values('Pearson_r', ascending=False)

for rank, (_, row) in enumerate(static_importance_df.head(30).iterrows(), 1):
    variation_key = 'Spatial_Variation' if row['Predictor_Type'] == 'Static' else 'Temporal_Variation'
    analysis_results.append({
        'Category': 'Predictor_Importance_Top30',
        'Rank': rank,
        'Predictor_Type': row['Predictor_Type'],
        'Predictor': row['Predictor'],
        'Correlation_with_Q50': row['Pearson_r'],
        'Pvalue': row['Pearson_pvalue'],
        'Variation_Coefficient': row[variation_key],
        'Num_Samples': int(row['Num_Samples']),
        'Detail': 'Top RF features ranked by correlation strength'
    })

# ============================================================================
# 5. TEMPORAL AUTOCORRELATION & DEPENDENCY STRUCTURE
# ============================================================================
print('5. Computing temporal autocorrelation structure...')

sample_stations = df_analysis['IDr'].unique()[:min(50, len(df_analysis['IDr'].unique()))]
autocorr_results = []

for station_id in sample_stations:
    station_data = df_analysis[df_analysis['IDr'] == station_id].sort_values(['YYYY', 'MM'])
    
    if len(station_data) > 12:
        q50_values = station_data['Q50'].dropna().values
        
        if len(q50_values) > 1:
            lag1_corr = np.corrcoef(q50_values[:-1], q50_values[1:])[0, 1]
            autocorr_results.append(lag1_corr)

if autocorr_results:
    analysis_results.append({
        'Category': 'Temporal_Autocorrelation',
        'Metric': 'Lag1_Autocorrelation',
        'Mean': np.nanmean(autocorr_results),
        'Std': np.nanstd(autocorr_results),
        'Min': np.nanmin(autocorr_results),
        'Max': np.nanmax(autocorr_results),
        'Num_Stations_Analyzed': len(autocorr_results),
        'Detail': 'Temporal dependency - high values suggest need for lag features'
    })

# ============================================================================
# 6. INTERACTION EFFECTS: DYNAMIC PREDICTORS x SPATIAL LOCATION
# ============================================================================
print('6. Computing interaction patterns...')

if 'ppt0' in df_analysis.columns and 'elev' in df_analysis.columns and len(spatial_summary) > 1:
    df_analysis['Elev_Zone'] = pd.qcut(df_analysis['elev'], q=3, labels=['Low', 'Mid', 'High'], duplicates='drop')
    
    for zone in df_analysis['Elev_Zone'].unique():
        zone_data = df_analysis if zone == 'All' else df_analysis[df_analysis['Elev_Zone'] == zone]
        
        valid_data = zone_data[['ppt0', 'Q50']].dropna()
        if len(valid_data) > 2:
            ppt_q_corr, ppt_q_pval = pearsonr(valid_data['ppt0'], valid_data['Q50'])
            
            analysis_results.append({
                'Category': 'Spatial_Temporal_Interaction',
                'Interaction': 'Precipitation_x_Elevation',
                'Elevation_Zone': str(zone),
                'Ppt_Q50_Correlation': ppt_q_corr,
                'Num_Observations': len(valid_data),
                'Detail': 'Dynamic-spatial interaction - indicates if regionalized models help'
            })

# ============================================================================
# 7. DATA QUALITY & COVERAGE ASSESSMENT
# ============================================================================
print('7. Assessing data quality and coverage...')

analysis_results.append({
    'Category': 'Data_Quality_Spatial_Coverage',
    'Metric': 'Station_Coverage',
    'Num_Stations': df_analysis['IDr'].nunique(),
    'Num_Observations': len(df_analysis),
    'Avg_Obs_Per_Station': len(df_analysis) / df_analysis['IDr'].nunique(),
    'Temporal_Span_Years': int(df_analysis['YYYY'].max() - df_analysis['YYYY'].min() + 1),
    'Detail': 'Data completeness assessment'
})

missing_summary = []
for col in static_var + dynamic_var:
    if col in df_analysis.columns:
        missing_pct = (df_analysis[col].isna().sum() / len(df_analysis)) * 100
        if missing_pct > 0:
            missing_summary.append({
                'Variable': col,
                'Missing_Percent': missing_pct
            })

if missing_summary:
    missing_df = pd.DataFrame(missing_summary).sort_values('Missing_Percent', ascending=False)
    for _, row in missing_df.head(10).iterrows():
        analysis_results.append({
            'Category': 'Data_Quality_Missing_Values',
            'Variable': row['Variable'],
            'Missing_Percent': row['Missing_Percent'],
            'Detail': 'Missing data rate - may affect feature availability'
        })

# ============================================================================
# 8. MODEL DESIGN RECOMMENDATIONS
# ============================================================================
print('8. Generating model design recommendations...')

seasonal_cv = seasonal_stats[('Q50', 'std')].mean() / seasonal_stats[('Q50', 'mean')].mean()

recommendations = []
if seasonal_cv > 0.3:
    recommendations.append('Strong seasonal pattern detected - consider temporal features (month, season)')
else:
    recommendations.append('Weak seasonal pattern - temporal features may have limited benefit')

if len(spatial_summary) > 30:
    recommendations.append('Many stations detected - spatial clustering or regional RF models recommended')
else:
    recommendations.append('Limited stations - global RF model may be sufficient')

if np.nanmean(autocorr_results) > 0.4 if autocorr_results else False:
    recommendations.append('High temporal autocorrelation - consider lag features for improved accuracy')

top_predictors = static_importance_df.head(10)['Predictor'].tolist()
top_5_predictors = ', '.join(top_predictors[:5])
top_rec = f'Focus RF on top predictors: {top_5_predictors}'
recommendations.append(top_rec)

for i, rec in enumerate(recommendations, 1):
    analysis_results.append({
        'Category': 'Model_Design_Recommendation',
        'Recommendation_ID': i,
        'Recommendation': rec,
        'Detail': 'Based on statistical patterns in data'
    })

# ============================================================================
# 9. FEATURE MULTICOLLINEARITY ASSESSMENT
# ============================================================================
print('9. Computing feature multicollinearity...')

top_static = static_importance_df[static_importance_df['Predictor_Type'] == 'Static'].head(15)['Predictor'].tolist()
if len(top_static) > 1:
    correlation_matrix = df_analysis[top_static].corr()
    
    high_corr_pairs = []
    for i in range(len(correlation_matrix.columns)):
        for j in range(i+1, len(correlation_matrix.columns)):
            corr_val = correlation_matrix.iloc[i, j]
            if abs(corr_val) > 0.7:
                high_corr_pairs.append({
                    'Var1': correlation_matrix.columns[i],
                    'Var2': correlation_matrix.columns[j],
                    'Correlation': corr_val
                })
    
    num_high_corr = len(high_corr_pairs)
    rec_multicollinearity = 'Consider removing one variable from each pair' if num_high_corr > 0 else 'Low multicollinearity detected'
    analysis_results.append({
        'Category': 'Feature_Multicollinearity',
        'Metric': 'High_Correlation_Pairs',
        'Num_Pairs_Corr_GT_0.7': num_high_corr,
        'Recommendation': rec_multicollinearity,
        'Detail': 'Multicollinearity assessment for top static features'
    })

# ============================================================================
# 10. STATION-LEVEL FLOW VARIABILITY & HETEROGENEITY
# ============================================================================
print('10. Computing station-level heterogeneity...')

station_heterogeneity = []
for station_id in df_analysis['IDr'].unique():
    station_data = df_analysis[df_analysis['IDr'] == station_id]
    
    if len(station_data) > 10:
        q50_values = station_data['Q50'].values
        station_heterogeneity.append({
            'IDr': station_id,
            'Q50_Mean': q50_values.mean(),
            'Q50_CV': q50_values.std() / q50_values.mean() if q50_values.mean() != 0 else np.nan,
            'Num_Obs': len(station_data)
        })

if station_heterogeneity:
    het_df = pd.DataFrame(station_heterogeneity)
    het_std = het_df['Q50_CV'].std()
    het_rec = 'High station heterogeneity detected - consider separate regional models' if het_std > 0.3 else 'Low heterogeneity - single global model likely sufficient'
    analysis_results.append({
        'Category': 'Station_Level_Heterogeneity',
        'Metric': 'Flow_Variability_Across_Stations',
        'Q50_CV_Mean': het_df['Q50_CV'].mean(),
        'Q50_CV_Std': het_std,
        'Q50_CV_Min': het_df['Q50_CV'].min(),
        'Q50_CV_Max': het_df['Q50_CV'].max(),
        'Num_Stations': len(het_df),
        'High_Variability_Stations': len(het_df[het_df['Q50_CV'] > het_df['Q50_CV'].quantile(0.75)]),
        'Recommendation': het_rec,
        'Detail': 'Station-level variability indicates if regionalization helps'
    })

# ============================================================================
# 11. LAG FEATURE NECESSITY ANALYSIS
# ============================================================================
print('11. Computing lag feature correlations...')

lag_correlations = []
sample_stations_lag = df_analysis['IDr'].unique()[:min(30, len(df_analysis['IDr'].unique()))]

for station_id in sample_stations_lag:
    station_data = df_analysis[df_analysis['IDr'] == station_id].sort_values(['YYYY', 'MM'])
    
    if len(station_data) > 24:
        q50_values = station_data['Q50'].dropna().values
        
        if len(q50_values) > 2:
            lag1_corr = np.corrcoef(q50_values[:-1], q50_values[1:])[0, 1]
            lag3_corr = np.corrcoef(q50_values[:-3], q50_values[3:])[0, 1] if len(q50_values) > 3 else np.nan
            lag12_corr = np.corrcoef(q50_values[:-12], q50_values[12:])[0, 1] if len(q50_values) > 12 else np.nan
            
            lag_correlations.append({
                'Lag1': lag1_corr,
                'Lag3': lag3_corr,
                'Lag12': lag12_corr
            })

if lag_correlations:
    lag_df = pd.DataFrame(lag_correlations)
    mean_lag1 = lag_df['Lag1'].mean()
    mean_lag12 = lag_df['Lag12'].mean()
    
    lag1_rec = 'Include 1-month lag features' if mean_lag1 > 0.3 else 'Lag-1 features may not improve model'
    lag12_rec = 'Include 12-month lag features' if mean_lag12 > 0.3 else 'Annual lag features may not be needed'
    
    analysis_results.append({
        'Category': 'Lag_Feature_Necessity',
        'Metric': 'Lag_Correlations',
        'Mean_Lag1_Corr': mean_lag1,
        'Mean_Lag3_Corr': lag_df['Lag3'].mean(),
        'Mean_Lag12_Corr': mean_lag12,
        'Num_Stations_Analyzed': len(lag_df),
        'Lag1_Recommendation': lag1_rec,
        'Lag12_Recommendation': lag12_rec,
        'Detail': 'Lag correlations guide feature engineering decisions'
    })

# ============================================================================
# 12. OPTIMAL FEATURE COUNT ANALYSIS
# ============================================================================
print('12. Determining optimal feature count...')

static_importance_df_sorted = static_importance_df.sort_values('Pearson_r', ascending=False)
static_importance_df_sorted['Cumulative_Sum'] = static_importance_df_sorted['Pearson_r'].cumsum()
static_importance_df_sorted['Cumulative_Pct'] = (static_importance_df_sorted['Cumulative_Sum'] / 
                                                   static_importance_df_sorted['Pearson_r'].sum()) * 100

features_for_80pct = len(static_importance_df_sorted[static_importance_df_sorted['Cumulative_Pct'] <= 80])
features_for_90pct = len(static_importance_df_sorted[static_importance_df_sorted['Cumulative_Pct'] <= 90])

rec_features = f'Use top {features_for_80pct} features for 80% importance or {features_for_90pct} for 90% importance'
analysis_results.append({
    'Category': 'Optimal_Feature_Count',
    'Metric': 'Cumulative_Importance_Thresholds',
    'Features_for_80pct_Importance': features_for_80pct,
    'Features_for_90pct_Importance': features_for_90pct,
    'Total_Features': len(static_importance_df_sorted),
    'Recommendation': rec_features,
    'Detail': 'Feature count optimization balances performance and model complexity'
})

# ============================================================================
# 13. TEMPORAL VS STATIC FEATURE IMPORTANCE BALANCE
# ============================================================================
print('13. Computing temporal vs static feature importance balance...')

static_total = static_importance_df[static_importance_df['Predictor_Type'] == 'Static']['Pearson_r'].sum()
dynamic_total = static_importance_df[static_importance_df['Predictor_Type'] == 'Dynamic']['Pearson_r'].sum()
total_importance = static_total + dynamic_total

rec_balance = 'Focus on static features' if static_total > dynamic_total else 'Dynamic features are equally important'
analysis_results.append({
    'Category': 'Feature_Type_Importance_Balance',
    'Metric': 'Static_vs_Dynamic_Contribution',
    'Static_Importance_Sum': static_total,
    'Dynamic_Importance_Sum': dynamic_total,
    'Static_Pct': (static_total / total_importance * 100) if total_importance > 0 else 0,
    'Dynamic_Pct': (dynamic_total / total_importance * 100) if total_importance > 0 else 0,
    'Recommendation': rec_balance,
    'Detail': 'Balance between terrain/soil vs climate features'
})

# ============================================================================
# 14. SPATIAL AUTOCORRELATION ASSESSMENT (CORRECTED FOR EQUIDISTANT PROJECTION)
# ============================================================================
print('14. Computing spatial autocorrelation with proper coordinate handling...')

spatial_data = df_analysis.drop_duplicates(subset=['IDr'])[['IDr', 'Xcoord', 'Ycoord']].copy()

if len(spatial_data) > 10:
    coords = spatial_data[['Xcoord', 'Ycoord']].values
    distances = cdist(coords, coords, metric='euclidean')
    
    station_q50 = df_analysis.groupby('IDr')['Q50'].mean().to_dict()
    q50_values = np.array([station_q50.get(idr, np.nan) for idr in spatial_data['IDr']])
    
    distance_bands = [
        (0, 10000, '0-10km'),
        (10000, 25000, '10-25km'),
        (25000, 50000, '25-50km'),
        (50000, 100000, '50-100km'),
        (100000, 500000, '100-500km')
    ]
    
    for dist_min, dist_max, band_label in distance_bands:
        band_correlations = []
        
        for i in range(len(spatial_data)):
            for j in range(i+1, len(spatial_data)):
                dist = distances[i, j]
                
                if dist_min <= dist < dist_max and not np.isnan(q50_values[i]) and not np.isnan(q50_values[j]):
                    corr = np.corrcoef(q50_values[i:i+1], q50_values[j:j+1])[0, 1]
                    band_correlations.append(corr)
        
        if band_correlations:
            mean_corr = np.nanmean(band_correlations)
            spatial_rec = 'Strong spatial pattern - regionalization may help' if mean_corr > 0.4 else 'Weak spatial pattern'
            analysis_results.append({
                'Category': 'Spatial_Autocorrelation_by_Distance',
                'Distance_Band': band_label,
                'Distance_Min_m': dist_min,
                'Distance_Max_m': dist_max,
                'Mean_Q50_Correlation': mean_corr,
                'Std_Correlation': np.nanstd(band_correlations),
                'Num_Station_Pairs': len(band_correlations),
                'Recommendation': spatial_rec,
                'Detail': 'Flow correlation between stations at different distances'
            })

# ============================================================================
# 15. SEASONAL FEATURE ENGINEERING GUIDANCE
# ============================================================================
print('15. Determining seasonal feature engineering needs...')

seasonal_q50_stats = df_analysis.groupby('MM')['Q50'].agg(['mean', 'std', 'count']).reset_index()
seasonal_q50_stats['CV'] = seasonal_q50_stats['std'] / seasonal_q50_stats['mean']

high_var_months = seasonal_q50_stats[seasonal_q50_stats['CV'] > seasonal_q50_stats['CV'].quantile(0.75)]['MM'].tolist()
low_var_months = seasonal_q50_stats[seasonal_q50_stats['CV'] < seasonal_q50_stats['CV'].quantile(0.25)]['MM'].tolist()

seasonal_cv_min = seasonal_q50_stats['CV'].min()
seasonal_cv_max = seasonal_q50_stats['CV'].max()
seasonal_cv_range_str = f'{seasonal_cv_min:.3f} to {seasonal_cv_max:.3f}'

seasonal_rec = 'Use season-specific models or interaction features' if len(high_var_months) > 3 else 'Single model adequate - seasonal variation manageable'
analysis_results.append({
    'Category': 'Seasonal_Feature_Engineering',
    'Metric': 'Month_Variability_Pattern',
    'High_Var_Months': str(high_var_months),
    'Low_Var_Months': str(low_var_months),
    'Seasonal_CV_Range': seasonal_cv_range_str,
    'Recommendation': seasonal_rec,
    'Detail': 'Identifies months with high/low flow variability for feature engineering'
})

# ============================================================================
# 16. DISTRIBUTION SHAPE ACROSS CLUSTERS
# ============================================================================
print('16. Analyzing distribution characteristics by cluster...')

if 'Cluster_ID' in df_analysis.columns or 'Elev_Zone' in df_analysis.columns:
    cluster_col = 'Cluster_ID' if 'Cluster_ID' in df_analysis.columns else 'Elev_Zone'
    
    for cluster_id in df_analysis[cluster_col].unique():
        cluster_data = df_analysis[df_analysis[cluster_col] == cluster_id]['Q50'].dropna()
        
        if len(cluster_data) > 30:
            cluster_skew = skew(cluster_data)
            transform_needed = 'Yes - high skewness' if abs(cluster_skew) > 1 else 'No - relatively normal'
            analysis_results.append({
                'Category': 'Distribution_by_Region',
                'Cluster_ID': cluster_id,
                'Q50_Skewness': cluster_skew,
                'Q50_Kurtosis': kurtosis(cluster_data),
                'Q50_IQR': cluster_data.quantile(0.75) - cluster_data.quantile(0.25),
                'Q50_Range': cluster_data.max() - cluster_data.min(),
                'Num_Observations': len(cluster_data),
                'Transformation_Needed': transform_needed,
                'Detail': 'Distribution characteristics for different regions'
            })

# ============================================================================
# 17. SPATIAL CLUSTERING BY COORDINATES & FLOW STATISTICS
# ============================================================================
print('17. Computing spatial clustering with coordinate-based regions...')

station_stats = df_analysis.groupby('IDr').agg({
    'Xcoord': 'first',
    'Ycoord': 'first',
    'Q50': ['mean', 'std'],
    'Q10': 'mean',
    'Q90': 'mean',
    'QMIN': 'mean',
    'QMAX': 'mean',
    'YYYY': 'count'
}).reset_index()

station_stats.columns = ['IDr', 'Xcoord', 'Ycoord', 'Q50_Mean', 'Q50_Std', 'Q10_Mean', 'Q90_Mean', 'QMIN_Mean', 'QMAX_Mean', 'Num_Obs']

if len(station_stats) > 10:
    from sklearn.preprocessing import StandardScaler
    
    X_cluster = station_stats[['Xcoord', 'Ycoord', 'Q50_Mean']].copy()
    X_cluster_normalized = StandardScaler().fit_transform(X_cluster)
    
    n_clusters = min(6, max(3, len(station_stats) // 15))
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    station_stats['Spatial_Cluster'] = kmeans.fit_predict(X_cluster_normalized)
    
    for cluster_id in range(n_clusters):
        cluster_stations = station_stats[station_stats['Spatial_Cluster'] == cluster_id]
        cluster_df = df_analysis[df_analysis['IDr'].isin(cluster_stations['IDr'])]
        
        q90_q10 = cluster_df['Q90'].mean() / cluster_df['Q10'].mean() if cluster_df['Q10'].mean() > 0 else np.nan
        cluster_detail = f'Geographic region with {len(cluster_stations)} stations'
        analysis_results.append({
            'Category': 'Spatial_Cluster_Characteristics',
            'Cluster_ID': cluster_id,
            'Num_Stations': len(cluster_stations),
            'Num_Observations': len(cluster_df),
            'Xcoord_Center': cluster_stations['Xcoord'].mean(),
            'Ycoord_Center': cluster_stations['Ycoord'].mean(),
            'Xcoord_Range': cluster_stations['Xcoord'].max() - cluster_stations['Xcoord'].min(),
            'Ycoord_Range': cluster_stations['Ycoord'].max() - cluster_stations['Ycoord'].min(),
            'Q50_Mean': cluster_df['Q50'].mean(),
            'Q50_Std': cluster_df['Q50'].std(),
            'Q10_Mean': cluster_df['Q10'].mean(),
            'Q90_Mean': cluster_df['Q90'].mean(),
            'QMIN_Mean': cluster_df['QMIN'].mean(),
            'QMAX_Mean': cluster_df['QMAX'].mean(),
            'Q90_Q10_Ratio': q90_q10,
            'Detail': cluster_detail
        })

# ============================================================================
# 18. QUANTILE-SPECIFIC PATTERNS (QMIN to QMAX)
# ============================================================================
print('18. Analyzing quantile-specific patterns across spatial/temporal dimensions...')

quantile_vars = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']

for quantile_var in quantile_vars:
    if quantile_var in df_analysis.columns:
        seasonal_stats_q = df_analysis.groupby('MM')[quantile_var].agg(['mean', 'std', 'min', 'max']).reset_index()
        
        cv_across_months = seasonal_stats_q['std'].mean() / seasonal_stats_q['mean'].mean() if seasonal_stats_q['mean'].mean() > 0 else np.nan
        
        q_var_note = f'{quantile_var} shows seasonal variability' if cv_across_months > 0.2 else f'{quantile_var} is stable across seasons'
        analysis_results.append({
            'Category': 'Quantile_Temporal_Variability',
            'Quantile': quantile_var,
            'Seasonal_CV': cv_across_months,
            'Mean_Value': seasonal_stats_q['mean'].mean(),
            'Std_Value': seasonal_stats_q['std'].mean(),
            'Min_Monthly': seasonal_stats_q['min'].min(),
            'Max_Monthly': seasonal_stats_q['max'].max(),
            'Recommendation': q_var_note,
            'Detail': f'Seasonal variation in {quantile_var} affects model design'
        })

for quantile_var in quantile_vars:
    if quantile_var in df_analysis.columns:
        spatial_stats_q = df_analysis.groupby('IDr')[quantile_var].agg(['mean', 'std', 'count']).reset_index()
        spatial_stats_q = spatial_stats_q[spatial_stats_q['count'] > 10]
        
        cv_across_stations = spatial_stats_q['std'].mean() / spatial_stats_q['mean'].mean() if spatial_stats_q['mean'].mean() > 0 else np.nan
        
        q_spatial_note = f'{quantile_var} shows spatial heterogeneity' if cv_across_stations > 0.3 else f'{quantile_var} is uniform across space'
        analysis_results.append({
            'Category': 'Quantile_Spatial_Variability',
            'Quantile': quantile_var,
            'Spatial_CV': cv_across_stations,
            'Num_Stations': len(spatial_stats_q),
            'Mean_Value': spatial_stats_q['mean'].mean(),
            'Std_Value': spatial_stats_q['std'].mean(),
            'Min_Station': spatial_stats_q['mean'].min(),
            'Max_Station': spatial_stats_q['mean'].max(),
            'Recommendation': q_spatial_note,
            'Detail': f'Spatial variation in {quantile_var} suggests need for regional models'
        })

# ============================================================================
# 19. QUANTILE SPREAD ANALYSIS (QMAX-QMIN range by season and space)
# ============================================================================
print('19. Computing quantile spread patterns...')

df_analysis['Q_Range'] = df_analysis['QMAX'] - df_analysis['QMIN']
df_analysis['Q_IQR'] = df_analysis['Q90'] - df_analysis['Q10']
df_analysis['Q_Midrange'] = (df_analysis['QMAX'] + df_analysis['QMIN']) / 2

seasonal_spread = df_analysis.groupby('MM').agg({
    'Q_Range': ['mean', 'std'],
    'QMAX': 'mean',
    'QMIN': 'mean',
    'Q50': 'mean'
}).reset_index()

for _, row in seasonal_spread.iterrows():
    month = int(row['MM'])
    qmax_val = row[('QMAX', 'mean')]
    qmin_val = row[('QMIN', 'mean')]
    q50_val = row[('Q50', 'mean')]
    
    qmax_q50_ratio = qmax_val / q50_val if q50_val > 0 else np.nan
    q50_qmin_ratio = q50_val / qmin_val if qmin_val > 0 else np.nan
    
    analysis_results.append({
        'Category': 'Quantile_Spread_Seasonal',
        'Month': month,
        'Mean_Q_Range_QMAX_QMIN': row[('Q_Range', 'mean')],
        'Std_Q_Range': row[('Q_Range', 'std')],
        'Mean_QMAX': qmax_val,
        'Mean_QMIN': qmin_val,
        'Mean_Q50': q50_val,
        'QMAX_Q50_Ratio': qmax_q50_ratio,
        'Q50_QMIN_Ratio': q50_qmin_ratio,
        'Detail': 'Variability envelope changes with season'
    })

spatial_spread = df_analysis.groupby('IDr').agg({
    'Q_Range': ['mean', 'std'],
    'QMAX': 'mean',
    'QMIN': 'mean',
    'Q50': 'mean',
    'YYYY': 'count'
}).reset_index()
spatial_spread.columns = ['IDr', 'Q_Range_Mean', 'Q_Range_Std', 'QMAX_Mean', 'QMIN_Mean', 'Q50_Mean', 'Num_Obs']
spatial_spread = spatial_spread[spatial_spread['Num_Obs'] > 10]

high_spread_stations = spatial_spread[spatial_spread['Q_Range_Mean'] > spatial_spread['Q_Range_Mean'].quantile(0.75)]
low_spread_stations = spatial_spread[spatial_spread['Q_Range_Mean'] < spatial_spread['Q_Range_Mean'].quantile(0.25)]

spread_std = spatial_spread['Q_Range_Mean'].std()
spread_mean = spatial_spread['Q_Range_Mean'].mean()
spread_rec = 'Large spatial variation in flow spread - consider separate quantile models by region' if spread_std > spread_mean * 0.3 else 'Uniform spread across stations'
analysis_results.append({
    'Category': 'Quantile_Spread_Spatial',
    'Metric': 'Q_Range_Variability_Across_Stations',
    'Mean_Q_Range': spread_mean,
    'Std_Q_Range': spread_std,
    'Min_Q_Range': spatial_spread['Q_Range_Mean'].min(),
    'Max_Q_Range': spatial_spread['Q_Range_Mean'].max(),
    'Num_High_Spread_Stations': len(high_spread_stations),
    'Num_Low_Spread_Stations': len(low_spread_stations),
    'Recommendation': spread_rec,
    'Detail': 'Quantile envelope characteristics for different stations'
})

# ============================================================================
# 20. TEMPORAL CONSISTENCY BY QUANTILE (Year-to-Year Patterns)
# ============================================================================
print('20. Analyzing year-to-year consistency of quantiles...')

for quantile_var in ['QMIN', 'Q10', 'Q50', 'Q90', 'QMAX']:
    if quantile_var in df_analysis.columns:
        annual_q = df_analysis.groupby('YYYY')[quantile_var].agg(['mean', 'std', 'count']).reset_index()
        
        cv_across_years = annual_q['std'].mean() / annual_q['mean'].mean() if annual_q['mean'].mean() > 0 else np.nan
        
        annual_rec = f'{quantile_var} varies significantly across years - consider year effects' if cv_across_years > 0.15 else f'{quantile_var} is consistent across years'
        analysis_results.append({
            'Category': 'Quantile_Annual_Consistency',
            'Quantile': quantile_var,
            'Annual_CV': cv_across_years,
            'Mean_Annual_Value': annual_q['mean'].mean(),
            'Min_Year': annual_q['mean'].min(),
            'Max_Year': annual_q['mean'].max(),
            'Num_Years': len(annual_q),
            'Recommendation': annual_rec,
            'Detail': f'Temporal stability of {quantile_var} for model design'
        })

# ============================================================================
# SAVE RESULTS TO CSV
# ============================================================================

results_df = pd.DataFrame(analysis_results)

output_path = '../predict_analysis_red/spatio-temporal-statistical.csv'
os.makedirs(os.path.dirname(output_path), exist_ok=True)
results_df.to_csv(output_path, index=False)

print(f'\n✓ Spatio-temporal analysis complete!')
print(f'✓ Results saved to: {output_path}')
print(f'✓ Total metrics: {len(results_df)}')
print(f'\nAnalysis categories:')
for category in sorted(results_df['Category'].unique()):
    count = len(results_df[results_df['Category'] == category])
    print(f'  - {category}: {count} metrics')

PYTHON_EOF
"
# close the sif
exit