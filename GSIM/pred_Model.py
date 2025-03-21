import os, sys 
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor as RFReg
from sklearn.model_selection import train_test_split,GridSearchCV
from sklearn.pipeline import Pipeline
from xgboost import XGBRegressor as XGBReg
from xgboost import plot_importance
from scipy import stats
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def hist_plt(ds,varRsp):
    figname = "hist_" + varT + "_TR.png"
    fig, ax = plt.subplots(nrows=2,ncols=2,num=None,figsize=(12,6),dpi=200)
    st = fig.suptitle(varT,fontsize="x-large")
    plt.subplot(1,2,1)
    plt.hist(ds['yj'],bins=100,alpha=0.8)
    plt.title("YeoJohnson")
    plt.subplot(1,2,2)
    stats.probplot(ds['yj'],dist='norm',plot=plt)
    fig.tight_layout()
    st.set_y(0.97)
    fig.subplots_adjust(top=0.9)
    plt.savefig(dirOut + figname)

    figname = "hist_" + varT + "_Ori.png"
    fig, ax = plt.subplots(nrows=2,ncols=2,num=None,figsize=(12,6),dpi=200)
    st = fig.suptitle(varT,fontsize="x-large")
    plt.subplot(1,2,1)
    plt.hist(ds[varT],bins=100,alpha=0.8)
    plt.title("Original")
    plt.subplot(1,2,2)
    stats.probplot(ds[varT],dist='norm',plot=plt)
    fig.tight_layout()
    st.set_y(0.97)
    fig.subplots_adjust(top=0.9)
    plt.savefig(dirOut + figname)

def corr_plt(ds,varLst):
    nVar = len(varLst)
    for i in range(nVar) :
        for j in range(i+1, nVar, 1) :
            pearson = stats.pearsonr(ds[varLst[i]],ds[varLst[j]])[0]            
            figname = "corr_" + varLst[i] + "_" + varLst[j] + ".png"
            fig, ax = plt.subplots(nrows=1,ncols=1,num=None,figsize=(6,6),dpi=200)
            st = fig.suptitle("Corr.",fontsize="x-large")
            plt.scatter(ds[varLst[i]],ds[varLst[j]],s=1)
            ident = [min(min(ds[varLst[i]]),min(ds[varLst[j]])), max(max(ds[varLst[i]]),max(ds[varLst[j]]))]
            plt.plot(ident,ident,'r--')
            plt.xlabel(varLst[i])
            plt.ylabel(varLst[j])
            plt.title("(r = " + str("{:.2f}".format(pearson)) + ")")        
            fig.tight_layout()
            st.set_y(0.97)
            fig.subplots_adjust(top=0.9)
            plt.savefig(dirOut + figname)
            plt.close(fig)
    
def dat_split(ds,varRsp,varCov):
    dic_dat = {}
    ds.dropna(subset=[varRsp] + varCov,inplace=True)
    X = ds.loc[:,varCov].values
    Y = ds.loc[:,varRsp].values
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.5, random_state=24) 
    y_train = np.ravel(Y_train)
    y_test = np.ravel(Y_test)
    dic_dat["X_tr"] = X_train
    dic_dat["X_te"] = X_test
    dic_dat["y_tr"] = y_train
    dic_dat["y_te"] = y_test
    print (len(y_train))
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


def model_build(dic_dat, varRsp, feats, model, flag="Ori") :
    if model == 'RF' : 
        learner = RFReg(n_estimators=500,max_features="auto",max_samples=0.67,n_jobs=-1,random_state=24)
    elif model == 'XGB' : 
        learner = XGBReg(booster='dart',n_estimators=500,learning_rate=0.05,max_depth=4,gamma=0,random_state=24)
    learner.fit(dic_dat['X_tr'], dic_dat['y_tr']);
# predition and scatter plot
    dic_pred = {}
    dic_pred['train'] = learner.predict(dic_dat['X_tr'])
    dic_pred['test'] = learner.predict(dic_dat['X_te'])
    arr_r = [stats.pearsonr(dic_pred['train'],dic_dat['y_tr'])[0],stats.pearsonr(dic_pred['test'],dic_dat['y_te'])[0]]

