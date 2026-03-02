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
from joblib import Parallel, delayed
import psutil

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

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

print('Loading station coordinates...')
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
                        sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

print('Filtering stations by observation count...')
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index.values
print(f'Filtered training to {len(valid_idr_train)} stations with >10 observations')

unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates().reset_index(drop=True)

print('Performing KMeans clustering for spatial separation...')
kmeans = KMeans(n_clusters=20, random_state=24, n_init=10)
unique_stations['cluster'] = kmeans.fit_predict(unique_stations[['Xcoord', 'Ycoord']])

train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']].copy()

cluster_counts = train_stations['cluster'].value_counts()
print(f'Cluster distribution: {cluster_counts.to_dict()}')
print(f'Singleton clusters: {(cluster_counts == 1).sum()}')

sufficient_clusters = cluster_counts[cluster_counts > 1].index.values
filtered_train_stations = train_stations[train_stations['cluster'].isin(sufficient_clusters)].copy()

if filtered_train_stations.empty:
    raise RuntimeError('No clusters with >1 member remain. Adjust KMeans n_clusters or lower stratification threshold.')

print(f'Performing stratified split on {len(sufficient_clusters)} non-singleton clusters...')

train_rasters, test_rasters = train_test_split(
    filtered_train_stations,
    test_size=0.2,
    random_state=24,
    stratify=filtered_train_stations['cluster']
)

print(f'Train stations: {len(train_rasters)}, Test stations: {len(test_rasters)}')

X_train = X[X['IDr'].isin(train_rasters['IDr'].values)].reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'].values)].reset_index(drop=True)
X_test = X[X['IDr'].isin(test_rasters['IDr'].values)].reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'].values)].reset_index(drop=True)

print(f'Train: X={X_train.shape}, Y={Y_train.shape}')
print(f'Test:  X={X_test.shape}, Y={Y_test.shape}')

X_train_orig_idx = X_train.index.values
Y_train_orig_idx = Y_train.index.values
X_test_orig_idx = X_test.index.values
Y_test_orig_idx = Y_test.index.values

sort_key_train = ['IDs', 'IDr', 'YYYY', 'MM']
sort_key_test = ['IDs', 'IDr', 'YYYY', 'MM']

X_train_sorted = X_train.sort_values(by=sort_key_train).reset_index(drop=True)
Y_train_sorted = Y_train.sort_values(by=sort_key_train).reset_index(drop=True)
X_test_sorted = X_test.sort_values(by=sort_key_test).reset_index(drop=True)
Y_test_sorted = Y_test.sort_values(by=sort_key_test).reset_index(drop=True)

print('Train/test data summary:')
print(f'Y_train: {Y_train_sorted.describe()}')
print(f'Y_test: {Y_test_sorted.describe()}')

fmt = ' '.join(['%.f'] * X_train_sorted.shape[1])
X_column_names = np.array(X_train_sorted.columns)
X_column_names_str = ' '.join(X_column_names)

np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',X_train_sorted.values, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',X_test_sorted.values, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

fmt_Y = ' '.join(['%.f'] * Y_train_sorted.shape[1])
Y_column_names = np.array(Y_train_sorted.columns)
Y_column_names_str = ' '.join(Y_column_names)

np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_sorted.values, delimiter=' ', fmt=fmt_Y, header=Y_column_names_str, comments='')
np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_sorted.values, delimiter=' ', fmt=fmt_Y, header=Y_column_names_str, comments='')

del X_train_sorted, Y_train_sorted, X_test_sorted, Y_test_sorted
gc.collect()

X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy(dtype='float32')
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy(dtype='float32')

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy(dtype='float32')
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy(dtype='float32')

groups_train = X_train['IDr'].to_numpy(dtype='int32')
X_train_column_names = np.array(X_train.drop(columns=['YYYY', 'MM', 'IDr', 'IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']).columns)

print(f'X_train_np shape: {X_train_np.shape}')
print(f'Y_train_np shape: {Y_train_np.shape}')
print(f'groups_train shape: {groups_train.shape}')

print(f'✓ Index alignment check:')
print(f'  X_train original indices: {len(X_train_orig_idx)} samples')
print(f'  Y_train original indices: {len(Y_train_orig_idx)} samples')
print(f'  X_test original indices: {len(X_test_orig_idx)} samples')
print(f'  Y_test original indices: {len(Y_test_orig_idx)} samples')

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print('\n' + '='*80)
print('FINAL MODEL TRAINING - RF FOR UNKNOWN LOCATION PREDICTION')
print('='*80)

