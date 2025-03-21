#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 30 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /home/st929/output/sc30_train_model.sh.%A_%a.out
#SBATCH -e /home/st929/output/sc30_train_model.sh.%A_%a.err
#SBATCH --job-name=sc30_train_model.sh
#SBATCH --array=400
#SBATCH --mem=50G

##### #SBATCH --array=200,400,500,600
#### for obs in 2 4 5 8 10 15 ; do sbatch --export=obs=$obs /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc30_modeling_pythonALL_RFrunMainRespRenk.sh ; done
#### 2 4 5 8 10 15 

IN=/gpfs/gibbs/pi/hydro/st929
EXTRACT=/gpfs/gibbs/pi/hydro/st929/files_for_extracting

cd $EXTRACT

module load StdEnv

export N_EST=$SLURM_ARRAY_TASK_ID
#### export N_EST=100
echo "n_estimators" $N_EST

module load miniconda

source activate my_env

echo "start python modeling"

cd $EXTRACT

python <<EOF

import os
import pandas as pd
import numpy as np
from sklearn.model_selection import GroupKFold
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.cluster import KMeans
from sklearn.feature_selection import RFECV

# Load the file into a DataFrame
file_path = "/gpfs/gibbs/pi/hydro/st929/files_for_extracting/stationID_x_y_valueALL_predictors.txt"
df = pd.read_csv(file_path, sep='\\s+')

# Add a random variable to the DataFrame
np.random.seed(42)
df['random_variable'] = np.random.rand(len(df))

# Define predictors and target
predictors = [col for col in df.columns if col not in ['ID', 'lon', 'lat', 'Alkalinity', 'Flux']]
target = 'Alkalinity'

# Generate spatial clusters/groups
n_clusters = 10
kmeans = KMeans(n_clusters=n_clusters, random_state=42)
df['spatial_group'] = kmeans.fit_predict(df[['lon', 'lat']])

# Prepare features and target
X = df[predictors]
y = df[target]

# Initialize the Random Forest Regressor
n_estimators = int(os.environ.get("N_EST", 1000))
model = RandomForestRegressor(
    random_state=24,
    n_estimators=n_estimators,
    n_jobs=30,
    oob_score=True,
    bootstrap=True
)

# Spatial cross-validation
group_kfold = GroupKFold(n_splits=5)
mse_list = []
r2_list = []
feature_importances_list = []
groups=df['spatial_group']
print(f"Size of X: {X.shape[0]}")
print(f"Size of groups: {len(groups)}")

for fold, (train_index, test_index) in enumerate(group_kfold.split(X, y, groups=groups)):
    X_train, X_test = X.iloc[train_index], X.iloc[test_index]
    y_train, y_test = y.iloc[train_index], y.iloc[test_index]
    #groups_train, groups_test = groups.iloc[train_index], groups.iloc[test_index]
    groups_train, groups_test = groups.iloc[train_index], groups.iloc[test_index]
    rfecv = RFECV(estimator=model, step=1, cv=GroupKFold(n_splits=5), scoring='neg_mean_squared_error', n_jobs=-1)
    # Fit RFECV
    rfecv.fit(X_train, y_train, groups=groups_train)

    # Fit RFECV
    # Print the number of features selected at each step
    print(f"Fold {fold + 1}: Number of features selected at each step:")
    for i, score in enumerate(rfecv.grid_scores_):
        print(f"Step {i + 1}: {score}")

    # Fit RFECV
    # Select the optimal features
    X_train_rfe = rfecv.transform(X_train)
    X_test_rfe = rfecv.transform(X_test)

    # Fit RFECV
    # Fit the model on the selected features
    model.fit(X_train_rfe, y_train)
    
    y_pred = model.predict(X_test_rfe)
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    y_pred_train = model.predict(X_train_rfe)
    r2_train = r2_score(y_train, y_pred_train)
    
    mse_list.append(mse)
    r2_list.append(r2)
    
    # Calculate feature importances
    feature_importances = pd.DataFrame(model.feature_importances_, index=X_train.columns[rfecv.support_], columns=['importance']).sort_values('importance', ascending=False)
    feature_importances['fold'] = fold
    feature_importances_list.append(feature_importances)

# Combine feature importances from all folds
if feature_importances_list:
    all_feature_importances = pd.concat(feature_importances_list)

    # Print the R^2 and MSE values for each fold
    print("MSE list:", mse_list)
    print("R^2 list:", r2_list)

    # Overall performance
    print(f"\nOverall Spatial Cross-Validation Mean Squared Error: {np.mean(mse_list)}")
    print(f"Overall Spatial Cross-Validation R^2 Score: {np.mean(r2_list)}")

    # Print feature importances for each fold
    print("\nFeature Importances for each fold:")
    print(all_feature_importances)

    # Save the results
    all_feature_importances.to_csv(f"feature_importances_{n_estimators}_spatial_validation.csv", index=False)
else:
    print("No feature importances to concatenate.")
EOF

