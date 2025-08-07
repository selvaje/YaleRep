#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 22  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31SnapCor_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_OOB_all_multicoreE.sh
#SBATCH --array=400,500,600
#SBATCH --mem=100G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo 'obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST'

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample "
echo 'start python modeling'

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.base import RegressorMixin
from sklearn.tree import DecisionTreeRegressor
from sklearn import metrics
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy import stats
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed
pd.set_option('display.max_columns', None)
np.set_printoptions(suppress=True, precision=6, floatmode='fixed', formatter={'float': '{:.6f}'.format})

obs_leaf_s=(os.environ['obs_leaf'])
obs_leaf_i=int(os.environ['obs_leaf'])
obs_split_s=(os.environ['obs_split'])
obs_split_i=int(os.environ['obs_split'])
sample_f=float(os.environ['sample'])
sample_s=str(int(sample_f*100))
N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])

# Define column data types based on analysis
dtypes_X = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3',
        'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3',
        'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3',
        'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
        'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack','order_horton','order_shreve','order_strahler','order_topo']},
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg','channel_dist_up_cel','channel_dist_up_seg','channel_elv_dw_cel','channel_elv_dw_seg',
        'channel_elv_up_cel','channel_elv_up_seg','channel_grad_dw_seg','channel_grad_up_cel','channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm','accumulation']}
}

dtypes_Y = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM':  'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

importance = pd.read_csv('../extract4py_sample/importance_sampleAll.txt', header=None, sep=' ', engine='c', low_memory=False)
include_variables = importance.iloc[:40, 1].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)

