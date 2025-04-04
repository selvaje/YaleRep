#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling_pythonALL_GroupAwareRandomForestRFEcollinarity_sample.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_GroupAwareRandomForestRFEcollinarity_sample.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_GroupAwareRandomForestRFEcollinarity_sample.sh
#SBATCH --array=300
#SBATCH --mem=100G

##### #SBATCH --array=200,400,500,600
#### for obs in 4 5 8 10 15; do for samp in 0  ;   do sbatch --export=obs=$obs,samp=$samp sc30_modeling_pythonALL_GroupAwareRandomForestRFEcollinarity_sample.sh ; done ; done 
#### 2 4 5 8 10 15 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample
cd $EXTRACT

module load StdEnv

export obs=$obs 
export N_EST=$SLURM_ARRAY_TASK_ID

echo   "n_estimators"  $N_EST   "obs" $obs  "samp" $samp
~/bin/echoerr   n_estimators${N_EST}obs${obs}samp${samp}

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
 --env=obs=$obs,N_EST=$N_EST,samp=$samp /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "


python3 <<'EOF'
import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.base import RegressorMixin
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from sklearn import metrics
from sklearn.base import RegressorMixin
from scipy import stats
from scipy.stats import pearsonr
from sklearn.pipeline import Pipeline
from joblib import Parallel, delayed
from sklearn.feature_selection import RFE
from sklearn.linear_model import LinearRegression
import dill
pd.set_option('display.max_columns', None)  # Show all columns
import os
import gc
from statsmodels.stats.outliers_influence import variance_inflation_factor
from sklearn.preprocessing import StandardScaler


obs_s = (os.environ['obs'])
obs_i = int(os.environ['obs'])
print(obs_s)

N_EST_I = int(os.environ['N_EST'])
N_EST_S = (os.environ['N_EST'])
print(N_EST_S)

samp_i = int(os.environ['samp'])
samp_s = (os.environ['samp'])
print(samp_s)

# Define column data types based on analysis
dtypes_X = {
    # Integer columns
    'ID': 'int32',
    'IDraster': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and spatial data)
    'lon': 'float32',
    'lat': 'float32',
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
        'GSWs', 'GSWr', 'GSWo', 'GSWe']},

    # Float - Continuous measurements, spatial metrics
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation']}
}

# Define columns to exclude from import
excluded_columns = ['ID', 'lon', 'lat', 'Xcoord', 'Ycoord', 'YYYY', 'MM']


def calculate_vif(X, vif_threshold=10):
    '''
    Calculates VIF for each feature and removes features with VIF above the threshold.

    Args:
        X (pd.DataFrame): Feature matrix.
        vif_threshold (int): VIF threshold for feature removal.

    Returns:
        pd.DataFrame: Feature matrix with multicollinear features removed.
        list: Removed columns
    '''
    X_scaled = StandardScaler().fit_transform(X)  # VIF is sensitive to scale
    vif_data = pd.DataFrame()
    vif_data['feature'] = X.columns
    vif_data['VIF'] = [variance_inflation_factor(X_scaled, i) for i in range(X_scaled.shape[1])]

    # Identify highly correlated features
    highly_correlated = vif_data[vif_data['VIF'] > vif_threshold]['feature'].to_list()

    # Remove highly correlated columns
    X_filtered = X.drop(columns=highly_correlated)
    return X_filtered, highly_correlated

# Load the sampled datasets
X_samp = pd.read_csv('stationID_x_y_valueALL_predictors_sampM0_Xs.txt', header=0, sep=' ', usecols=lambda col: col not in excluded_columns, dtype=dtypes_X, engine='c',     low_memory=False )

# Calculate and apply VIF filtering
X_samp_filtered, removed_columns = calculate_vif(X_samp)

# Update X_column_names and X_samp_np
X_column_names = np.array(X_samp_filtered.columns)
X_samp_np = X_samp_filtered.to_numpy()

print(f'Removed columns due to multicollinearity: {removed_columns}')

# Define column data types
dtypes_Y = {
    # Integer columns
    'ID': 'int32',
    'IDraster': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and flow values)
    'lon': 'float32',
    'lat': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',

    # Float - Streamflow quantiles
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

# Load only the Q50 column from Y_samp
target_column = 'Q50'  # Name of the target column
Y_samp = pd.read_csv('stationID_x_y_valueALL_predictors_sampM0_Ys.txt', header=0, sep=' ', usecols=[target_column], dtype='float32', engine='c', low_memory=False)

print(Y_samp.head(4))
print(X_samp_filtered.head(4))

# Prepare data for RFE
Y_samp_np = Y_samp.to_numpy()

del X_samp, Y_samp
gc.collect()

print('X_samp_np shape:', X_samp_np.shape)
print(X_samp_np[:3])

print('Y_samp_np shape:', Y_samp_np.shape)
print(Y_samp_np[:3])

