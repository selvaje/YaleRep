#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500
#SBATCH --mem=400G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G
#### for obs_leaf in 100   ; do for obs_split in 100  ; do for sample in 0.9 ; do for samp in 0 1 2 3 4  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,samp=$samp /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc30_modeling_pythonALL_RFunID_flowred_GaRFG_5bos_chatPar3_imp_oob_batch.sh   ; done; done ; done ; done 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample_red
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export N_EST=$SLURM_ARRAY_TASK_ID ;  export samp=$samp
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST samp $samp "

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample  samp $samp  "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST,samp=$samp /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.base import RegressorMixin, BaseEstimator, clone
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

sample_f=float(os.environ['sample'])
sample_s=str(int(sample_f*100))

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])

samp_i=int(os.environ['samp'])
samp_s=(os.environ['samp'])

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


# Read CSV with correct data types 
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_sampM{samp_s}_Ys.txt', header=0,sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_sampM{samp_s}_Xs.txt', header=0,sep='\s+', dtype=dtypes_X, engine='c', low_memory=False )
X_column_names = np.array(X.columns)
### contain only IDr + variables and _np are not sorted
X_train_np = X.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()        ### only this with IDr
Y_train_np = Y.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()

del X, Y,
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])

class GroupAwareDecisionTreeRegressor(BaseEstimator, RegressorMixin):
    def __init__(self,
                 max_features='sqrt',
                 min_samples_leaf=1,
                 min_samples_split=2,
                 random_state=None,
                 **tree_kwargs):
        self.max_features = max_features
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.random_state = random_state
        self.tree_kwargs = tree_kwargs

    def fit(self, X, y, groups=None):
        if groups is None:
            raise ValueError('GroupAwareDecisionTreeRegressor requires groups')

        rng = check_random_state(self.random_state)
        unique_groups = np.unique(groups)
        sampled_groups = rng.choice(unique_groups,
                                    size=len(unique_groups),
                                    replace=True)
        mask = np.isin(groups, sampled_groups)

        X_sub = X[mask]
        y_sub = y[mask]

        self.tree_ = DecisionTreeRegressor(
            max_features=self.max_features,
            min_samples_leaf=self.min_samples_leaf,
            min_samples_split=self.min_samples_split,
            random_state=rng.randint(0, int(1e9)),
            **self.tree_kwargs
        )
        self.tree_.fit(X_sub, y_sub)
        self.train_idx_ = np.where(mask)[0]

        del rng, unique_groups, sampled_groups, mask, X_sub, y_sub
        gc.collect()
        return self

    def predict(self, X):
        return self.tree_.predict(X)

    @property
    def feature_importances_(self):
        return self.tree_.feature_importances_

