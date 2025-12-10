#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=400
#SBATCH --mem=800G

##### #SBATCH --array=300,400,500,600  200,400 250G  500,600 380G
#### for obs_leaf in 25 50 75 100  ; do for obs_split in 25 50 75 10 ; do for depth in 20 25 30  ;  do for sample in 0.9  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,depth=$depth   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFunID_flowred_GaRFG2oob4Imp_5bos_chatPar3_imp_oob_batch_15.sh    ; done; done ; done ; done 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export depth=$depth ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf $obs_leaf obs_split $obs_split depth $depth sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,depth=$depth,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "


python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor, BaseEnsemble
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.preprocessing import QuantileTransformer
from sklearn.model_selection import GroupKFold
from sklearn.tree import DecisionTreeRegressor
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn import metrics
from sklearn.utils import check_random_state
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy import stats
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed, parallel_backend, dump, load

pd.set_option('display.max_columns', None)  # Show all columns

obs_leaf_s=(os.environ['obs_leaf'])
obs_leaf_i=int(os.environ['obs_leaf'])

obs_split_s=(os.environ['obs_split'])
obs_split_i=int(os.environ['obs_split'])

depth_s=(os.environ['depth'])
depth_i=int(os.environ['depth'])

sample_f=float(os.environ['sample'])
sample_s=str(int(sample_f*100))

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])

# Define column data types based on analysis
dtypes_X = {
    # Integer columns
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and spatial data)
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',

    # Integer - Precipitation, temperature, soil, and categorical values
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

    # Float - Continuous measurements, spatial metrics
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

# Define column data types
dtypes_Y = {
    # Integer columns
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and flow values)
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',

    # Float - Streamflow quantiles
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

importance = pd.read_csv('../extract4py_sample_red/predict_importance_red/importance_sampleAll.txt', header=None, sep='\s+', engine='c', low_memory=False)
# Extract the second column (index 1) for the first 30 rows

include_variables = importance.iloc[:86, 1].tolist()
# Additional columns to add
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']

# Combine the lists
include_variables.extend(additional_columns)

# Read CSV with correct data types 
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_Y.txt', header=0,sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_X.txt', header=0,sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

# Ensure X and Y have the same index
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
target_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
id_cols = ['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']
# qt = QuantileTransformer(n_quantiles=500, output_distribution='normal', random_state=0)
# # Select only target columns and add 1 to avoid zeros
Y_targets = Y[target_cols] + 1
Y_ids = Y[id_cols].reset_index(drop=True)
Y = pd.concat([Y_ids, Y_targets], axis=1)

# # Fit and transform the target columns
# Y_targets_transformed = qt.fit_transform(Y_targets)
# # Convert back to DataFrame with original column names
# Y_targets_transformed_df = pd.DataFrame(Y_targets_transformed, columns=target_cols)
# # Optional: keep identifier columns unchanged
# Y_ids = Y[id_cols].reset_index(drop=True)
# # Combine identifiers and transformed targets into one DataFrame
# Y = pd.concat([Y_ids, Y_targets_transformed_df], axis=1)
# del Y_ids, Y_targets_transformed_df, Y_targets_transformed, Y_targets 

print('#### Y ###################')
print(Y.head(4))

gc.collect()

stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt', sep='\s+' , usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

# Filter IDr with >5 observations for training
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10 ].index
print(f'Filtered training to {len(valid_idr_train)} stations with >5 observations')

# Ensure unique IDraster values are split while maintaining spatial separation
unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=24).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_
# Filter stations for training, keep all for testing
train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
test_stations = unique_stations[['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=24,
    stratify=train_stations['cluster']
)

X_train = X[X['IDr'].isin(train_rasters['IDr'])]
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])]
X_test = X[X['IDr'].isin(test_rasters['IDr'])]
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'])]

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

fmt = ' '.join(['%f'] * (len(include_variables)))
X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', X_train , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='') 
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

#### the X_train and so on are sorted as the input

X_test = X_test.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_test_index = X_test.index.to_numpy()

Y_test = Y_test.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_test_index = Y_test.index.to_numpy()

X_train = X_train.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_train_index = X_train.index.to_numpy()

