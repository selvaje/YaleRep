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
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy.stats import pearsonr, spearmanr, skew, kurtosis
from scipy.spatial.distance import cdist
from joblib import Parallel, delayed
import psutil

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_i = int(os.environ['obs_split'])
depth_i = int(os.environ['depth'])
sample_f = float(os.environ['sample'])
N_EST_I = int(os.environ['N_EST'])

print(f'Config: N_EST={N_EST_I}, leaf={obs_leaf_i}, split={obs_split_i}, depth={depth_i}, sample={sample_f}')

static_var = ['cti', 'spi', 'sti', 'accumulation', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch', 'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near', 'stream_dist_dw_near', 'stream_dist_proximity', 'stream_dist_up_farth', 'stream_dist_up_near', 'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg', 'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP', 'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe', 'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo', 'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine', 'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev', 'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale', 'slope', 'tcurv', 'tpi', 'tri', 'vrm']

dynamic_var = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3', 'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3', 'soil0', 'soil1', 'soil2', 'soil3']

dynamic_bases = ['ppt', 'tmin', 'tmax', 'swe', 'soil']

dtypes_X = {'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32', 'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32'}

climate_soil_cols = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3', 'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3', 'soil0', 'soil1', 'soil2', 'soil3']

feature_cols = ['cti', 'spi', 'sti', 'accumulation', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch', 'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near', 'stream_dist_dw_near', 'stream_dist_proximity', 'stream_dist_up_farth', 'stream_dist_up_near', 'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg', 'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP', 'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe', 'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo', 'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine', 'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev', 'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale', 'slope', 'tcurv', 'tpi', 'tri', 'vrm']

dtypes_X.update({col: 'int32' for col in climate_soil_cols if col not in dtypes_X})
dtypes_X.update({col: 'float32' for col in feature_cols})

dtypes_Y = {'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32', 'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32'}
dtypes_Y.update({col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']})

def load_with_dtypes(filepath, usecols=None, dtype_dict=None, chunksize=50000):
    chunks = []
    for chunk in pd.read_csv(filepath, header=0, sep='\s+', usecols=usecols, dtype=dtype_dict, engine='c', chunksize=chunksize):
        chunks.append(chunk)
        if len(chunks) % 10 == 0:
            gc.collect()
    return pd.concat(chunks, ignore_index=True) if chunks else pd.DataFrame()

print('Loading data...')
importance = pd.read_csv('varX_list.txt', header=None, sep='\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
include_variables.extend(['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'])

Y = load_with_dtypes('stationID_x_y_valueALL_predictors_Y_floredSFD.txt', dtype_dict=dtypes_Y)
X = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', usecols=lambda col: col in include_variables, dtype_dict=dtypes_X)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

df_analysis = pd.merge(X, Y, on=['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'], how='inner')
print(f'Merged data shape: {df_analysis.shape}')

analysis_results = []

print('Computing analyses 1-20...')

output_vars = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
for output_var in output_vars:
    if output_var in df_analysis.columns:
        q_data = df_analysis[output_var].dropna()
        analysis_results.append({'Category': 'Global_Output_Statistics', 'Metric': output_var, 'Mean': q_data.mean(), 'Std': q_data.std(), 'Min': q_data.min(), 'Max': q_data.max(), 'Median': q_data.median(), 'Skewness': skew(q_data), 'Kurtosis': kurtosis(q_data), 'CV': q_data.std() / q_data.mean() if q_data.mean() != 0 else np.nan, 'Detail': 'Distribution shape'})

seasonal_stats = df_analysis.groupby('MM').agg({'Q50': ['mean', 'std', 'count'], 'Q10': 'mean', 'Q90': 'mean'}).reset_index()
for _, row in seasonal_stats.iterrows():
    month = int(row['MM'])
    analysis_results.append({'Category': 'Temporal_Seasonal_Pattern', 'Temporal_Level': f'Month_{month:02d}', 'Q50_Mean': row[('Q50', 'mean')], 'Q50_Std': row[('Q50', 'std')], 'Num_Observations': int(row[('Q50', 'count')]), 'Detail': 'Seasonal variability'})

spatial_summary = df_analysis.groupby('IDr').agg({'Xcoord': 'first', 'Ycoord': 'first', 'Q50': ['mean', 'std', 'count'], 'YYYY': ['min', 'max']}).reset_index()
spatial_summary.columns = ['IDr', 'Xcoord', 'Ycoord', 'Q50_mean', 'Q50_std', 'Num_obs', 'Year_min', 'Year_max']

static_features = [col for col in static_var if col in df_analysis.columns]
clusters = None
if static_features:
    station_static = df_analysis.drop_duplicates(subset=['IDr'])[['IDr'] + static_features].set_index('IDr').fillna(df_analysis[static_features].mean())
    station_static_norm = StandardScaler().fit_transform(station_static)
    n_clust = min(5, max(3, len(station_static) // 20))
    kmeans = KMeans(n_clusters=n_clust, random_state=42, n_init=10)
    clusters = kmeans.fit_predict(station_static_norm)
    
    for cid in range(n_clust):
        c_stations = station_static.index[clusters == cid]
        c_data = df_analysis[df_analysis['IDr'].isin(c_stations)]
        q50_mean = c_data['Q50'].mean()
        q50_std = c_data['Q50'].std()
        q50_cv = q50_std / q50_mean if q50_mean != 0 else np.nan
        analysis_results.append({'Category': 'Spatial_Regional_Cluster', 'Cluster_ID': cid, 'Num_Stations': len(c_stations), 'Q50_Mean': q50_mean, 'Q50_CV': q50_cv, 'Detail': 'Spatial clustering'})

static_importance = []
for var_name in static_var:
    if var_name in df_analysis.columns:
        vd = df_analysis[[var_name, 'Q50']].dropna()
        if len(vd) > 2:
            pr, pp = pearsonr(vd[var_name], vd['Q50'])
            static_importance.append({'Predictor_Type': 'Static', 'Predictor': var_name, 'Pearson_r': abs(pr), 'Num_Samples': len(vd)})

for var_name in dynamic_var:
    if var_name in df_analysis.columns:
        vd = df_analysis[[var_name, 'Q50']].dropna()
        if len(vd) > 2:
            pr, pp = pearsonr(vd[var_name], vd['Q50'])
            static_importance.append({'Predictor_Type': 'Dynamic', 'Predictor': var_name, 'Pearson_r': abs(pr), 'Num_Samples': len(vd)})

static_importance_df = pd.DataFrame(static_importance).sort_values('Pearson_r', ascending=False)
for rank, (_, row) in enumerate(static_importance_df.head(30).iterrows(), 1):
    analysis_results.append({'Category': 'Predictor_Importance_Top30', 'Rank': rank, 'Predictor': row['Predictor'], 'Pearson_r': row['Pearson_r'], 'Detail': 'Top predictors'})

sample_stations = df_analysis['IDr'].unique()[:min(50, len(df_analysis['IDr'].unique()))]
autocorr_results = []
for sid in sample_stations:
    sd = df_analysis[df_analysis['IDr'] == sid].sort_values(['YYYY', 'MM'])
    if len(sd) > 12:
        qv = sd['Q50'].dropna().values
        if len(qv) > 1:
            autocorr_results.append(np.corrcoef(qv[:-1], qv[1:])[0, 1])

if autocorr_results:
    analysis_results.append({'Category': 'Temporal_Autocorrelation', 'Metric': 'Lag1_Autocorrelation', 'Mean': np.nanmean(autocorr_results), 'Detail': 'Temporal dependency'})

if 'ppt0' in df_analysis.columns and 'elev' in df_analysis.columns:
    df_analysis['Elev_Zone'] = pd.qcut(df_analysis['elev'], q=3, labels=['Low', 'Mid', 'High'], duplicates='drop')
    for zone in df_analysis['Elev_Zone'].unique():
        zd = df_analysis[df_analysis['Elev_Zone'] == zone]
        vd = zd[['ppt0', 'Q50']].dropna()
        if len(vd) > 2:
            pc, pp = pearsonr(vd['ppt0'], vd['Q50'])
            analysis_results.append({'Category': 'Spatial_Temporal_Interaction', 'Elevation_Zone': str(zone), 'Ppt_Q50_Correlation': pc, 'Detail': 'Dynamic-spatial'})

analysis_results.append({'Category': 'Data_Quality_Spatial_Coverage', 'Num_Stations': df_analysis['IDr'].nunique(), 'Num_Observations': len(df_analysis), 'Temporal_Span_Years': int(df_analysis['YYYY'].max() - df_analysis['YYYY'].min() + 1), 'Detail': 'Data assessment'})

seasonal_cv = seasonal_stats[('Q50', 'std')].mean() / seasonal_stats[('Q50', 'mean')].mean()

rec_seasonal = 'Strong seasonal - use temporal features' if seasonal_cv > 0.3 else 'Weak seasonal'
rec_regional = 'Regional models - many stations' if len(spatial_summary) > 30 else 'Global model'
has_autocorr = len(autocorr_results) > 0 and np.nanmean(autocorr_results) > 0.4
rec_lag = 'Include lag features' if has_autocorr else 'No lag needed'

recommendations = [rec_seasonal, rec_regional, rec_lag]
for i, rec in enumerate(recommendations, 1):
    analysis_results.append({'Category': 'Model_Design_Recommendation', 'Recommendation_ID': i, 'Recommendation': rec, 'Detail': 'Based on patterns'})

top_static = static_importance_df[static_importance_df['Predictor_Type'] == 'Static'].head(15)['Predictor'].tolist()
if len(top_static) > 1:
    cm = df_analysis[top_static].corr()
    hcp = 0
    for i in range(len(cm.columns)):
        for j in range(i+1, len(cm.columns)):
            if abs(cm.iloc[i, j]) > 0.7:
                hcp += 1
    analysis_results.append({'Category': 'Feature_Multicollinearity', 'Num_High_Corr_Pairs': hcp, 'Detail': 'Multicollinearity check'})

station_het = []
for sid in df_analysis['IDr'].unique():
    sd = df_analysis[df_analysis['IDr'] == sid]
    if len(sd) > 10:
        qv = sd['Q50'].values
        station_het.append(qv.std() / qv.mean() if qv.mean() != 0 else np.nan)

if station_het:
    analysis_results.append({'Category': 'Station_Level_Heterogeneity', 'Q50_CV_Mean': np.nanmean(station_het), 'Q50_CV_Std': np.nanstd(station_het), 'Detail': 'Station variability'})

lag_corr = []
for sid in df_analysis['IDr'].unique()[:min(30, len(df_analysis['IDr'].unique()))]:
    sd = df_analysis[df_analysis['IDr'] == sid].sort_values(['YYYY', 'MM'])
    if len(sd) > 24:
        qv = sd['Q50'].dropna().values
        if len(qv) > 2:
            lag_corr.append(np.corrcoef(qv[:-1], qv[1:])[0, 1])

if lag_corr:
    analysis_results.append({'Category': 'Lag_Feature_Necessity', 'Mean_Lag1_Corr': np.nanmean(lag_corr), 'Detail': 'Lag analysis'})

print('Computing analyses 21-30...')

print('21. Variable interaction effects...')
top_static_list = static_importance_df[static_importance_df['Predictor_Type'] == 'Static'].head(10)['Predictor'].tolist()
if len(top_static_list) >= 2:
    for i in range(len(top_static_list)):
        for j in range(i+1, min(i+3, len(top_static_list))):
            v1, v2 = top_static_list[i], top_static_list[j]
            vd = df_analysis[[v1, v2, 'Q50']].dropna()
            if len(vd) > 10:
                it = vd[v1] * vd[v2]
                cint, _ = pearsonr(it, vd['Q50'])
                c1, _ = pearsonr(vd[v1], vd['Q50'])
                c2, _ = pearsonr(vd[v2], vd['Q50'])
                if abs(cint) > max(abs(c1), abs(c2)) * 0.5:
                    analysis_results.append({'Category': 'Variable_Interaction_Analysis', 'Var1': v1, 'Var2': v2, 'Interaction_Correlation': abs(cint), 'Detail': 'Top interactions'})

print('22. Predictability by flow magnitude...')
flow_regimes = [('Low', (0, df_analysis['Q50'].quantile(0.33))), ('Medium', (df_analysis['Q50'].quantile(0.33), df_analysis['Q50'].quantile(0.67))), ('High', (df_analysis['Q50'].quantile(0.67), df_analysis['Q50'].max()))]
for regime_name, (qmin, qmax) in flow_regimes:
    rd = df_analysis[(df_analysis['Q50'] >= qmin) & (df_analysis['Q50'] <= qmax)]
    if len(rd) > 10:
        q50cv = rd['Q50'].std() / rd['Q50'].mean() if rd['Q50'].mean() != 0 else np.nan
        analysis_results.append({'Category': 'Predictability_by_Flow_Magnitude', 'Flow_Regime': regime_name, 'Q50_CV': q50cv, 'Num_Obs': len(rd), 'Detail': 'Flow regime analysis'})

print('23. Feature engineering recommendations...')
for db in dynamic_bases:
    lvars = [f'{db}0', f'{db}1', f'{db}2', f'{db}3']
    lvars_data = [c for c in lvars if c in df_analysis.columns]
    if len(lvars_data) > 1:
        corrs = []
        for lv in lvars_data:
            vd = df_analysis[[lv, 'Q50']].dropna()
            if len(vd) > 2:
                corrs.append(abs(pearsonr(vd[lv], vd['Q50'])[0]))
        if corrs:
            mc = max(corrs)
            if mc > 0.3:
                rec = f'Include {db} 3-month lag'
            elif mc > 0.15:
                rec = f'Include {db} 1-month lag'
            else:
                rec = f'Use current {db}'
            analysis_results.append({'Category': 'Feature_Engineering_Recommendations', 'Dynamic_Variable': db, 'Max_Lag_Correlation': mc, 'Recommendation': rec, 'Detail': 'Lag windows'})

print('24. Spatial clustering quality...')
if clusters is not None:
    analysis_results.append({'Category': 'Clustering_Quality', 'Metric': 'Spatial_Quality', 'Avg_Clusters': len(set(clusters)), 'Detail': 'Cluster assessment'})

print('25. Seasonal model necessity...')
seasons = {'DJF': [12, 1, 2], 'MAM': [3, 4, 5], 'JJA': [6, 7, 8], 'SON': [9, 10, 11]}
for sname, months in seasons.items():
    sd = df_analysis[df_analysis['MM'].isin(months)]
    if len(sd) > 50:
        analysis_results.append({'Category': 'Seasonal_Model_Necessity', 'Season': sname, 'Num_Observations': len(sd), 'Q50_Mean': sd['Q50'].mean(), 'Detail': 'Seasonal necessity'})

print('26. Quantile-specific model requirements...')
for qvar in ['QMIN', 'Q50', 'QMAX']:
    if qvar in df_analysis.columns:
        seasonal_q = df_analysis.groupby('MM')[qvar].agg(['mean', 'std']).reset_index()
        cv = seasonal_q['std'].mean() / seasonal_q['mean'].mean() if seasonal_q['mean'].mean() > 0 else np.nan
        analysis_results.append({'Category': 'Quantile_Requirements', 'Quantile': qvar, 'Seasonal_CV': cv, 'Detail': 'Quantile variability'})

print('27. Station-specific feature importance...')
for sid in df_analysis['IDr'].unique()[:min(5, len(df_analysis['IDr'].unique()))]:
    sd = df_analysis[df_analysis['IDr'] == sid]
    if len(sd) > 20:
        best_pred = None
        best_corr = 0
        for var in static_importance_df.head(5)['Predictor'].tolist():
            if var in sd.columns:
                vd = sd[[var, 'Q50']].dropna()
                if len(vd) > 5:
                    corr, _ = pearsonr(vd[var], vd['Q50'])
                    if abs(corr) > best_corr:
                        best_corr = abs(corr)
                        best_pred = var
        if best_pred:
            analysis_results.append({'Category': 'Station_Specific_Importance', 'Station_ID': int(sid), 'Best_Predictor': best_pred, 'Correlation': best_corr, 'Detail': 'Station-level'})

print('28. Temporal stability assessment...')
for qvar in ['Q10', 'Q50', 'Q90']:
    if qvar in df_analysis.columns:
        annual_q = df_analysis.groupby('YYYY')[qvar].agg(['mean', 'std']).reset_index()
        cv = annual_q['std'].mean() / annual_q['mean'].mean() if annual_q['mean'].mean() > 0 else np.nan
        analysis_results.append({'Category': 'Temporal_Stability', 'Quantile': qvar, 'Annual_CV': cv, 'Num_Years': len(annual_q), 'Detail': 'Year-to-year stability'})

print('29. Optimal hyperparameter guidelines...')
static_importance_df_sorted = static_importance_df.sort_values('Pearson_r', ascending=False)
static_importance_df_sorted['Cumulative_Sum'] = static_importance_df_sorted['Pearson_r'].cumsum()
static_importance_df_sorted['Cumulative_Pct'] = (static_importance_df_sorted['Cumulative_Sum'] / static_importance_df_sorted['Pearson_r'].sum()) * 100
features_for_80pct = len(static_importance_df_sorted[static_importance_df_sorted['Cumulative_Pct'] <= 80])

n_features = min(features_for_80pct, 50)
max_depth_rec = int(np.sqrt(len(df_analysis)))
analysis_results.append({'Category': 'RF_Hyperparameter_Guidelines', 'Recommended_N_Features': n_features, 'Recommended_Max_Depth': max_depth_rec, 'Recommended_N_Estimators': 100, 'Detail': 'RF tuning guide'})

print('30. Final comprehensive model design summary...')
n_stations = df_analysis['IDr'].nunique()
temporal_years = int(df_analysis['YYYY'].max() - df_analysis['YYYY'].min() + 1)
regionalization_needed = 'Yes - use regional models' if n_stations > 50 else 'No - global model'
temporal_features_needed = 'Yes - include temporal features' if seasonal_cv > 0.3 else 'No'
has_lag = len(lag_corr) > 0 and np.nanmean(lag_corr) > 0.3
lag_features_needed = 'Yes - include lag features' if has_lag else 'No'

static_total = static_importance_df[static_importance_df['Predictor_Type'] == 'Static']['Pearson_r'].sum()
dynamic_total = static_importance_df[static_importance_df['Predictor_Type'] == 'Dynamic']['Pearson_r'].sum()
total_imp = static_total + dynamic_total
static_pct = (static_total / total_imp * 100) if total_imp > 0 else 0

top_feature = static_importance_df.iloc[0]['Predictor'] if len(static_importance_df) > 0 else 'N/A'

analysis_results.append({
    'Category': 'Final_Model_Design_Summary',
    'Total_Stations': n_stations,
    'Temporal_Span_Years': temporal_years,
    'Total_Observations': len(df_analysis),
    'Recommended_Regionalization': regionalization_needed,
    'Include_Temporal_Features': temporal_features_needed,
    'Include_Lag_Features': lag_features_needed,
    'Top_Feature': top_feature,
    'Static_Features_Importance_Pct': static_pct,
    'Num_Features_Recommended': n_features,
    'Detail': 'Complete RF model design strategy'
})

print('✓ All 30 analyses complete!')

results_df = pd.DataFrame(analysis_results)

output_path = '../predict_analysis_red/spatio-temporal-statistical30.csv'
os.makedirs(os.path.dirname(output_path), exist_ok=True)
results_df.to_csv(output_path, index=False)

print(f'✓ Results saved to: {output_path}')
print(f'✓ Total metrics: {len(results_df)}')
print(f'✓ Categories: {len(results_df[\"Category\"].unique())}')
print(f'\nAnalysis categories:')
for category in sorted(results_df['Category'].unique()):
    count = len(results_df[results_df['Category'] == category])
    print(f'  - {category}: {count} metrics')

PYTHON_EOF
"
# close the sif
exit
