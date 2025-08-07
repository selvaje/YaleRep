#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 22 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31SnapCor_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_OOB_all_multicoreE.sh
#SBATCH --array=400,500,600
#SBATCH --mem=300G

#### for obs_leaf in 30 ; do for obs_split in 30 ; do for sample in 0.9  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_SnapCorGrokImp3.sh    ; done; done ; done


EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv
export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf $obs_leaf obs_split $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif bash -c "

python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.base import RegressorMixin
from sklearn.tree import DecisionTreeRegressor
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed
pd.set_option('display.max_columns', None)

obs_leaf_s = os.environ['obs_leaf']
obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_s = os.environ['obs_split']
obs_split_i = int(os.environ['obs_split'])
sample_f = float(os.environ['sample'])
sample_s = str(int(sample_f * 100))
N_EST_I = int(os.environ['N_EST'])
N_EST_S = os.environ['N_EST']

dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo']},
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity', 'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
        'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
        'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale', 'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation']}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

importance = pd.read_csv('../extract4py_sample/importance_sampleAll.txt', header=None, sep=' ', engine='c', low_memory=False)
include_variables = importance.iloc[:40, 1].tolist()
include_variables.extend(['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'])

Y = pd.read_csv('stationID_x_y_valueALL_predictors_Y1.txt', header=0, sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv('stationID_x_y_valueALL_predictors_X1.txt', header=0, sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

expected_quantiles = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
Y_cols = Y.columns.tolist()
missing_quantiles = [col for col in expected_quantiles if col not in Y_cols]
if missing_quantiles:
    print(f'Warning: Missing quantile columns in Y: {missing_quantiles}')
n_quantiles = len([col for col in Y_cols if col in expected_quantiles])
print(f'Number of quantiles detected: {n_quantiles}')

stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt', sep=' ', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

train_rasters, test_rasters = train_test_split(stations['IDr'], test_size=0.2, random_state=24)
X_train = X[X['IDr'].isin(train_rasters)]
Y_train = Y[Y['IDr'].isin(train_rasters)]
X_test = X[X['IDr'].isin(test_rasters)]
Y_test = Y[Y['IDr'].isin(test_rasters)]

print('Training and Testing data')
print('#### X TRAIN ###################')
print(X_train.head(4))
print('#### Y TRAIN ###################')
print(Y_train.head(4))
print('#### X TEST ####################')
print(X_test.head(4))
print('#### Y TEST ####################')
print(Y_test.head(4))
print('################################')
print(X_train.shape)
print(Y_train.shape)
print(X_test.shape)
print(Y_test.shape)

fmt = '%i %f %f %i %f %f %i %i ' + ' '.join(['%f'] * (X.shape[1] - 8))
X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)
np.savetxt(f'../predict_splitting/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           X_train, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(f'../predict_splitting/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           X_test, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

X_train_index = X_train.index.to_numpy()
X_train = X_train.sort_values(by='IDr').reset_index(drop=True)
Y_train_index = Y_train.index.to_numpy()
Y_train = Y_train.sort_values(by='IDr').reset_index(drop=True)
X_test_index = X_test.index.to_numpy()
X_test = X_test.sort_values(by='IDr').reset_index(drop=True)
Y_test_index = Y_test.index.to_numpy()
Y_test = Y_test.sort_values(by='IDr').reset_index(drop=True)

fmt = '%i %f %f %i %f %f %i %i ' + ' '.join(['%f'] * n_quantiles)
Y_column_names = np.array(Y.columns)
Y_column_names_str = ' '.join(Y_column_names)
np.savetxt(f'../predict_splitting/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           Y_train, delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt(f'../predict_splitting/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           Y_test, delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')

X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()
X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])

class GroupAwareDecisionTree(DecisionTreeRegressor):
    def __init__(self, *, min_samples_leaf=1, min_samples_split=2, group_penalty=0.1):
        super().__init__(min_samples_leaf=min_samples_leaf, min_samples_split=min_samples_split)
        self.group_penalty = group_penalty

    def fit(self, X, y, sample_weight=None, check_input=True, groups=None):
        if groups is not None:
            if len(groups) != X.shape[0]:
                raise ValueError(f'Length of groups ({len(groups)}) does not match X rows ({X.shape[0]})')
            unique_groups, group_counts = np.unique(groups, return_counts=True)
            print(f'GroupAwareDecisionTree: {len(unique_groups)} groups, min size: {group_counts.min()}, max size: {group_counts.max()}')
            if sample_weight is None:
                sample_weight = np.ones(X.shape[0])
            group_weights = {g: 1.0 / count for g, count in zip(unique_groups, group_counts)}
            sample_weight = np.array([sample_weight[i] * (1.0 + self.group_penalty * group_weights[groups[i]]) 
                                    for i in range(X.shape[0])])
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)
        self.groups_ = groups

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def __init__(self, *args, n_estimators=100, min_samples_leaf=1, min_samples_split=2, max_samples=None, group_penalty=0.1, **kwargs):
        super().__init__(*args, **kwargs)
        self.n_estimators = n_estimators
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.max_samples = max_samples
        self.group_penalty = group_penalty

    def fit(self, X, Y):
        X = X.astype(np.float32)
        Y = Y.astype(np.float32)
        self.n_features_ = X.shape[1] - 1
        unique_groups = np.unique(X[:, 0])

        def train_tree(boot_groups):
            train_mask = np.isin(X[:, 0], boot_groups)
            tree = GroupAwareDecisionTree(
                min_samples_leaf=self.min_samples_leaf, 
                min_samples_split=self.min_samples_split,
                group_penalty=self.group_penalty
            )
            X_train_filtered = X[train_mask, 1:]
            Y_train_filtered = Y[train_mask]
            groups_filtered = X[train_mask, 0]
            tree.fit(X_train_filtered, Y_train_filtered, groups=groups_filtered)
            del X_train_filtered, Y_train_filtered, groups_filtered
            gc.collect()
            return tree

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(train_tree)(
            np.random.choice(unique_groups, size=len(unique_groups), replace=True)
        ) for _ in range(self.n_estimators))

    def predict(self, X):
        if X.shape[1] == self.n_features_ + 1:
            X = X[:, 1:]
        elif X.shape[1] != self.n_features_:
            raise ValueError(f'Expected {self.n_features_} or {self.n_features_ + 1} columns, got {X.shape[1]}')
        all_preds = Parallel(n_jobs=self.n_jobs, prefer='threads')(
            delayed(tree.predict)(X) for tree in self.estimators_
        )
        all_preds = np.array(all_preds)
        y_pred = np.mean(all_preds, axis=0)
        return np.maximum(y_pred, 0)

RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=-1, max_samples=sample_f, 
                                      oob_score=True, bootstrap=True, min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i,
                                      group_penalty=0.1)

print('Fit RF on the training')
RFreg.fit(X_train_np, Y_train_np)

Y_train_pred_nosort = RFreg.predict(X_train_np)
Y_test_pred_nosort = RFreg.predict(X_test_np)

print('Y_train_np shape:', Y_train_np.shape)
print('Y_test_np shape:', Y_test_np.shape)
print('Y_train_pred_nosort shape:', Y_train_pred_nosort.shape)
print('Y_test_pred_nosort shape:', Y_test_pred_nosort.shape)

n_quantiles = Y_train_np.shape[1]
if Y_train_pred_nosort.shape[1] != n_quantiles or Y_test_pred_nosort.shape[1] != n_quantiles:
    raise ValueError(f'Prediction shape does not match target shape: expected {n_quantiles} quantiles')

def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true)
    gamma = np.std(y_pred) / np.std(y_true)
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

train_r_coll = [pearsonr(Y_train_pred_nosort[:, i], Y_train_np[:, i])[0] for i in range(n_quantiles)]
test_r_coll = [pearsonr(Y_test_pred_nosort[:, i], Y_test_np[:, i])[0] for i in range(n_quantiles)]

print(train_r_coll)
print(test_r_coll)

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)

train_rho_coll = [spearmanr(Y_train_pred_nosort[:, i], Y_train_np[:, i])[0] for i in range(n_quantiles)]
test_rho_coll = [spearmanr(Y_test_pred_nosort[:, i], Y_test_np[:, i])[0] for i in range(n_quantiles)]

train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)

train_mae_coll = [mean_absolute_error(Y_train_np[:, i], Y_train_pred_nosort[:, i]) for i in range(n_quantiles)]
test_mae_coll = [mean_absolute_error(Y_test_np[:, i], Y_test_pred_nosort[:, i]) for i in range(n_quantiles)]

train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)

train_kge_coll = [kge(Y_train_np[:, i], Y_train_pred_nosort[:, i]) for i in range(n_quantiles)]
test_kge_coll = [kge(Y_test_np[:, i], Y_test_pred_nosort[:, i]) for i in range(n_quantiles)]

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

train_r_all = np.array(train_r_all).reshape(1, -1)
test_r_all = np.array(test_r_all).reshape(1, -1)
train_rho_all = np.array(train_rho_all).reshape(1, -1)
test_rho_all = np.array(test_rho_all).reshape(1, -1)
train_mae_all = np.array(train_mae_all).reshape(1, -1)
test_mae_all = np.array(test_mae_all).reshape(1, -1)
train_kge_all = np.array(train_kge_all).reshape(1, -1)
test_kge_all = np.array(test_kge_all).reshape(1, -1)

obs_leaf_a = np.array(obs_leaf_i).reshape(1, -1)
obs_split_a = np.array(obs_split_i).reshape(1, -1)
sample_a = np.array(sample_f).reshape(1, -1)
N_EST_a = np.array(N_EST_I).reshape(1, -1)

initial_array = np.array([[N_EST_a[0, 0], sample_a[0, 0], obs_split_a[0, 0], obs_leaf_a[0, 0]]])

merge_r = np.concatenate((initial_array, train_r_all, test_r_all, train_r_coll, test_r_coll), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

np.savetxt(f'../predict_score/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           merge_r, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           merge_kge, delimiter=' ', fmt=fmt)

importance = pd.Series(RFreg.feature_importances_, index=X_column_names[8:])
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(f'../predict_importance/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
                  index=True, sep=' ', header=False)

Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_index[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_index[:Y_test_pred_nosort.shape[0]])

Y_train_pred_sort = Y_train_pred_indexed.sort_index()
Y_test_pred_sort = Y_test_pred_indexed.sort_index()

Y_train_pred_sort = Y_train_pred_sort.values
Y_test_pred_sort = Y_test_pred_sort.values

del Y_train_pred_indexed, Y_test_pred_indexed
gc.collect()

quantile_names = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX'][:n_quantiles]
fmt = ' '.join(['%.2f'] * n_quantiles)
header = ' '.join(quantile_names)

print(Y_train_pred_sort.shape)
print(Y_train_pred_sort[:4])
print(Y_test_pred_sort.shape)
print(Y_test_pred_sort[:4])

np.savetxt(f'../predict_prediction/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           Y_train_pred_sort, delimiter=' ', fmt=fmt, header=header, comments='')
np.savetxt(f'../predict_prediction/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', 
           Y_test_pred_sort, delimiter=' ', fmt=fmt, header=header, comments='')

EOF
"
exit
