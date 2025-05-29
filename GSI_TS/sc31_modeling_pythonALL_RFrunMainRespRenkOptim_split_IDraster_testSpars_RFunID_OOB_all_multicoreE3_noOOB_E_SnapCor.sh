#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 22  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31SnapCor_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_OOB_all_multicoreE.sh
#SBATCH --array=400,500,600
#SBATCH --mem=400G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G
################ sample is not need with oob_score=False
#### for obs_leaf in 10 15 20 25 30  ; do for obs_split in 10 15 20 25 30  ; do for sample in 0.9  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_OOB_all_multicoreE3_noOOB_E_SnapCor.sh ; done; done ; done 

#### for obs_leaf in 2 4 5 8 10 12   ; do for obs_split in 2 4 5 8 10 12 ; do for sample in  0.3 0.4 0.5 0.6 0.7 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc30_modeling_pythonALL_RFrunMainRespRenk.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }' ) /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars_RFunID_OOB_all_multicoreE.sh  ; done  ; done ; done 
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
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
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn import metrics
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy import stats
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed
import dill 
pd.set_option('display.max_columns', None)  # Show all columns

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

# Define columns to exclude from import
excluded_columns = [
    'GSWe', 'dy', 'AWCtS', 'GSWr', 'dyy', 'tpi',
    'GSWo', 'slope_curv_max_dw_cel', 'GRWLl', 'GSWs', 'WWP', 'vrm',
    'swe2', 'pcurv', 'stream_diff_up_near', 'slope_grad_dw_cel',
    'outlet_diff_dw_scatch', 'swe0', 'swe1', 'GRWLc', 'GRWLd',
    'slope_elv_dw_cel', 'stream_diff_dw_near', 'stream_dist_dw_near',
    'stream_dist_proximity', 'SLTPPT', 'rough-scale', 'tmin3', 'tmax3',
    'elev-stdev', 'SNDPPT', 'eastness', 'dx', 'swe3', 'sti'
]

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


importance = pd.read_csv('./stationID_x_y_valueALL_predictors_XimportanceN400_25obs_snapCor1RF.txt', header=None, sep=' ', engine='c',low_memory=False, usecols=[0])
# Extract the second column (index 1) for the first 30 rows

include_variables = importance.iloc[:40, 0].tolist()
# Additional columns to add
additional_columns = ['ID', 'IDraster', 'YYYY', 'MM', 'lon', 'lat', 'Xcoord', 'Ycoord']

# Combine the lists
include_variables.extend(additional_columns)

# Read CSV with correct data types 
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_YsnapCor.txt', header=0, sep=' ', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_XsnapCor.txt', header=0, sep=' ', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False )

stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt', sep=' ', usecols=['IDraster', 'Xcoord', 'Ycoord']).drop_duplicates()

# Perform clustering on the unique station locations
num_clusters = 50  # Adjust as needed
kmeans = KMeans(n_clusters=num_clusters, random_state=42, n_init='auto')
stations['cluster'] = kmeans.fit_predict(stations[['Xcoord', 'Ycoord']])

# Ensure unique IDraster values are split while maintaining spatial separation
train_rasters, test_rasters = train_test_split(stations[['IDraster', 'cluster']], test_size=0.2, random_state=24, stratify=stations['cluster'])

# Apply clustering and IDraster separation to X and Y
X_train = X[X['IDraster'].isin(train_rasters['IDraster'])]
Y_train = Y[Y['IDraster'].isin(train_rasters['IDraster'])]
X_test = X[X['IDraster'].isin(test_rasters['IDraster'])]
Y_test = Y[Y['IDraster'].isin(test_rasters['IDraster'])]

print('Training and Testing data')
print('################################')
print(X_train.head(4))
print('################################')
print(Y_train.head(4))
print('################################')
print(X_train.shape)
print(Y_train.shape)
print(X_test.shape)
print(Y_test.shape)

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'      
X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)
# np.savetxt(rf'./stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', X_train, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
# np.savetxt(rf'./stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFEsnapCor.txt' , X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

#### the X_train and so on are sorted as the input
X_train_index = X_train.index.to_numpy()
X_train = X_train.sort_values(by='IDraster').reset_index(drop=True)

Y_train_index = Y_train.index.to_numpy()
Y_train = Y_train.sort_values(by='IDraster').reset_index(drop=True)

X_test_index = X_test.index.to_numpy()
X_test = X_test.sort_values(by='IDraster').reset_index(drop=True)

Y_test_index = Y_test.index.to_numpy()
Y_test = Y_test.sort_values(by='IDraster').reset_index(drop=True)

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', Y_train,  delimiter=' ', fmt=fmt, header='ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt' , Y_test ,  delimiter=' ', fmt=fmt, header='ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