# export data
    fname = "exp_" + "data" + "_" + varRsp + "X" + "_" + flag + ".csv"
    dfOut = pd.DataFrame(dic_dat['X_tr'])
    dfOut.to_csv(fname,index=False,header=False)
    fname = "exp_" + "data" + "_" +  varRsp + "Y" +  "_" + flag + ".csv"
    dfOut = pd.DataFrame(dic_dat['y_tr'])
    dfOut.to_csv(fname,index=False,header=False)
    fname = "exp_" + "pred" + "_" + varRsp + "Y"  + "_" + flag + ".csv"    
    dfOut = pd.DataFrame(dic_pred['train'])
    dfOut.to_csv(fname,index=False,header=False)
    
    figname = "scatter_" + model + "_" + varRsp + "_" + flag + ".png"
    fig, ax = plt.subplots(nrows=1,ncols=2,num=None,figsize=(8,4),dpi=200)
    st = fig.suptitle(model + ":" + varRsp + " (" + flag + ")",fontsize="x-large")
    plt.subplot(1,2,1)
    plt.scatter(dic_dat['y_tr'],dic_pred['train'],s=1)
    plt.xlabel('obs')
    plt.ylabel('pred')
    ident = [min(min(dic_dat['y_tr']),min(dic_pred['train'])), max(max(dic_dat['y_tr']),max(dic_pred['train']))]
    plt.plot(ident,ident,'r--')
    plt.title("Train (r = " + str("{:.2f}".format(arr_r[0])) + ")")
    plt.subplot(1,2,2)
    plt.scatter(dic_dat['y_te'],dic_pred['test'],s=1)
    plt.xlabel('obs')
    plt.ylabel('pred')
    ident = [min(min(dic_dat['y_te']),min(dic_pred['test'])), max(max(dic_dat['y_te']),max(dic_pred['test']))]
    plt.plot(ident,ident,'r--')
    plt.title("Test (r = " + str("{:.2f}".format(arr_r[1])) + ")")
    fig.tight_layout()
    st.set_y(0.99)
    fig.subplots_adjust(top=0.85)
    plt.savefig(dirOut + figname)
# importance plot
    figname = "varImp_" + model + "_" +  varRsp + "_" + flag + ".png"
    fig, ax = plt.subplots(nrows=1,ncols=1,num=None,figsize=(6,12),dpi=200)
    if model == 'RF' : 
        feats = np.array(feats,dtype='str')
        impt = [learner.feature_importances_, np.std([tree.feature_importances_ for tree in learner.estimators_],axis=1)] 
        ind = np.argsort(impt[0])
        plt.barh(range(len(feats)),impt[0][ind],color="b", xerr=impt[1][ind], align="center")
        plt.yticks(range(len(feats)),feats[ind])
    elif model == 'XGB' : 
        learner.get_booster().feature_names = feats
        plot_importance(learner.get_booster()) 
    fig.tight_layout()
    plt.savefig(dirOut + figname)


fCSV = sys.argv[1]
fPath, fName = os.path.split(fCSV)
fPfx, fSfx = os.path.splitext(fName)
dirOut = sys.argv[2]
varT = sys.argv[3]
relay = sys.argv[4]

dsIn = pd.read_csv(fCSV,low_memory=False)

#dsIn.dropna(inplace=True)
# don't do it here. causing data loss

#######################
# data transformation #
#######################

#dsIn['yj'], lmbda =  stats.yeojohnson(dsIn[varT])

# split date into year and month 
#psDat = dsIn['date']
#dsDat = psDat.str.split(pat='-',expand=True)
#dsIn[['year','month']] = dsDat.iloc[:,1:3]

##############
# Modelling  #
##############

featbase = ['soil','ppt','tmax','tmin']

feats = [ ]
for i in range(int(relay) + 1) :
    baseadd = [str(i)] * len(featbase)
    feats += [a + b for a, b in zip(featbase,baseadd)]

feats.extend(['extent','occurrence','recurrence','seasonality'])
#feats_stat = ['GRAND','AWCtS','CLYPPT','SNDPPT','SLTPPT','WWP','canal','delta','lake','river.1','water','extent','occurrence','recurrence','seasonality']

# ful data w/o relay
#feats = ['aet','def','pet','PDSI','soil','srad','swe','ws','vpd','ppt','tmax','tmin','vap']
#feats=dsIn.columns.values[8:-1]

#hist_plt(dsIn,varT)
#corr_plt(dsIn,feats_stat)

dic_Ori = dat_split(dsIn,varT,feats)
model_build(dic_Ori, varT, feats, 'RF')
# dic_TR = dat_split(dsIn,'yj',feats)
# model_build(dic_TR, varT, feats, 'RF', flag="TR")

