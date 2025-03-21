#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 10:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc04_rf_tuning.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc04_rf_tuning.sh.%J.err
#SBATCH --job-name=sc04_rf_tuning.sh
#SBATCH --mem=100G
### -p scavenge

### for NUM in {1..30}; do sbatch --export=DIR=icesat2_66 /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc04_rf_tuning.sh ; done

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

module load Python/3.7.0-foss-2018b
module load miniconda

# conda create -n con_rf python numpy scipy pandas matplotlib ipython jupyter r-irkernel r-ggplot2 r-tidyverse 
source activate con_rf 
# conda search sklearn


export RAM=/dev/shm
export DIR=$DIR
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt/${DIR}

cd $INP_DIR
python <<'EOF'

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor as RFReg
from sklearn.model_selection import train_test_split,GridSearchCV
from sklearn import preprocessing
from sklearn.pipeline import Pipeline
from scipy.stats.stats import pearsonr
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

features = pd.read_csv('filter_tree_land_cover.txt', header=None, sep=' ')
features.columns = ['gedi', 'ice_70', 'ice_75', 'ice_80', 'ice_85', 'ice_90', 'ice_95', 'tree_cover', 'land_cover']
features.head(5)
feat = features.iloc[:,1:9].columns.values

# normalize land cover from 0 to 27. so 10:0, 180:27
le = preprocessing.LabelEncoder()
le.fit(features['land_cover'])
features['land_cover'] = le.transform(features['land_cover'])

labels = np.array(features['gedi'])
features= features.drop('gedi', axis = 1)
feature_list = list(features.columns)
features = np.array(features)

#train_features, test_features, train_labels, test_labels = train_test_split(features, labels, test_size = 0.997, random_state = 56)
train_features, test_features, train_labels, test_labels = train_test_split(features, labels, test_size = 0.75, random_state = 88)

print('Training Features Shape:', train_features.shape)
print('Training Labels Shape:', train_labels.shape)
print('Testing Features Shape:', test_features.shape)
print('Testing Labels Shape:', test_labels.shape)

baseline_preds = test_features[:, feature_list.index('tree_cover')]
baseline_errors = abs(baseline_preds - test_labels)
print('Average baseline error: ', round(np.mean(baseline_errors), 2))

pipeline = Pipeline([('rf',RFReg())])

parameters = {
        'rf__max_features':("log2","sqrt",0.33),
        'rf__max_samples':(0.5,0.6,0.7),
        'rf__n_estimators':(500,1000,2000),
        'rf__max_depth':(50,100,200)}

grid_search = GridSearchCV(pipeline,parameters,n_jobs=-1,cv=3,scoring='r2',verbose=1)
grid_search.fit(train_features, train_labels)

print ('Best Training score: %0.3f' % grid_search.best_score_)
print ('Optimal parameters:')
best_par = grid_search.best_estimator_.get_params()
for par_name in sorted(parameters.keys()):
    print ('\t%s: %r' % (par_name, best_par[par_name]))

EOF

exit







# Instantiate model with 1000 decision trees
rf = RFReg(n_estimators=500, max_features=0.33, max_depth=200, max_samples=0.7, n_jobs=-1, random_state=24)
rf.fit(train_features, train_labels)

predictions = rf.predict(test_features)

dic_pred = {}
dic_pred['train'] = rf.predict(train_features)
dic_pred['test'] = rf.predict(test_features)
pearsonr_get = [round(pearsonr(dic_pred['train'], train_labels)[0], 2), round(pearsonr(dic_pred['test'], test_labels)[0], 2)]

print('Pearson R of training and test are: ', pearsonr_get)

# errors = abs(predictions - test_labels)
mse = [round(np.mean(abs(dic_pred['train'] - train_labels)), 2), round(np.mean(abs(dic_pred['test'] - test_labels)), 2)]
print('Mean Absolute Error:', mse, 'degrees.')


pp1 = PdfPages('scatter.pdf')
plt.rcParams["figure.figsize"] = (6,6)
plot1 = plt.figure()
ax = plot1.add_subplot(111)
plt.scatter(train_labels, dic_pred['train'])
plt.xlabel('orig')
plt.ylabel('pred')
ident = [-1, 80]
ax.text(0, 69, 'MSE: '+ str(mse[0]), fontsize=15,  color='black')
ax.text(0, 75, 'PCC: '+ str(pearsonr_get[0]), fontsize=15,  color='black')
plt.plot(ident, ident, 'r--')
pp1.savefig(plot1)

plot2 = plt.figure()
ax = plot2.add_subplot(111)
plt.scatter(test_labels, dic_pred['test'])
plt.xlabel('orig')
plt.ylabel('pred')
ident = [-1, 80]
ax.text(0, 69, 'MSE: '+ str(mse[1]), fontsize=15,  color='black')
ax.text(0, 75, 'PCC: '+ str(pearsonr_get[1]), fontsize=15,  color='black')
plt.plot(ident, ident, 'r--')
pp1.savefig(plot2)
pp1.close()

impt = [rf.feature_importances_, np.std([tree.feature_importances_ for tree in rf.estimators_],axis=1)]
ind = np.argsort(impt[0])

pp = PdfPages('importance.pdf')
plot3 = plt.figure()
plt.rcParams["figure.figsize"] = (4,8)
plt.barh(range(len(feat)), impt[0][ind], color="b", xerr=impt[1][ind], align="center")
plt.yticks(range(len(feat)), feat[ind])
pp.savefig(plot3)
pp.close()





