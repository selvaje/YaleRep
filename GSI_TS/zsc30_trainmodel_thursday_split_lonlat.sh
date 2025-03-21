#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 30 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /home/st929/output/sc30_train_model_original.sh.%A_%a.out
#SBATCH -e /home/st929/output/sc30_train_model_original.sh.%A_%a.err
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
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score


# Define the file path
file_path = "/gpfs/gibbs/pi/hydro/st929/files_for_extracting/stationID_x_y_valueALL_predictors.txt"

# Load the file into a DataFrame
df = pd.read_csv(file_path, sep='\\s+')

# Add a random variable to the DataFrame
np.random.seed(42)
df['random_variable'] = np.random.rand(len(df))
# Create a unique identifier for each lon, lat pair

#df_mean = df.groupby(['YYYY', 'MM', 'ID', 'lon', 'lat']).mean(numeric_only=True).reset_index()
#df_mean= df_mean.drop(columns=['lon', 'lat',''])

# Ensure each lon, lat pair is only in either the training or test set
unique_ID = df['ID'].unique()
train_lon_lat, test_lon_lat = train_test_split(unique_ID, test_size=0.3, random_state=42)

# Create training and testing sets based on the unique lon, lat pairs
train_df = df[df['ID'].isin(train_lon_lat)]
test_df = df[df['ID'].isin(test_lon_lat)]

# Drop the lon_lat column as it's no longer needed
train_df = train_df.drop(columns=['ID'])
test_df = test_df.drop(columns=['ID'])

# Ensure the size of groups matches the size of X

# Load previously saved feature importances
X_selected_var = pd.read_csv('/gpfs/gibbs/pi/hydro/st929/files_for_extracting/feature_importances_400.csv', header=None, sep=',')
X_selected_var[1] = pd.to_numeric(X_selected_var[1], errors='coerce')
selected_features = X_selected_var.loc[X_selected_var[1] > 0.015, 0]
print("selected_features",selected_features)


# Define the target variable and predictors
target = 'Alkalinity'
predictors = [col for col in selected_features if col not in [target, 'Flux','lon','lat','Discharge']]

print("max_Alkalinity", np.max(df[target]))

# Separate predictors and target variable for training and testing sets
X_train = train_df[predictors]
y_train = train_df[target]
X_test = test_df[predictors]
y_test = test_df[target]

print("X_train shape:", X_train.shape)

# Print the columns of X_train
print("X_train columns:", X_train.columns)

# Print the shape of y_train
print("y_train shape:", y_train.shape)
print("y_train name:", y_train.name)



# Split the data into training and testing sets
#X_train, X_test, y_train, y_test = train_test_split(df[predictors], df[target], test_size=0.3, random_state=42)

# Initialize the Random Forest Regressor
model = RandomForestRegressor(
    random_state=24,
    n_estimators=1000,
    max_features='sqrt',  # Considering a subset of features at each split
    n_jobs=30,
    oob_score=True,
    bootstrap=True
)

# Train the model
model.fit(X_train, y_train)
# Make predictions on the test set
y_pred = model.predict(X_test)
y_pred_train=model.predict(X_train)

# Evaluate the model

mse = mean_squared_error(y_test, y_pred)
mean_y_test=np.mean(y_test)
mean_y_pred=np.mean(y_pred)
max_y_test=np.max(y_test)
max_y_pred=np.max(y_pred)
r2 = r2_score(y_test, y_pred)
r2_train=r2_score(y_train,y_pred_train)

print(f"Mean Squared Error: {mse}")
print(f"mean: {mean_y_test},{mean_y_pred}")
print(f"min: {np.min(y_test)},{np.min(y_pred)}")
print(f"max: {max_y_test},{max_y_pred}")
print(f"R^2 Score: {r2}")
print(f"R^2 Score Train: {r2_train}")


# Display feature importances
feature_importances = pd.DataFrame(model.feature_importances_, index=predictors, columns=['importance']).sort_values('importance', ascending=False)
print("\nFeature Importances:")
print(feature_importances)

# Save the results
feature_importances.to_csv(f"feature_importances_{os.environ['N_EST']}_initial_selection.csv")

# Optionally, you can use numpy or pandas to save the predictors as a CSV or txt
np.savetxt(f"predictors_used_{os.environ['N_EST']}.txt", predictors, fmt="%s")

# Save the Random Forest model as a .pkl file
with open(f"random_forest_model_{os.environ['N_EST']}.pkl", "wb") as model_file:
    dill.dump(model, model_file)  # Use dill.dump() or pickle.dump()

print("Model saved as .pkl file")



# Alternatively, save the predictors as a CSV using numpy
np.savetxt(f"predictors_used_{os.environ['N_EST']}.csv", predictors, fmt="%s")

EOF