# Read CSV with correct data types 
Y = pd.read_csv('stationID_x_y_valueALL_predictors_Y11.txt', header=0,sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv('stationID_x_y_valueALL_predictors_X11.txt', header=0,sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

# Add description of X and Y
print('#### X Description ###################')
print(X.describe())
print('#### Y Description ###################')
print(Y.describe())

stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt', sep=' ', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

# Split unique IDr values
train_rasters, test_rasters = train_test_split(stations['IDr'], test_size=0.2, random_state=24)

# Apply to X and Y
X_train = X[X['IDr'].isin(train_rasters)]
Y_train = Y[Y['IDr'].isin(train_rasters)]
X_test = X[X['IDr'].isin(test_rasters)]
Y_test = Y[Y['IDr'].isin(test_rasters)]

# Verify split sizes
print('Train IDr count: %d, Test IDr count: %d' % (len(train_rasters), len(test_rasters)))
print('X_train: %d, Y_train: %d' % (len(X_train), len(Y_train)))
print('X_test: %d, Y_test: %d' % (len(X_test), len(Y_test)))

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

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'
X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)
np.savetxt('predict_splitting/stationID_x_y_valueALL_predictors_XTrainN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), X_train, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt('predict_splitting/stationID_x_y_valueALL_predictors_XTestN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

X_train_index = X_train.index.to_numpy()
X_train = X_train.sort_values(by='IDr').reset_index(drop=True)
Y_train_index = Y_train.index.to_numpy()
Y_train = Y_train.sort_values(by='IDr').reset_index(drop=True)
X_test_index = X_test.index.to_numpy()
X_test = X_test.sort_values(by='IDr').reset_index(drop=True)
Y_test_index = Y_test.index.to_numpy()
Y_test = Y_test.sort_values(by='IDr').reset_index(drop=True)

print('Training and Testing data after IDr sorting')
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

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names = np.array(Y.columns)     
Y_column_names_str = ' '.join(Y_column_names) 
np.savetxt('predict_splitting/stationID_x_y_valueALL_predictors_YTrainN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), Y_train,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt('predict_splitting/stationID_x_y_valueALL_predictors_YTestN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), Y_test ,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')

# Remove specified columns but keep as DataFrames, retain IDr in X for grouping
X_train_df = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM'])
Y_train_df = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr'])
X_test_df = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM'])
Y_test_df = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr'])

# Delete original DataFrames to free memory
del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print('#### Y TRAIN DF ####################')
print(Y_train_df.shape)
print(Y_train_df.head(4))
print('#### X TRAIN DF ####################')
print(X_train_df.shape)
print(X_train_df.head(4))

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def __init__(self, *args, n_estimators=100, min_samples_leaf=1, min_samples_split=2, max_samples=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.n_estimators = n_estimators
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.max_samples = max_samples
        self.training_groups = None
        self.feature_names = None

    def fit(self, X, Y):
        # Input validation
        if X.isna().any().any() or Y.isna().any().any():
            raise ValueError('Input data contains missing values')
        if len(X) != len(Y):
            raise ValueError('X and Y have different lengths: %d vs %d' % (len(X), len(Y)))
        if 'IDr' not in X.columns:
            raise ValueError('X must contain 'IDr' column for group-aware training')

        X = X.astype(np.float32)
        Y = Y.astype(np.float32)
        self.training_groups = np.unique(X['IDr'])
        self.feature_names = X.drop(columns=['IDr']).columns.tolist()

        def train_tree(boot_groups):
            try:
                train_mask = X['IDr'].isin(boot_groups)
                X_filtered = X[train_mask]
                Y_filtered = Y[train_mask]
                
                # Apply max_samples within each group
                if self.max_samples is not None:
                    sampled_indices = []
                    for group in boot_groups:
                        group_indices = X_filtered[X_filtered['IDr'] == group].index
                        n_samples = int(len(group_indices) * self.max_samples)
                        if n_samples > 0:
                            sampled_indices.extend(np.random.choice(group_indices, size=n_samples, replace=False))
                    X_filtered = X_filtered.loc[sampled_indices]
                    Y_filtered = Y_filtered.loc[sampled_indices]
                
                X_train_filtered = X_filtered.drop(columns=['IDr']).to_numpy()
                Y_train_filtered = Y_filtered.to_numpy()
                tree = DecisionTreeRegressor(
                    min_samples_leaf=self.min_samples_leaf,
                    min_samples_split=self.min_samples_split
                )
                tree.fit(X_train_filtered, Y_train_filtered)
                del X_train_filtered, Y_train_filtered, X_filtered, Y_filtered
                gc.collect()
                return tree
            except Exception as e:
                print('Error training tree: %s' % e)
                return None

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(train_tree)(
            np.random.choice(self.training_groups, size=len(self.training_groups), replace=True)
        ) for _ in range(self.n_estimators))
        
        self.estimators_ = [tree for tree in self.estimators_ if tree is not None]
        if not self.estimators_:
            raise ValueError('No trees were successfully trained')

    def predict(self, X):
        # Input validation
        if len(X) == 0:
            raise ValueError('Input X is empty')
        if 'IDr' not in X.columns:
            raise ValueError('X must contain 'IDr' column for consistency')
        if X.isna().any().any():
            raise ValueError('Input data contains missing values')
        test_features = X.drop(columns=['IDr']).columns.tolist()
        if test_features != self.feature_names:
            raise ValueError('Test features %s do not match training features %s' % (test_features, self.feature_names))
        
        # Check for overlap with training groups
        test_groups = np.unique(X['IDr'])
        overlap = np.intersect1d(self.training_groups, test_groups)
        if len(overlap) > 0:
            print('Warning: %d test IDr values overlap with training IDr values' % len(overlap))

        X_pred = X.drop(columns=['IDr']).to_numpy()
        all_preds = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(tree.predict)(X_pred) for tree in self.estimators_)
        all_preds = np.array(all_preds)
        y_pred = np.mean(all_preds, axis=0)
        return np.maximum(y_pred, 0)

RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=-1, max_samples=sample_f, oob_score=False, bootstrap=True, min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i)