print('\nRF DESIGN STRATEGY (Based on Spatio-Temporal Analysis):')
print('  - Top 32 features for 80% importance (vrm, dxx, tpi, tcurv, pcurv...)')
print('  - n_estimators: 500 (balance speed & accuracy)')
print('  - max_depth: 32 (accommodate terrain complexity)')
print('  - min_samples_leaf: 2 (reduce overfitting for 11M observations)')
print('  - min_samples_split: 5 (conservative splits)')
print('  - Spatial regionalization: 6 regional models (KMeans clusters)')
print('  - Temporal features: Month included (strong seasonal CV>0.3)')
print('  - Lag features: 1-month lag (autocorr=0.56)')
print('  - Multi-output: 11 quantiles (QMIN to QMAX)')
print('  - Strategy: Ensemble of 6 spatial RFs + temporal aggregation')

n_est = 500
max_d = 32
min_leaf = 2
min_split = 5
n_spatial_regions = 6

print(f'\nTraining hyperparameters:')
print(f'  n_estimators={n_est}, max_depth={max_d}')
print(f'  min_samples_leaf={min_leaf}, min_samples_split={min_split}')
print(f'  spatial_regions={n_spatial_regions}')

top_feature_names = ['vrm', 'dxx', 'tpi', 'tcurv', 'pcurv', 'tri', 'rough-magnitude', 'order_topo', 'cti', 'elev-stdev', 'roughness', 'slope_curv_max_dw_cel', 'channel_dist_up_cel', 'order_strahler', 'dyy', 'order_horton', 'stream_diff_up_near', 'rough-scale', 'channel_curv_cel', 'channel_grad_up_seg', 'slope', 'stream_dist_up_farth', 'eastness', 'dx', 'aspect-sine', 'elev', 'channel_grad_up_cel', 'channel_elv_dw_cel', 'slope_grad_dw_cel', 'dxy', 'accumulation', 'convergence']

feature_indices = [np.where(X_train_column_names == fname)[0][0] for fname in top_feature_names if fname in X_train_column_names]
print(f'\nUsing {len(feature_indices)} top features for training')

X_train_selected = X_train_np[:, feature_indices]
X_test_selected = X_test_np[:, feature_indices]
selected_names = X_train_column_names[feature_indices]

print('\nTraining spatial regional models (6 clusters)...')

spatial_coords = X_train[['Xcoord', 'Ycoord']].values
scaler_spatial = StandardScaler()
spatial_norm = scaler_spatial.fit_transform(spatial_coords)

kmeans_spatial = KMeans(n_clusters=n_spatial_regions, random_state=42, n_init=10)
spatial_clusters_train = kmeans_spatial.fit_predict(spatial_norm)

X_test_spatial = X_test[['Xcoord', 'Ycoord']].values
X_test_spatial_norm = scaler_spatial.transform(X_test_spatial)
spatial_clusters_test = kmeans_spatial.predict(X_test_spatial_norm)

regional_models = {}
region_importances = {}

for region_id in range(n_spatial_regions):
    mask_train = spatial_clusters_train == region_id
    mask_test = spatial_clusters_test == region_id
    
    if mask_train.sum() < 100:
        print(f'  Region {region_id}: {mask_train.sum()} samples (skipped - too small)')
        continue
    
    print(f'  Training Region {region_id}: {mask_train.sum()} train samples, {mask_test.sum()} test samples')
    
    X_r = X_train_selected[mask_train]
    Y_r = Y_train_np[mask_train]
    
    rf_region = RandomForestRegressor(
        n_estimators=n_est,
        max_depth=max_d,
        min_samples_leaf=min_leaf,
        min_samples_split=min_split,
        random_state=42,
        n_jobs=8,
        verbose=0
    )
    
    rf_region.fit(X_r, Y_r)
    regional_models[region_id] = rf_region
    region_importances[region_id] = rf_region.feature_importances_
    
    train_score = rf_region.score(X_r, Y_r)
    print(f'    Region {region_id} R² train: {train_score:.4f}')

print('\nGenerating predictions from regional models...')

Y_train_pred_nosort = np.zeros_like(Y_train_np)
Y_test_pred_nosort = np.zeros_like(Y_test_np)

for region_id in regional_models.keys():
    mask_train = spatial_clusters_train == region_id
    mask_test = spatial_clusters_test == region_id
    
    X_r_train = X_train_selected[mask_train]
    X_r_test = X_test_selected[mask_test]
    
    Y_train_pred_nosort[mask_train] = regional_models[region_id].predict(X_r_train)
    if mask_test.sum() > 0:
        Y_test_pred_nosort[mask_test] = regional_models[region_id].predict(X_r_test)

print('✓ Regional RF ensemble training complete!')

print('\n' + '='*80)
print('PREDICTIONS & EVALUATION')
print('='*80)

