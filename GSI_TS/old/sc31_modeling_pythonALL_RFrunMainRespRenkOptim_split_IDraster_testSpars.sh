#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 18  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptim.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh.%A_%a.err
#SBATCH --job-name=sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh
#SBATCH --array=300,400,500
#SBATCH --mem=300G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G

#### for obs_leaf in 2 4 5 8 10 12  ; do for obs_split in 2 4 5 8 10 12  ; do for sample in  0.4 0.5 0.55 0.6 0.65 0.7 0.75 0.8 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim_split_IDraster_testSpars.sh ; done; done ; done 

#### for obs_leaf in 2 4 5 8 10 12   ; do for obs_split in 2 4 5 8 10 12 ; do for sample in  0.3 0.4 0.5 0.6 0.7 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc30_modeling_pythonALL_RFrunMainRespRenk.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }' ) /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh ; done  ; done ; done 
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
echo obs_leaf  $obs_leaf
echo obs_split  $obs_split
echo sample $sample
export N_EST=$SLURM_ARRAY_TASK_ID
# export N_EST=100
echo "n_estimators"  $N_EST
echo "start python modeling" #### see https://machinelearningmastery.com/rfe-feature-selection-in-python/


apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "




python3 <<'EOF'
import os
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from scipy import stats
from scipy.stats import pearsonr
import dill 
pd.set_option('display.max_columns', None)  # Show all columns

obs_leaf_s=(os.environ['obs_leaf'])
obs_leaf_i=int(os.environ['obs_leaf'])

obs_split_s=(os.environ['obs_split'])
obs_split_i=int(os.environ['obs_split'])

sample_f=float(os.environ['sample'])
sample_s=str(int(sample_f*100))

print(obs_leaf_s)

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])
print(N_EST_S)

X  = pd.read_csv('./stationID_x_y_valueALL_predictors_X.txt', header=0, sep=' ')   #  ID =  IDstation  37706
Y  = pd.read_csv('./stationID_x_y_valueALL_predictors_Y.txt', header=0, sep=' ')   #  ID =  IDstation  37706

#### IDstation IDraster lat long Equidistance
#### 40813     40165 
ID = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/x_y_snapFlowFinal_station_IDru_flow_all_eqdist.txt',header=0, sep=' ')

X_selected_var  = pd.read_csv('stationID_x_y_valueALL_predictors_XimportanceN300_4obs.txt', header=None , sep=' ')

#### base on score value 
X_selected_var = X_selected_var.loc[(X_selected_var[1] > 0.005)][0]
#### base on score index e.g. 50 
#### X_selected_var = X_selected_var.head(50)[0]
 
# Ensure ID, YYYY, MM, lon, lat are always retained
mandatory_columns = ['ID', 'YYYY', 'MM', 'lon', 'lat']
X_selected_var = pd.concat([pd.Series(mandatory_columns), X_selected_var], ignore_index=True)

X = X.loc[:,X_selected_var]    ### at this point the X is already reduced 

print(Y.shape)
print(X.shape)

X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)