Y_train = Y_train.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_train_index = Y_train.index.to_numpy()

print(Y_train.describe())
print(X_train.describe())

print(Y_test.describe())
print(X_test.describe())

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names = np.array(Y.columns)     
Y_column_names_str = ' '.join(Y_column_names) 
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')

### contain only IDr + variables and _np are not sorted
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()        ### only this with IDr
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
groups_train = X_train['IDr'].to_numpy()  # only for grouping
X_train_column_names = np.array(X_train.drop(columns=['YYYY', 'MM', 'IDr', 'IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']).columns)

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])

class GroupBootstrapExtraTreesForest:
    def __init__(
        self,
        corr_thresh=0.5,
        n_estimators=100,
        max_features=0.2,
        max_depth=None,
        min_samples_leaf=1,
        min_samples_split=2,
        random_state=24,
        n_jobs=1,
        oob_metric='r2'
    ):
        self.corr_thresh = corr_thresh
        self.n_estimators = n_estimators
        self.max_features = max_features
        self.max_depth = max_depth
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.random_state = random_state
        self.n_jobs = n_jobs
        self.oob_metric = oob_metric
        self.trees_ = []
        self.feature_sets_ = []
        self.feature_importances_ = None
        self.kept_cols_ = None
        
    def _decorrelate(self, X):
        df = pd.DataFrame(X)
        corr_mat = df.corr(method='spearman').abs()
        upper = np.triu(np.ones(corr_mat.shape), k=1).astype(bool)
        upper_rho = pd.DataFrame(upper, columns=corr_mat.columns, index=corr_mat.index)
        drop_cols = [
            col for col in corr_mat.columns
            if any(corr_mat.loc[upper_rho.index, col][upper_rho[col]] > self.corr_thresh)
        ]
        kept = [c for c in df.columns if c not in drop_cols]
        return df[kept].to_numpy(), kept

    def _fit_tree(self, X, y, groups, rng):
        unique_groups = np.unique(groups)
        boot_groups = rng.choice(unique_groups, size=len(unique_groups), replace=True)
        boot_indices = np.hstack([np.where(groups == g)[0] for g in boot_groups])
        X_boot, features_kept = self._decorrelate(X[boot_indices])
        if self.kept_cols_ is None:
            self.kept_cols_ = features_kept  # set once for entire forest
        # Limit features if specified
        if self.max_features is not None:
            n_feats = int(np.ceil(self.max_features * X_boot.shape[1])) if self.max_features <= 1 else int(self.max_features)
            feats_idx = rng.choice(range(X_boot.shape[1]), n_feats, replace=False)
            X_boot = X_boot[:, feats_idx]
            features_kept = [features_kept[j] for j in feats_idx]
        tree = ExtraTreesRegressor(
            n_estimators=1,
            max_depth=self.max_depth,
            min_samples_leaf=self.min_samples_leaf,
            min_samples_split=self.min_samples_split,
            max_features=None,  # Already subset manually
            random_state=rng.randint(0, 1000000),
            n_jobs=1
        )
        tree.fit(X_boot, y[boot_indices])
        gc.collect()
        return tree, features_kept, boot_groups

    def fit(self, X, y, groups):
        rng = np.random.RandomState(self.random_state)
        results = Parallel(n_jobs=self.n_jobs)(
            delayed(self._fit_tree)(X, y, groups, rng)
            for _ in range(self.n_estimators)
        )
        self.trees_ = [(tree, features) for tree, features, boot_groups in results]
        self.feature_sets_ = [boot_groups for tree, features, boot_groups in results]
        gc.collect()
        return self

    def predict(self, X):
        all_preds = Parallel(n_jobs=self.n_jobs)(
            delayed(self._tree_predict)(tree, X, features)
            for tree, features in self.trees_
        )
        gc.collect()
        return np.mean(all_preds, axis=0)

    def _tree_predict(self, tree, X, features):
        df = pd.DataFrame(X)
        return tree.predict(df[features].to_numpy())

    def oob_score(self, X, y, groups):
        n_targets = y.shape[1] if y.ndim > 1 else 1
        per_target_scores = Parallel(n_jobs=self.n_jobs)(
            delayed(self._single_target_group_oob)(X, y, groups, i)
            for i in range(n_targets)
        )
        general_oob = np.nanmean(per_target_scores)
        gc.collect()
        return general_oob, np.array(per_target_scores)

    def _single_target_group_oob(self, X, y, groups, target_idx):
        group_scores = []
        unique_groups = np.unique(groups)
        for g in unique_groups:
            idx = np.where(groups == g)[0]
            preds = []
            for j, (tree, feats) in enumerate(self.trees_):
                if g not in self.feature_sets_[j]:
                    pred = tree.predict(pd.DataFrame(X[idx])[feats].to_numpy())
                    pred_i = pred[:, target_idx] if y.ndim > 1 else pred
                    preds.append(pred_i)
            if preds:
                y_pred = np.mean(preds, axis=0)
                y_true = y[idx, target_idx] if y.ndim > 1 else y[idx]
                score = (
                    r2_score(y_true, y_pred)
                    if self.oob_metric == 'r2'
                    else mean_squared_error(y_true, y_pred)
                )
                group_scores.append(score)
        gc.collect()
        return np.mean(group_scores) if group_scores else np.nan

    def compute_feature_importances(self, original_feature_names):
        
        # Aggregate feature importances from all trees, aligned to original features.
        # Returns a numpy array of importances aligned to original_feature_names,
        # also populates self.feature_importances_ and self.kept_cols_.
        
        importances_sum = np.zeros(len(original_feature_names))
        n_trees = len(self.trees_)

        feature_name_to_index = {name: i for i, name in enumerate(original_feature_names)}

        for tree, feats in self.trees_:
            tree_imps = tree.feature_importances_

            # Importance vector aligned with original features
            tree_importances_full = np.zeros(len(original_feature_names))

            for imp, feat in zip(tree_imps, feats):
                idx = feature_name_to_index.get(feat)
                if idx is not None:
                    tree_importances_full[idx] = imp

            importances_sum += tree_importances_full

        self.feature_importances_ = importances_sum / n_trees
        return self.feature_importances_