class GroupedRandomForestRegressor(BaseEstimator, RegressorMixin):
    def __init__(self,
                 n_estimators=100,
                 max_features='sqrt',
                 min_samples_leaf=1,
                 min_samples_split=2,
                 random_state=None,
                 n_jobs=-1,
                 subsample=1.0,
                 oob_metric='r2',
                 **rf_kwargs):
        self.n_estimators = n_estimators
        self.max_features = max_features
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.random_state = random_state
        self.n_jobs = n_jobs
        self.subsample = subsample
        self.oob_metric = oob_metric
        self.rf_kwargs = rf_kwargs

    def _fit_single_tree(self, X, y, groups, rng_seed):
        rng = check_random_state(rng_seed)
        unique_groups = np.unique(groups)

        sampled_groups = rng.choice(unique_groups, size=len(unique_groups), replace=True)
        mask = np.isin(groups, sampled_groups)

        if self.subsample < 1.0:
            idx = np.where(mask)[0]
            n_sub = int(len(idx) * self.subsample)
            idx_sub = rng.choice(idx, size=n_sub, replace=False)
            mask_sub = np.zeros_like(mask, dtype=bool)
            mask_sub[idx_sub] = True
            mask = mask_sub
            del idx, n_sub, idx_sub, mask_sub

        est = GroupAwareDecisionTreeRegressor(
            max_features=self.max_features,
            min_samples_leaf=self.min_samples_leaf,
            min_samples_split=self.min_samples_split,
            random_state=rng.randint(0, int(1e9)),
            **self.rf_kwargs
        )
        est.fit(X[mask], y[mask], groups=groups[mask])
        train_idx = np.where(mask)[0]

        del rng, unique_groups, sampled_groups, mask
        gc.collect()
        return est, train_idx

    def fit(self, X, y, chunk_size=None):
        rng = check_random_state(self.random_state)
        self.groups_ = X[:, 0].astype(int)
        X_noID = X[:, 1:]
        seeds = rng.randint(0, int(1e9), size=self.n_estimators)

        self.estimators_ = []
        self.train_indices_list = []

        if chunk_size is None:
            chunk_size = max(1, self.n_estimators // 10)

        with parallel_backend('threading', n_jobs=self.n_jobs):
            for i in range(0, self.n_estimators, chunk_size):
                batch_seeds = seeds[i:i+chunk_size]
                batch_results = Parallel(n_jobs=self.n_jobs)(
                    delayed(self._fit_single_tree)(X_noID, y, self.groups_, s)
                    for s in batch_seeds
                )
                ests, idxs = zip(*batch_results)
                self.estimators_.extend(ests)
                self.train_indices_list.extend(idxs)
                del batch_results, batch_seeds, ests, idxs
                gc.collect()

        self._compute_oob_scores(X_noID, y)
        del rng, seeds, X_noID
        gc.collect()
        return self

    def _predict_single_tree(self, est, X):
        preds = est.predict(X)
        res = preds.copy()
        del preds
        gc.collect()
        return res

    def predict(self, X):
        if X.shape[1] == self.estimators_[0].tree_.n_features_in_ + 1:
            X = X[:, 1:]

        with parallel_backend('threading', n_jobs=self.n_jobs):
            preds = Parallel(n_jobs=self.n_jobs)(
                delayed(self._predict_single_tree)(est, X)
                for est in self.estimators_
            )

        preds_stack = np.stack(preds, axis=0)
        del preds
        gc.collect()
        return np.maximum(np.mean(preds_stack, axis=0), 0)

    def _compute_oob_scores(self, X, y):
        n_samples, n_targets = y.shape[0], y.shape[1]
        all_preds = np.full((self.n_estimators, n_samples, n_targets), np.nan)

        for i, (est, train_idx) in enumerate(zip(self.estimators_, self.train_indices_list)):
            test_idx = np.setdiff1d(np.arange(n_samples), train_idx)
            if test_idx.size > 0:
                all_preds[i, test_idx, :] = est.predict(X[test_idx])[:, None] if n_targets == 1 else est.predict(X[test_idx])
            del test_idx
            gc.collect()

        preds = np.nanmean(all_preds, axis=0)
        self.oob_scores_ = []

        valid = ~np.isnan(preds).any(axis=1)
        if np.any(valid):
            if self.oob_metric == 'mse':
                score = np.mean((y[valid] - preds[valid])**2)
            elif self.oob_metric == 'rmse':
                score = np.sqrt(np.mean((y[valid] - preds[valid])**2))
            elif self.oob_metric == 'r2':
                ss_res = np.sum((y[valid] - preds[valid])**2)
                ss_tot = np.sum((y[valid] - np.mean(y[valid], axis=0))**2)
                score = 1 - ss_res / ss_tot if np.any(ss_tot > 0) else np.nan
            else:
                raise ValueError(f'Unsupported oob_metric {self.oob_metric}')
        else:
            score = np.nan
        self.oob_scores_.append(score)

        for j in range(n_targets):
            valid = ~np.isnan(preds[:, j])
            if np.any(valid):
                if self.oob_metric == 'mse':
                    s = np.mean((y[valid, j] - preds[valid, j])**2)
                elif self.oob_metric == 'rmse':
                    s = np.sqrt(np.mean((y[valid, j] - preds[valid, j])**2))
                elif self.oob_metric == 'r2':
                    ss_res = np.sum((y[valid, j] - preds[valid, j])**2)
                    ss_tot = np.sum((y[valid, j] - np.mean(y[valid, j]))**2)
                    s = 1 - ss_res / ss_tot if ss_tot > 0 else np.nan
                else:
                    raise ValueError(f'Unsupported oob_metric {self.oob_metric}')
            else:
                s = np.nan
            self.oob_scores_.append(s)

        self.oob_scores_ = np.array(self.oob_scores_)
        del all_preds, preds, valid
        gc.collect()

    @property
    def feature_importances_(self):
        if not hasattr(self, 'estimators_'):
            raise ValueError('The model is not fitted yet.')
        importances = np.array([est.feature_importances_ for est in self.estimators_])
        res = np.mean(importances, axis=0)
        del importances
        gc.collect()
        return res

# --------------------------
# Example usage:
# --------------------------

RFreg = GroupedRandomForestRegressor(
    n_estimators=N_EST_I,
    max_features='sqrt',
    min_samples_leaf=obs_leaf_i,
    min_samples_split=obs_split_i,
    subsample=1,
    random_state=42,
    n_jobs=-1,
    oob_metric='r2'
)

print('Fit RF on the training') 
RFreg.fit(X_train_np, Y_train_np , chunk_size=32 )

print('General OOB r2:',   RFreg.oob_scores_[0] )
print('OOB per quantile:', RFreg.oob_scores_[1:])  # [QMIN, Q10, ..., QMAX]

# Make predictions on the training data

## Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_column_names[8:])
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_{samp_s}GaRFG.txt', index=True, sep=' ', header=False)

EOF
" ## close the sif
exit