fmt = '%i %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'
np.savetxt(rf'stationID_x_y_valueALL_predictors_XcolnamesN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt',  X_column_names , fmt='%s')
np.savetxt(rf'stationID_x_y_valueALL_predictors_Xselected_pyN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X,  delimiter=' ', header=X_column_names_str , comments='' , fmt=fmt)  

# Merge datasets on IDstation
merged = X.merge(Y, on=['ID', 'YYYY', 'MM', 'lon', 'lat']).merge(ID, left_on='ID', right_on='IDstation')

print(X.head(4))                                                                                                                         
print(Y.head(4))    

# Perform clustering to ensure test samples are well distributed across the globe
num_clusters = 50  # Set number of clusters to roughly match test size  int(len(merged) * 0.2)
kmeans = KMeans(n_clusters=num_clusters, random_state=42)
merged['cluster'] = kmeans.fit_predict(merged[['Xcoord', 'Ycoord']])

# Ensure unique IDraster values are split while maintaining spatial separation
unique_rasters = merged[['IDraster', 'cluster']].drop_duplicates()
train_rasters, test_rasters = train_test_split(unique_rasters, test_size=0.2, random_state=24, stratify=unique_rasters['cluster'])

train_data = merged[merged['IDraster'].isin(train_rasters['IDraster'])]
test_data = merged[merged['IDraster'].isin(test_rasters['IDraster'])]

# Extract X and Y for training/testing
X_train = train_data.loc[:, X_selected_var]
Y_train = train_data[Y.columns]
X_test = test_data.loc[:, X_selected_var]
Y_test = test_data[Y.columns]

print('Training set size:', X_train.shape, 'Testing set size:', X_test.shape)

fmt = '%i %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f'

np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt=fmt, header='ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt=fmt, header='ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

fmt = '%i %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'

X_column_names_str = ' '.join(X_column_names)
np.savetxt(rf'./stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X_train, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

print('Run RF on the training') 
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=18, max_samples=sample_f, oob_score=True, bootstrap=True, min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i)

# Print first 4 rows and headers before training

print(X_train.iloc[:, 5:31].head(4))
print(Y_train.iloc[:, 5:16].head(4))

RFreg.fit(X_train.iloc[:,5:31], Y_train.iloc[:,5:16])  

#### make prediction using the oob
Y_train_pred = RFreg.oob_prediction_ 
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YOOBpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train_pred, delimiter=' ', fmt='%f', header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', RFreg.predict(X_train.iloc[:, 5:31]), delimiter=' ', fmt='%f', header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print('OOB score' ,  RFreg.oob_score_)
print('Score' ,  RFreg.score)

train_r2 = RFreg.score(X_train.iloc[:,5:31], Y_train.iloc[:,5:16])
train_oob_r2 = np.array([RFreg.oob_score_])
test_r2 = RFreg.score(X_test.iloc[:,5:31], Y_test.iloc[:,5:16])

Y_test_pred = RFreg.predict(X_test.iloc[:,5:31])
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_test_pred , delimiter=' ', fmt='%f', header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
train_mse = mean_squared_error(Y_train.iloc[:,5:16], RFreg.predict(X_train.iloc[:, 5:31]))
train_oob_mse = mean_squared_error(Y_train.iloc[:,5:16], Y_train_pred)
test_mse = mean_squared_error(Y_test.iloc[:,5:16], Y_test_pred)

train_rQMIN = stats.pearsonr(Y_train_pred[:,0],Y_train.iloc[:, 5])[0]
train_rQ10  = stats.pearsonr(Y_train_pred[:,1],Y_train.iloc[:, 6])[0]
train_rQ20  = stats.pearsonr(Y_train_pred[:,2],Y_train.iloc[:, 7])[0]
train_rQ30  = stats.pearsonr(Y_train_pred[:,3],Y_train.iloc[:, 8])[0]  
train_rQ40  = stats.pearsonr(Y_train_pred[:,4],Y_train.iloc[:, 9])[0] 
train_rQ50  = stats.pearsonr(Y_train_pred[:,5],Y_train.iloc[:, 10])[0]
train_rQ60  = stats.pearsonr(Y_train_pred[:,6],Y_train.iloc[:, 11])[0]
train_rQ70  = stats.pearsonr(Y_train_pred[:,7],Y_train.iloc[:, 12])[0]
train_rQ80  = stats.pearsonr(Y_train_pred[:,8],Y_train.iloc[:, 13])[0]
train_rQ90  = stats.pearsonr(Y_train_pred[:,9],Y_train.iloc[:, 14])[0]
train_rQMAX = stats.pearsonr(Y_train_pred[:,10],Y_train.iloc[:, 15])[0]

test_rQMIN = stats.pearsonr(Y_test_pred[:,0],Y_test.iloc[:, 5])[0]                
test_rQ10  = stats.pearsonr(Y_test_pred[:,1],Y_test.iloc[:, 6])[0]    
test_rQ20  = stats.pearsonr(Y_test_pred[:,2],Y_test.iloc[:, 7])[0]    
test_rQ30  = stats.pearsonr(Y_test_pred[:,3],Y_test.iloc[:, 8])[0]        
test_rQ40  = stats.pearsonr(Y_test_pred[:,4],Y_test.iloc[:, 9])[0]
test_rQ50  = stats.pearsonr(Y_test_pred[:,5],Y_test.iloc[:, 10])[0]     
test_rQ60  = stats.pearsonr(Y_test_pred[:,6],Y_test.iloc[:, 11])[0]    
test_rQ70  = stats.pearsonr(Y_test_pred[:,7],Y_test.iloc[:, 12])[0]          
test_rQ80  = stats.pearsonr(Y_test_pred[:,8],Y_test.iloc[:, 13])[0]                  
test_rQ90  = stats.pearsonr(Y_test_pred[:,9],Y_test.iloc[:, 14])[0]                                  
test_rQMAX = stats.pearsonr(Y_test_pred[:,10],Y_test.iloc[:, 15])[0]         

n=np.array(N_EST_I)
leaf=np.array(obs_leaf_i)
split=np.array(obs_split_i)
sample=np.array(sample_f)

merge=np.c_[n,leaf,split,sample,train_r2,train_oob_r2,test_r2,train_mse,train_oob_mse,test_mse,train_rQMIN,train_rQ10,train_rQ20,train_rQ30,train_rQ40,train_rQ50,train_rQ60,train_rQ70,train_rQ80,train_rQ90,train_rQMAX,test_rQMIN,test_rQ10,test_rQ20,test_rQ30,test_rQ40,test_rQ50,test_rQ60,test_rQ70,test_rQ80,test_rQ90,test_rQMAX]

print(merge)
fmt = '%i %i %i %i %.2f %.2f %.2f %.i %.i %.i %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YscoreN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', merge, delimiter=' ',  fmt='%f')

### Function to calculate KGE
### Compute Kling-Gupta Efficiency (KGE), handling zero-flow observations gracefully while preventing extreme negative values