### contain only IDraster + variables and _np are not sorted 
X_train_np = X_train.drop(columns=['ID', 'lon', 'lat', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()  
Y_train_np = Y_train.drop(columns=['ID', 'lon', 'lat', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()

X_test_np = X_test.drop(columns=['ID', 'lon', 'lat', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDraster']).to_numpy()
Y_test_np = Y_test.drop(columns=['ID', 'lon', 'lat', 'Xcoord', 'Ycoord', 'YYYY', 'MM']).to_numpy()

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])

class GroupAwareDecisionTree(DecisionTreeRegressor):
    def __init__(self, *, min_samples_leaf=1, min_samples_split=2):
        super().__init__(min_samples_leaf=min_samples_leaf, min_samples_split=min_samples_split)

    def fit(self, X, y, sample_weight=None, check_input=True):
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def __init__(self, *args, n_estimators=100, min_samples_leaf=1, min_samples_split=2, max_samples=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.n_estimators = n_estimators
        self.min_samples_leaf = min_samples_leaf
        self.min_samples_split = min_samples_split
        self.max_samples = max_samples

    def fit(self, X, Y):
        X = X.astype(np.float32)  # Reduce precision
        Y = Y.astype(np.float32)  # Reduce precision
        unique_groups = np.unique(X[:, 0])

        def train_tree(boot_groups):
            train_mask = np.isin(X[:, 0], boot_groups)
            tree = GroupAwareDecisionTree(min_samples_leaf=self.min_samples_leaf, min_samples_split=self.min_samples_split)
            X_train_filtered = X[train_mask, 1:]
            Y_train_filtered = Y[train_mask, 1:]
            tree.fit(X_train_filtered, Y_train_filtered)
            del X_train_filtered, Y_train_filtered  # Explicitly delete
            gc.collect()  # Run garbage collection
            return tree

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(train_tree)(
            np.random.choice(unique_groups, size=len(unique_groups), replace=True)
        ) for _ in range(self.n_estimators))

    def predict(self, X):
        # Check if X has the IDraster column
        if X.shape[1] == X_train_np.shape[1]:  # Assuming X_train_np is available
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

RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=-1, max_samples=sample_f, oob_score=False, bootstrap=False, min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i)

print('Fit RF on the training') 
RFreg.fit(X_train_np, Y_train_np)


# Make predictions on the training data
Y_train_pred_nosort = RFreg.predict(X_train_np)
Y_test_pred_nosort = RFreg.predict(X_test_np)

### save Y testing and training 



#  Calculate error matrix 

# Compute Kling-Gupta Efficiency (KGE).
def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]     # Correlation coefficient
    beta = np.mean(y_pred) / np.mean(y_true)  # Bias ratio
    gamma = np.std(y_pred) / np.std(y_true)   # Variability ratio
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

# Calculate Pearson correlation coefficients
train_r_coll = [pearsonr(Y_train_pred_nosort[:, i], Y_train_np[:, i + 1])[0] for i in range(0, 11)]
test_r_coll = [pearsonr(Y_test_pred_nosort[:, i], Y_test_np[:, i + 1])[0] for i in range(0, 11)]

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)

# Calculate Spearman correlation coefficients
train_rho_coll = [spearmanr(Y_train_pred_nosort[:, i], Y_train_np[:, i + 1])[0] for i in range(0, 11)]
test_rho_coll = [spearmanr(Y_test_pred_nosort[:, i], Y_test_np[:, i + 1])[0] for i in range(0, 11)]

train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)

# Calculate Mean Absolute Error (MAE)
train_mae_coll = [mean_absolute_error(Y_train_np[:, i + 1], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_mae_coll = [mean_absolute_error(Y_test_np[:, i + 1], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)

# Calculate Kling-Gupta Efficiency (KGE)
train_kge_coll = [kge(Y_train_np[:, i + 1], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_kge_coll = [kge(Y_test_np[:, i + 1], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_kge_all = np.mean(train_kge_coll)
test_kge_all = np.mean(test_kge_coll)

# Convert lists to numpy arrays
train_r_coll = np.array(train_r_coll).reshape(1, -1)
test_r_coll = np.array(test_r_coll).reshape(1, -1)

train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)

train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)

train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)

# Reshape the r_all, rho_all, mae_all, and kge_all arrays
train_r_all = np.array(train_r_all).reshape(1, -1)
test_r_all = np.array(test_r_all).reshape(1, -1)

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
merge_r   = np.concatenate((initial_array, train_r_all  , test_r_all  , train_r_coll  , test_r_coll  ), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

# Define the format strings
fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

# Save the results to separate files
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', merge_kge, delimiter=' ', fmt=fmt)

## Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_column_names[8:])
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', index=True, sep=' ', header=False)

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
fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RFsnapCor.txt', Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

EOF
" ## close the sif
exit



############################################################
rho and kge comparison 
https://github.com/copilot/share/804c43a4-4340-8002-b902-8e006450415c