class GroupAwareDecisionTree(DecisionTreeRegressor):
    def __init__(self, *, min_group_size=5):
        super().__init__()
        self.min_group_size = min_group_size
        self.constant_value_ = None  # Initialize constant_value_

    def fit(self, X, y, sample_weight=None, check_input=True):
        # Check if the input data is empty
        if X.size == 0 or y.size == 0:
            # If the data is empty, create a 'dummy' tree
            # that always predicts the mean value of the target
            self.tree_ = None  # Indicate an empty tree
            self.constant_value_ = np.mean(y) if len(y) > 0 else 0.0  # Store the mean value
            return self  # Exit the fit method

        # Check if the group size is sufficient
        if X.shape[0] < self.min_group_size:
            self.tree_ = None
            self.constant_value_ = np.mean(y) if len(y) > 0 else 0.0
            return self

        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

    def predict(self, X):
        # Check if the tree is empty
        if self.tree_ is None:
            # If the tree is empty, return the constant value
            return np.full(X.shape[0], self.constant_value_)
        return super().predict(X)

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def __init__(self,
                 n_estimators=100,
                 *,
                 criterion='squared_error',
                 max_depth=None,
                 min_samples_split=2,
                 min_samples_leaf=1,
                 min_weight_fraction_leaf=0.0,
                 max_features='sqrt',
                 max_leaf_nodes=None,
                 min_impurity_decrease=0.0,
                 bootstrap=True,
                 oob_score=False,
                 n_jobs=None,
                 random_state=None,
                 verbose=0,
                 warm_start=False,
                 class_weight=None,
                 ccp_alpha=0.0,
                 max_samples=None,
                 min_group_size=5):  # Added min_group_size
        super().__init__(n_estimators=n_estimators,
                         criterion=criterion,
                         max_depth=max_depth,
                         min_samples_split=min_samples_split,
                         min_samples_leaf=min_samples_leaf,
                         min_weight_fraction_leaf=min_weight_fraction_leaf,
                         max_features=max_features,
                         max_leaf_nodes=max_leaf_nodes,
                         min_impurity_decrease=min_impurity_decrease,
                         bootstrap=bootstrap,
                         oob_score=oob_score,
                         n_jobs=n_jobs,
                         random_state=random_state,
                         verbose=verbose,
                         warm_start=warm_start,
                         ccp_alpha=ccp_alpha,
                         max_samples=max_samples)
        self.min_group_size = min_group_size
        self._feature_importances_ = None  # Initialize with None

    def fit(self, X, Y):
        # Ensure IDraster is the first column
        if X.shape[1] < X_samp_np.shape[1]:  # RFE has sliced the X
            X = np.concatenate((X_samp_np[:, 0].reshape(-1, 1), X), axis=1)

        unique_groups = np.unique(X[:, 0])

        # Filter out small groups
        valid_groups = []
        for group in unique_groups:
            group_mask = X[:, 0] == group
            if np.sum(group_mask) >= self.min_group_size:
                valid_groups.append(group)

        def train_tree(boot_groups):
            train_mask = np.isin(X[:, 0], boot_groups)

            # Check if train_mask results in empty data
            if not np.any(train_mask):
                # this should not happen since we are filtering the groups
                tree = GroupAwareDecisionTree(min_group_size=self.min_group_size)
                tree.tree_ = None  # Mark as a dummy tree
                tree.feature_importances_ = np.zeros(X.shape[1] - 1)  # set feature_importances_ to 0
                return tree

            X_train_filtered = X[train_mask, 1:]
            Y_train_filtered = Y[train_mask, 1:]

            tree = GroupAwareDecisionTree(min_group_size=self.min_group_size)
            tree.fit(X_train_filtered, Y_train_filtered, check_input=False)
            return tree

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(train_tree)(
            np.random.choice(valid_groups, size=len(valid_groups), replace=True)
        ) for _ in range(self.n_estimators))

        # Calculate feature importances (mean decrease in impurity)
        self._feature_importances_ = np.zeros(X.shape[1] - 1)  # Initialize to zeros
        num_valid_trees = 0
        for tree in self.estimators_:
            if tree.tree_ is not None:
                self._feature_importances_ += tree.feature_importances_
                num_valid_trees += 1
        if num_valid_trees > 0:
            self._feature_importances_ /= num_valid_trees
        else:
            self._feature_importances_ = np.zeros(X.shape[1] - 1)  # if no valid trees, set to 0

    @property
    def feature_importances_(self):
        return self._feature_importances_

    def predict(self, X):
        # Check if X has the IDraster column
        if X.shape[1] == X_samp_np.shape[1]:  # Assuming X_train_np is available
            X = X[:, 1:]  # Remove the first column (IDraster)

        # Use joblib to parallelize the predictions
        all_preds = Parallel(n_jobs=self.n_jobs, prefer='threads')(
            delayed(tree.predict)(X) for tree in self.estimators_
        )
        # Convert list to numpy array
        all_preds = np.array(all_preds)
        # Average the predictions
        y_pred = np.mean(all_preds, axis=0)
        return np.maximum(y_pred, 0)  # Ensure non-negative predictions


# Implement RFE with the Group-Aware Random Forest
# 1. Use GroupAwareRandomForestRFE as the base estimator
RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=-1, oob_score=False,
                                       max_samples=0.8, min_samples_leaf=obs_i, min_samples_split=obs_i,
                                       min_group_size=5)

# 2. Select the top 20 features
num_features_to_select = 20
rfe = RFE(RFreg, n_features_to_select=num_features_to_select, importance_getter='feature_importances_')  # explicitly set importance_getter

# Before fitting, combine IDraster with other features in X_subset
rfe.fit(X_samp_np, Y_samp_np.reshape(-1, 1))

# 3. Identify Selected Features
selected_feature_indices = rfe.get_support(indices=True)
selected_feature_names = X_column_names[selected_feature_indices]  # Get feature names

# Create a Pandas DataFrame
df = pd.DataFrame({
    'selected_feature_indices': selected_feature_indices,
    'selected_feature_names': selected_feature_names
})

# Save the DataFrame to a text file
df.to_csv('selected_feature_indices_names.txt', sep=' ', index=False, header=True)
EOF

" # closing the sif 