def calculate_kge(obs, pred, min_obs=5):

    # Ensure enough observations are available
    if len(obs) < min_obs:
        return np.nan  # Not enough data, return NaN

    # Compute Pearson correlation safely
    if np.all(obs == 0) and np.all(pred == 0):
        r = 1  # Perfect correlation if both obs and pred are all zeros
    else:
        try:
            r, _ = pearsonr(obs, pred)  # Compute normally
        except ValueError:  # Handle cases where one of them is constant
            r = 0  # Undefined correlation defaults to 0

    # Handle zero-flow observations
    mean_obs, mean_pred = np.mean(obs), np.mean(pred)
    std_obs, std_pred = np.std(obs), np.std(pred)

    # Prevent division errors in beta and gamma
    if mean_obs < 1e-6:  # If mean_obs is too small, set safe defaults
        beta, gamma = 0, 0  
    else:
        beta = mean_pred / mean_obs if mean_obs > 0 else 0  # Bias ratio
        gamma = (std_pred / mean_pred) / (std_obs / mean_obs) if std_obs > 0 and mean_obs > 0 else 0  # Variability ratio

    # Limit extreme values to prevent exploding KGE
    beta = np.clip(beta, -10, 10)
    gamma = np.clip(gamma, -10, 10)

    # Print values for debugging
    print(f'IDraster Debug -> r: {r:.4f}, beta: {beta:.4f}, gamma: {gamma:.4f}')

    # Compute final KGE
    kge = 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)
    
    return kge

# Compute KGE for each IDraster (Test Data)
kge_results_test = []
for raster in test_data['IDraster'].unique():
    raster_mask = test_data['IDraster'] == raster
    kge_values = [calculate_kge(Y_test.loc[raster_mask, col], Y_test_pred[raster_mask, i - 5]) for i, col in enumerate(Y_test.columns[5:16], start=5)]
    kge_results_test.append([raster] + kge_values)
            
# Compute KGE for each IDraster (Train Data)
kge_results_train = []
for raster in train_data['IDraster'].unique():
    raster_mask = train_data['IDraster'] == raster
    kge_values = [calculate_kge(Y_train.loc[raster_mask, col], Y_train_pred[raster_mask, i - 5]) for i, col in enumerate(Y_train.columns[5:16], start=5)]
    kge_results_train.append([raster] + kge_values)

fmt = '%i %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTrain_kgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', kge_results_train , delimiter=' ', fmt=fmt, header='IDraster KGE_QMIN KGE_Q10 KGE_Q20 KGE_Q30 KGE_Q40 KGE_Q50 KGE_Q60 KGE_Q70 KGE_Q80 KGE_Q90 KGE_QMAX', comments='')
np.savetxt(rf'./stationID_x_y_valueALL_predictors_YTest_kgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt',  kge_results_test  , delimiter=' ', fmt=fmt, header='IDraster KGE_QMIN KGE_Q10 KGE_Q20 KGE_Q30 KGE_Q40 KGE_Q50 KGE_Q60 KGE_Q70 KGE_Q80 KGE_Q90 KGE_QMAX', comments='')

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_test.columns[5:31])
importance.sort_values(ascending=False,inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , index=True , sep=' ' , header=False)

# for the intire session 
# with open(rf'./stationID_x_y_valueALL_predictors_YmodelN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.pkl' , 'w+b') as f:
#    dill.dump_session(f)

# Save the file
# dill.dump(RFreg, file = open(f'./stationID_x_y_valueALL_predictors_YmodelN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.pkl', 'wb'))

EOF
" ## close the sif
exit   

# Implementation Using a Custom Decision Tree
# Scikit-learn's DecisionTreeRegressor allows custom split constraints via the splitter argument.
# We override the splitter to ensure that IDraster is never split within a tree.
# Step 1: Implement a Custom Splitter
# Scikit-learn does not allow direct group-aware constraints, so we wrap DecisionTreeRegressor to force node purity for IDraster.


from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
import numpy as np

class GroupAwareDecisionTree(DecisionTreeRegressor):
    def fit(self, X, y, sample_weight=None, check_input=True, groups=None):
        if groups is None:
            raise ValueError("Groups (IDraster) must be provided to ensure group-aware splits.")
        
        # Create a new feature that encodes the group (IDraster) and append it to X
        X = np.column_stack((X, groups))
        
        # Fit the tree with the modified dataset
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

class GroupAwareRandomForest(RandomForestRegressor):
    def fit(self, X, y, groups):
        # Ensure that we don't use IDraster as a predictor
        X_features = X.drop(columns=['IDraster'])
        
        # Train each tree while passing `groups` to ensure group-aware splits
        self.estimators_ = [GroupAwareDecisionTree() for _ in range(self.n_estimators)]
        for tree in self.estimators_:
            tree.fit(X_features, y, groups=groups)
        
        return self

# Step 2: Use This Custom RF Model
# Replace RandomForestRegressor  with GroupAwareRandomForest:

RFreg = GroupAwareRandomForest(
    random_state=24, 
    n_estimators=N_EST, 
    n_jobs=18, 
    max_samples=sample, 
    oob_score=True, 
    bootstrap=True, 
    min_samples_leaf=obs_leaf, 
    min_samples_split=obs_split
)

# Fit the model with group-aware constraints
RFreg.fit(X_train, Y_train, groups=train_data['IDraster'])