RFreg = GroupBootstrapExtraTreesForest(
    corr_thresh=0.50,
    n_estimators=N_EST_I,
    max_features=0.2,
    max_depth=depth_i,
    min_samples_leaf=obs_leaf_i,
    min_samples_split=obs_split_i,
    random_state=42,
    n_jobs=-1,
    oob_metric='r2'
)
print('Fit RF on the training') 
RFreg.fit(X_train_np, Y_train_np , groups=groups_train)

# After fitting
general_oob, per_quantile_oob = RFreg.oob_score(X_train_np, Y_train_np, groups_train)
print('General OOB r2:', general_oob)
print('OOB per quantile:', per_quantile_oob)

# Make predictions on the training data
Y_train_pred_nosort = RFreg.predict(X_train_np)
Y_test_pred_nosort  = RFreg.predict(X_test_np)

def post_pred_check(Y_true_np, Y_pred_np, name='test'):
    print(f'{name} shapes: true {Y_true_np.shape}, pred {Y_pred_np.shape}')
    if Y_true_np.shape != Y_pred_np.shape:
        raise AssertionError('Shape mismatch between Y_true and Y_pred')
    for i in range(Y_true_np.shape[1]):
        tstd = np.nanstd(Y_true_np[:,i])
        pstd = np.nanstd(Y_pred_np[:,i])
        print(f'{name} col{i} std: true {tstd:.6f}, pred {pstd:.6f}, true NaNs {np.isnan(Y_true_np[:,i]).sum()}, pred NaNs {np.isnan(Y_pred_np[:,i]).sum()}')
        if tstd == 0:
            print('  -> WARNING: true column is constant; Pearson will be NaN.')
post_pred_check(Y_test_np, Y_test_pred_nosort, 'Y_test')
post_pred_check(Y_train_np, Y_train_pred_nosort, 'Y_train')

#  Calculate error matrix 

# Compute Kling-Gupta Efficiency (KGE).
def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]     # Correlation coefficient
    beta = np.mean(y_pred) / np.mean(y_true)  # Bias ratio
    gamma = np.std(y_pred) / np.std(y_true)   # Variability ratio
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

