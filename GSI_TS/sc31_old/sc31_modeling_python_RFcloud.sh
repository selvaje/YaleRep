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
Y = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', dtype_dict=dtypes_Y)

print('Loading X data...')
X = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', usecols=lambda col: col in include_variables, dtype_dict=dtypes_X)

print(f'X shape: {X.shape}, Y shape: {Y.shape}')

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# ============================================================================
# EFFICIENT STATION-LEVEL AGGREGATION
# ============================================================================

print('Loading station coordinates...')
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
                        sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

print('Filtering stations by observation count...')
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index.values
print(f'Filtered training to {len(valid_idr_train)} stations with >10 observations')

# ============================================================================
# SPATIAL TRAIN/TEST SPLIT WITH SINGLETON-CLUSTER HANDLING
# ============================================================================

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

# ============================================================================
# PREPARE NUMPY ARRAYS FOR MODELING (FULL TEMPORAL DATA - NO AGGREGATION!)
# ============================================================================

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


# ============================================================================
# FINAL MODEL TRAINING (ON FULL TEMPORAL DATA - IMPROVED)
# ============================================================================

new part 

# ============================================================================
# PREDICTIONS & EVALUATION
# ============================================================================

new part 

print('COMPUTING ERROR METRICS (PARALLELIZED)...')

def compute_one_quantile(i, Y_pred, Y_true):
    '''Compute metrics for one quantile.'''
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

# ============================================================================
# SAVE FEATURE IMPORTANCES & PREDICTIONS
# ============================================================================

importance = pd.Series(RFreg.feature_importances_.values if hasattr(RFreg.feature_importances_, 'values') 
                       else RFreg.feature_importances_, 
                       index=selected_names)
importance.sort_values(ascending=False, inplace=True)

print('\nTop 20 Final Feature Importances:')
print(importance.head(20))

importance.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', index=True, sep=' ', header=False)

Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_orig_idx[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_orig_idx[:Y_test_pred_nosort.shape[0]])

Y_train_pred_sort = Y_train_pred_indexed.sort_index().values
Y_test_pred_sort = Y_test_pred_indexed.sort_index().values

fmt_pred = '%.2f ' * 11
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt_pred.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort, delimiter=' ', fmt=fmt_pred.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print(f'✓ TRAINING COMPLETE')
print(f'Results saved to:')
print(f'  - Scores: ../predict_score_red/')
print(f'  - Importances: ../predict_importance_red/')
print(f'  - RFECV Ranking: ../predict_importance_red/')
print(f'  - Predictions: ../predict_prediction_red/')
print(f'  - Train/Test splits: ../predict_splitting_red/')
print(f'  - Statistical Analysis: ../predict_analysis_red/')

gc.collect()

PYTHON_EOF
"
# close the sif
exit
