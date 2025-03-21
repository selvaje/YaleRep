import os, sys 
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor as RFReg
from sklearn.model_selection import train_test_split,GridSearchCV
from sklearn.pipeline import Pipeline
#from scipy.stats.stats import pearsonr
from scipy import stats
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def dat_split(ds,varRsp,varCov):
    dic_dat = {}
    X = ds.loc[:,varCov].values
    Y = ds.loc[:,varRsp].values
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.5, random_state=24) 
    y_train = np.ravel(Y_train)
    y_test = np.ravel(Y_test)
    dic_dat["X_tr"] = X_train
    dic_dat["X_te"] = X_test
    dic_dat["y_tr"] = y_train
    dic_dat["y_te"] = y_test
    return (dic_dat)

def para_tune(dic_dat) : 
    pipeline = Pipeline([('rf',RFReg())])
    parameters = {
        'rf__n_estimators':(500,1000,2000)}

    grid_search = GridSearchCV(pipeline,parameters,n_jobs=4,cv=3,scoring='r2',verbose=1)
    grid_search.fit(dic_dat['X_tr'],dic_dat['y_tr'])

    print (grid_search.best_score_)

    print ('Best Training score: %0.3f' % grid_search.best_score_)
    print ('Optimal parameters:')
    best_par = grid_search.best_estimator_.get_params()
    for par_name in sorted(parameters.keys()):
        print ('\t%s: %r' % (par_name, best_par[par_name]))


def model_build(dic_dat,varRsp, feats, flag="Ori") :
    rfReg = RFReg(n_estimators=500,max_features="auto",max_samples=0.67,n_jobs=-1,random_state=24)
    rfReg.fit(dic_dat['X_tr'], dic_dat['y_tr']);
    dic_pred = {}
    dic_pred['train'] = rfReg.predict(dic_dat['X_tr'])
    dic_pred['test'] = rfReg.predict(dic_dat['X_te'])
    arr_r = [stats.pearsonr(dic_pred['train'],dic_dat['y_tr'])[0],stats.pearsonr(dic_pred['test'],dic_dat['y_te'])[0]]

    figname = "scatter_pred_" + varRsp + "_" + flag + ".png"
    fig, ax = plt.subplots(nrows=1,ncols=2,num=None,figsize=(8,4),dpi=200)
    st = fig.suptitle(varRsp + " (" + flag + ")",fontsize="x-large")

    plt.subplot(1,2,1)
    plt.scatter(dic_dat['y_tr'],dic_pred['train'],s=1)
    plt.xlabel('obs')
    plt.ylabel('pred')
    ident = [min(min(dic_dat['y_tr']),min(dic_pred['train'])), max(max(dic_dat['y_tr']),max(dic_pred['train']))]
    plt.plot(ident,ident,'r--')
    plt.title("Train (r = " + str("{:.2f}".format(arr_r[0])) + ")")
#    plt.text(0.1,0.9,"r = " + str("{:.2f}".format(arr_r[0])), horizontalalignment='center',verticalalignment='top', fontsize=14)
    plt.subplot(1,2,2)
    plt.scatter(dic_dat['y_te'],dic_pred['test'],s=1)
    plt.xlabel('obs')
    plt.ylabel('pred')
    ident = [min(min(dic_dat['y_te']),min(dic_pred['test'])), max(max(dic_dat['y_te']),max(dic_pred['test']))]
    plt.plot(ident,ident,'r--')
    plt.title("Test (r = " + str("{:.2f}".format(arr_r[1])) + ")")
#    plt.text(0.1,0.9,"r = " + str("{:.2f}".format(arr_r[1])), verticalalignment='top', fontsize=14)             
    fig.tight_layout()
    st.set_y(0.99)
    fig.subplots_adjust(top=0.85)
    plt.savefig(dirOut + figname)

    figname = "varImp_" + varRsp + "_" + flag + ".png"
    fig, ax = plt.subplots(nrows=1,ncols=1,num=None,figsize=(6,12),dpi=200)
    impt = [rfReg.feature_importances_, np.std([tree.feature_importances_ for tree in rfReg.estimators_],axis=1)] 
    ind = np.argsort(impt[0])
    plt.barh(range(len(feats)),impt[0][ind],color="b", xerr=impt[1][ind], align="center")
    plt.yticks(range(len(feats)),feats[ind])
#    plt.yticks(range(len(feats)),[feats[i] for i in range(len(ind))]);
    fig.tight_layout()
    st.set_y(0.99)
    fig.subplots_adjust(top=0.95)
    plt.savefig(dirOut + figname)

fCSV = sys.argv[1]
fPath, fName = os.path.split(fCSV)
fPfx, fSfx = os.path.splitext(fName)
dirOut = sys.argv[2]
fds = fPfx.split("_")
varT = sys.argv[3]
relay = sys.argv[4]

dsIn = pd.read_csv(fCSV)

#######################
# data transformation #
#######################

dsIn['yj'], lmbda =  stats.yeojohnson(dsIn[varT])

# figname = "hist_GSIM_Terra_" + varT + "_TR.png"
# fig, ax = plt.subplots(nrows=2,ncols=2,num=None,figsize=(12,6),dpi=200)
# st = fig.suptitle(varT,fontsize="x-large")
# plt.subplot(1,2,1)
# plt.hist(dsIn['yj'],bins=100,alpha=0.8)
# plt.title("YeoJohnson")
# plt.subplot(1,2,2)
# stats.probplot(dsIn['yj'],dist='norm',plot=plt)
# fig.tight_layout()
# st.set_y(0.97)
# fig.subplots_adjust(top=0.9)
# plt.savefig(dirOut + figname)

# figname = "hist_GSIM_Terra_" + varT + "_Ori.png"
# fig, ax = plt.subplots(nrows=2,ncols=2,num=None,figsize=(12,6),dpi=200)
# st = fig.suptitle(varT,fontsize="x-large")
# plt.subplot(1,2,1)
# plt.hist(dsIn[varT],bins=100,alpha=0.8)
# plt.title("Original")
# plt.subplot(1,2,2)
# stats.probplot(dsIn[varT],dist='norm',plot=plt)
# fig.tight_layout()
# st.set_y(0.97)
# fig.subplots_adjust(top=0.9)
# plt.savefig(dirOut + figname)


##############
# Modelling  #
##############

#featbase = ['aet','def','pet','PDSI','q','soil','srad','swe','ws','vpd','ppt','tmax','tmin','vap']    
featbase = ['aet','def','pet','PDSI','soil','srad','swe','ws','vpd','ppt','tmax','tmin','vap']

feats = [ ]
for i in range(int(relay) + 1) :
    baseadd = [str(i)] * len(featbase)
    feats += [a + b for a, b in zip(featbase,baseadd)]

feats = np.array(feats,dtype='str')
feats += ['LAT','LONG']

dic_Ori = dat_split(dsIn,varT,feats)
dic_TR = dat_split(dsIn,'yj',feats)
model_build(dic_Ori, varT, feats)
model_build(dic_TR, varT, feats, flag="TR")