# Calculate Pearson correlation coefficients

train_r2_coll = [r2_score(Y_train_np[:, i], Y_train_pred_nosort[:, i]) for i in range(11)]
test_r2_coll  = [r2_score(Y_test_np[:, i], Y_test_pred_nosort[:, i]) for i in range(11)]

print(train_r2_coll)
print(test_r2_coll)

train_r2_all = np.mean(train_r2_coll)
test_r2_all = np.mean(test_r2_coll)

# Calculate Spearman correlation coefficients
train_rho_coll = [spearmanr(Y_train_pred_nosort[:, i], Y_train_np[:, i ])[0] for i in range(0, 11)]
test_rho_coll = [spearmanr(Y_test_pred_nosort[:, i], Y_test_np[:, i ])[0] for i in range(0, 11)]

train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)

# Calculate Mean Absolute Error (MAE)
train_mae_coll = [mean_absolute_error(Y_train_np[:, i ], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_mae_coll = [mean_absolute_error(Y_test_np[:, i ], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)

# Calculate Kling-Gupta Efficiency (KGE)
train_kge_coll = [kge(Y_train_np[:, i ], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_kge_coll = [kge(Y_test_np[:, i ], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_kge_all = np.mean(train_kge_coll)
test_kge_all = np.mean(test_kge_coll)

# Convert lists to numpy arrays
train_r2_coll = np.array(train_r2_coll).reshape(1, -1)
test_r2_coll = np.array(test_r2_coll).reshape(1, -1)

train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)

train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)

train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)

# Reshape the r_all, rho_all, mae_all, and kge_all arrays
train_r2_all = np.array(train_r2_all).reshape(1, -1)
test_r2_all = np.array(test_r2_all).reshape(1, -1)

train_rho_all = np.array(train_rho_all).reshape(1, -1)
test_rho_all = np.array(test_rho_all).reshape(1, -1)

train_mae_all = np.array(train_mae_all).reshape(1, -1)
test_mae_all = np.array(test_mae_all).reshape(1, -1)

train_kge_all = np.array(train_kge_all).reshape(1, -1)
test_kge_all = np.array(test_kge_all).reshape(1, -1)

# Prepare metadata for output
obs_leaf_a = np.array(obs_leaf_i).reshape(1, -1)
obs_split_a = np.array(obs_split_i).reshape(1, -1)
sample_a = np.array(sample_f).reshape(1, -1)
N_EST_a = np.array(N_EST_I).reshape(1, -1)

# Create the initial array with metadata
initial_array = np.array([[N_EST_a[0, 0], sample_a[0, 0], obs_split_a[0, 0], obs_leaf_a[0, 0]]])

# Concatenate train and test metrics for r, rho, mae, and kge
merge_r   = np.concatenate((initial_array, train_r2_all  , test_r2_all  , train_r2_coll  , test_r2_coll  ), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

# Define the format strings
fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

# Save the results to separate files
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge, delimiter=' ', fmt=fmt)

## Get feature importances and sort them in descending order 
importances_array = RFreg.compute_feature_importances(X_train_column_names)         
# Always use original column names, not indices   
importance = pd.Series(importances_array, index=X_train_column_names)   
# Sort descending importance = importance.sort_values(ascending=False)   
importance.to_csv(rf'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', index=True, sep=' ', header=False , float_format='%.6f')

# Create Pandas DataFrames with the appropriate indices
Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_index[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_index[:Y_test_pred_nosort.shape[0]])

# Sort the DataFrames by index
Y_train_pred_sort = Y_train_pred_indexed.sort_index()
Y_test_pred_sort = Y_test_pred_indexed.sort_index()

# Extract the values as NumPy arrays
Y_train_pred_sort = Y_train_pred_sort.values
Y_test_pred_sort = Y_test_pred_sort.values

del Y_train_pred_indexed, Y_test_pred_indexed
gc.collect()

#### save prediction
print(Y_train_pred_sort.shape)            
print(Y_train_pred_sort[:4])        
print(Y_test_pred_sort.shape)  
print(Y_test_pred_sort[:4]) 

fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

EOF
" ## close the sif
exit