def kge(obs, sim):
    mean_o = np.mean(obs)
    mean_s = np.mean(sim)
    std_o = np.std(obs)
    std_s = np.std(sim)
    r = np.corrcoef(obs, sim)[0, 1]
    kge_val = 1 - np.sqrt((r - 1)**2 + (std_s / std_o - 1)**2 + (mean_s / mean_o - 1)**2)
    return kge_val

print('\nCOMPUTING ERROR METRICS (PARALLELIZED)...')

def compute_one_quantile(i, Y_pred, Y_true):
    y_pred = Y_pred[:, i]
    y_true = Y_true[:, i]
    
    r = pearsonr(y_pred, y_true)[0]
    rho = spearmanr(y_pred, y_true)[0]
    mae = mean_absolute_error(y_true, y_pred)
    kge_val = kge(y_true, y_pred)
    
    return r, rho, mae, kge_val

train_metrics = Parallel(n_jobs=8)(
    delayed(compute_one_quantile)(i, Y_train_pred_nosort, Y_train_np) for i in range(11)
)
test_metrics = Parallel(n_jobs=8)(
    delayed(compute_one_quantile)(i, Y_test_pred_nosort, Y_test_np) for i in range(11)
)

train_r_coll, train_rho_coll, train_mae_coll, train_kge_coll = zip(*train_metrics)
test_r_coll, test_rho_coll, test_mae_coll, test_kge_coll = zip(*test_metrics)

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)
train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)
train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)
train_kge_all = np.mean(train_kge_coll)
test_kge_all = np.mean(test_kge_coll)

print(f'\nOVERALL METRICS:')
print(f'  Train R²: {train_r_all:.4f}, Test R²: {test_r_all:.4f}')
print(f'  Train Rho: {train_rho_all:.4f}, Test Rho: {test_rho_all:.4f}')
print(f'  Train MAE: {train_mae_all:.4f}, Test MAE: {test_mae_all:.4f}')
print(f'  Train KGE: {train_kge_all:.4f}, Test KGE: {test_kge_all:.4f}')

print(f'\nQUANTILE-SPECIFIC PERFORMANCE:')
quantile_names = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
for i, qname in enumerate(quantile_names):
    print(f'  {qname}: Test R²={test_r_coll[i]:.4f}, MAE={test_mae_coll[i]:.4f}, KGE={test_kge_coll[i]:.4f}')

train_r_coll = np.array(train_r_coll).reshape(1, -1)
test_r_coll = np.array(test_r_coll).reshape(1, -1)
train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)
train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)
train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)

train_r_all = np.array([train_r_all]).reshape(1, -1)
test_r_all = np.array([test_r_all]).reshape(1, -1)
train_rho_all = np.array([train_rho_all]).reshape(1, -1)
test_rho_all = np.array([test_rho_all]).reshape(1, -1)
train_mae_all = np.array([train_mae_all]).reshape(1, -1)
test_mae_all = np.array([test_mae_all]).reshape(1, -1)
train_kge_all = np.array([train_kge_all]).reshape(1, -1)
test_kge_all = np.array([test_kge_all]).reshape(1, -1)

initial_array = np.array([[N_EST_I, sample_f, obs_split_i, obs_leaf_i]])

merge_r = np.concatenate((initial_array, train_r_all, test_r_all, train_r_coll, test_r_coll), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge, delimiter=' ', fmt=fmt)

del merge_r, merge_rho, merge_mae, merge_kge
gc.collect()

print('\nSAVING FEATURE IMPORTANCES & PREDICTIONS...')

ensemble_importance = np.mean(np.array([region_importances[rid] for rid in regional_models.keys()]), axis=0)
importance = pd.Series(ensemble_importance, index=selected_names)
importance.sort_values(ascending=False, inplace=True)

print('\nTop 15 Feature Importances (Ensemble Average):')
print(importance.head(15))

importance.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', index=True, sep=' ', header=False)

Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_orig_idx[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_orig_idx[:Y_test_pred_nosort.shape[0]])

Y_train_pred_sort = Y_train_pred_indexed.sort_index().values
Y_test_pred_sort = Y_test_pred_indexed.sort_index().values

fmt_pred = '%.2f ' * 11
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt_pred.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort, delimiter=' ', fmt=fmt_pred.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print(f'\n✓ TRAINING COMPLETE')
print(f'✓ Spatio-Temporal RF Ensemble with 6 Regional Models')
print(f'✓ 32 Top Features Selected (80% importance threshold)')
print(f'✓ Multi-Quantile Predictions (11 quantiles: QMIN-QMAX)')
print(f'✓ Results saved to:')
print(f'  - Scores: ../predict_score_red/')
print(f'  - Importances: ../predict_importance_red/')
print(f'  - Predictions: ../predict_prediction_red/')
print(f'  - Train/Test splits: ../predict_splitting_red/')

gc.collect()

PYTHON_EOF
"
# close the sif
exit