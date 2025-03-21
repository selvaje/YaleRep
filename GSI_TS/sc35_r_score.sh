#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc35_r_score.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc35_r_score.sh.%J.err
#SBATCH --job-name=sc35_r_score.sh 
#SBATCH --mem=10G


### for fin in stationID_x_y_valueALL_predictors_randX_YTest_obs_predict_N300_2leaf_4split_70sample_2RF.txt  stationID_x_y_valueALL_predictors_randX_YTrain_obs_predict_N300_2leaf_4split_70sample_2RF.txt stationID_x_y_valueALL_predictors_randX_YTestTrain_obs_predict_N300_2leaf_4split_70sample_2RF.txt ;  do  sbatch   --export=fin=$fin  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc35_r_score.sh  ; done

module load StdEnv
export fin=$fin
module load miniconda/23.5.2
source activate env_gsi_ts
# fin=stationID_x_y_valueALL_predictors_randX_YTest_obs_predict_N300_2leaf_4split_70sample_2RF.txt

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/KGE
python3 <<'EOF'
import os, sys 
import pandas as pd
import numpy as np
from numpy import savetxt
from sklearn import metrics
from sklearn.metrics import mean_squared_error
from sklearn.metrics import r2_score
from scipy import stats
from scipy.stats import pearsonr


fin=(os.environ["fin"])

table  = pd.read_csv(rf'./{fin}', header=0, sep=' ')


columns = ['QMIN','Q10','Q20','Q30','Q40','Q50','Q60','Q70','Q80','Q90','QMAX']  # List of columns
r2_ID = pd.DataFrame()  # Create an empty DataFrame to store the concatenated R2 values

for column in columns:
    r2_values = table.groupby('ID').apply(lambda x: r2_score(x[column], x[column + '.1'])).reset_index(name=column)
    r2_ID = pd.concat([r2_ID, r2_values.set_index('ID')], axis=1)  # Concatenate the R2 values along the columns

print(r2_ID.head(6))

r2_ID['min']=r2_ID[['QMIN','Q10','Q20','Q30','Q40','Q50','Q60','Q70','Q80','Q90','QMAX']].min(axis=1)
r2_ID['max']=r2_ID[['QMIN','Q10','Q20','Q30','Q40','Q50','Q60','Q70','Q80','Q90','QMAX']].max(axis=1)
r2_ID['mean']=r2_ID[['QMIN','Q10','Q20','Q30','Q40','Q50','Q60','Q70','Q80','Q90','QMAX']].mean(axis=1)
r2_ID['median']=r2_ID[['QMIN','Q10','Q20','Q30','Q40','Q50','Q60','Q70','Q80','Q90','QMAX']].median(axis=1)

r2_ID.reset_index(inplace=True)


print(r2_ID.head(6))

if fin == 'stationID_x_y_valueALL_predictors_randX_YTest_obs_predict_N300_2leaf_4split_70sample_2RF.txt':
    fout = 'r2_test.csv'

if fin == 'stationID_x_y_valueALL_predictors_randX_YTrain_obs_predict_N300_2leaf_4split_70sample_2RF.txt':
    fout = 'r2_train.csv'

if fin == 'stationID_x_y_valueALL_predictors_randX_YTestTrain_obs_predict_N300_2leaf_4split_70sample_2RF.txt':
    fout = 'r2_traintest.csv'
    
savetxt(rf'./{fout}', r2_ID  , delimiter=' ', fmt='%i %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f %4f',  header=' '.join(r2_ID.columns) , comments="" )

EOF