print('Fit RF on the training') 
RFreg.fit(X_train
```python
print('#### X TRAIN DF ####################')
print(X_train_df.shape)
print(X_train_df.head(4))
print('#### X TEST DF ####################')
print(X_test_df.shape)
print(X_test_df.head(4))

Y_train_pred_nosort = RFreg.predict(X_train_df)
Y_test_pred_nosort = RFreg.predict(X_test_df)

print('#### Y TRAIN PRED no sort  ####################')
print(Y_train_pred_nosort.shape)       
print(Y_train_pred_nosort[:4])     
print('#### Y TEST PRED no sort  ####################')
print(Y_test_pred_nosort.shape)   
print(Y_test_pred_nosort[:4])      

def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true)
    gamma = np.std(y_pred) / np.std(y_true)
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

train_r_coll = [pearsonr(Y_train_pred_nosort[:, i], Y_train_df.iloc[:, i])[0] for i in range(Y_train_df.shape[1])]
test_r_coll = [pearsonr(Y_test_pred_nosort[:, i], Y_test_df.iloc[:, i])[0] for i in range(Y_test_df.shape[1])]
print(train_r_coll)
print(test_r_coll)

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)

train_rho_coll = [spearmanr(Y_train_pred_nosort[:, i], Y_train_df.iloc[:, i])[0] for i in range(Y_train_df.shape[1])]
test_rho_coll = [spearmanr(Y_test_pred_nosort[:, i], Y_test_df.iloc[:, i])[0] for i in range(Y_test_df.shape[1])]
train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)

train_mae_coll = [mean_absolute_error(Y_train_df.iloc[:, i], Y_train_pred_nosort[:, i]) for i in range(Y_train_df.shape[1])]
test_mae_coll = [mean_absolute_error(Y_test_df.iloc[:, i], Y_test_pred_nosort[:, i]) for i in range(Y_test_df.shape[1])]
train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)

train_kge_coll = [kge(Y_train_df.iloc[:, i].to_numpy(), Y_train_pred_nosort[:, i]) for i in range(Y_train_df.shape[1])]
test_kge_coll = [kge(Y_test_df.iloc[:, i].to_numpy(), Y_test_pred_nosort[:, i]) for i in range(Y_test_df.shape[1])]
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
np.savetxt('predict_score/stationID_x_y_valueALL_predictors_Y1scorerN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), merge_r, delimiter=' ', fmt=fmt)
np.savetxt('predict_score/stationID_x_y_valueALL_predictors_Y1scorerhoN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), merge_rho, delimiter=' ', fmt=fmt)
np.savetxt('predict_score/stationID_x_y_valueALL_predictors_Y1scoremaeN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), merge_mae, delimiter=' ', fmt=fmt)
np.savetxt('predict_score/stationID_x_y_valueALL_predictors_Y1scorekgeN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), merge_kge, delimiter=' ', fmt=fmt)

importance = pd.Series(RFreg.feature_importances_, index=RFreg.feature_names)
importance.sort_values(ascending=False, inplace=True)
print(importance)
np.savetxt('predict_importance/stationID_x_y_valueALL_predictors_XimportanceN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), importance, fmt='%.6f')

Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_index[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_index[:Y_test_pred_nosort.shape[0]])

Y_train_pred_sort = Y_train_pred_indexed.sort_index()
Y_test_pred_sort = Y_test_pred_indexed.sort_index()

Y_train_pred_sort = Y_train_pred_sort.values
Y_test_pred_sort = Y_test_pred_sort.values

del Y_train_pred_indexed, Y_test_pred_indexed
gc.collect()

fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt('predict_prediction/stationID_x_y_valueALL_predictors_YpredictTrainN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt('predict_prediction/stationID_x_y_valueALL_predictors_YpredictTestN%s_%sleaf_%ssplit_%ssample_2RF.txt' % (N_EST_S, obs_leaf_s, obs_split_s, sample_s), Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

'EOF'
" ## close the sif
exit
