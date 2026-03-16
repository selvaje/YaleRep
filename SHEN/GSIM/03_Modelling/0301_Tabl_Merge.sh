#!/bin/bash 

########
# MAIN #
########

dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW
dirProc=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/procd
dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/TERRA
dirMerge=/data/shen/Discharge/Data_Proc/GSIM/03_Modelling/Tabl_Merge

#################################
# retrieve GSIM data wo errors  #
#################################

#egrep -v -f  ${dirQC}/error_ID.dat ${dirGSIM}/tabl_GSIM.csv > ${dirGSIM}/tabl_GSIM_no_error.csv

#wc -l ${dirGSIM}/tabl_GSIM_no_error.csv

############
# var Data #
############

#wc -l ${dirProc}/var_All.csv 

##############
# Data Merge #
##############

paste -d, ${dirGSIM}/tabl_GSIM_no_error.csv ${dirProc}/var_All.csv  > ${dirMerge}/tabl_GSIM_Var.csv

relay=5

case $relay in
1)
  filter="1958-01-31";;
2)
  filter="1958-01-31|1958-02-28";;
3)
  filter="1958-01-31|1958-02-28|1958-03-31";;
4)
  filter="1958-01-31|1958-02-28|1958-03-31|1958-04-30";;
5)
  filter="1958-01-31|1958-02-28|1958-03-31|1958-04-30|1958-05-31";;
esac

awk -F, -v filter=${filter} '$3 !~ filter{if($6 != "NAN") print}' ${dirMerge}/tabl_GSIM_Var.csv > ${dirMerge}/tabl_GSIM_Var_relay${relay}.csv
