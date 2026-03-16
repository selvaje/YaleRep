#!/bin/bash 

##############
# TERRA Data #
##############

######################
# build colossal vrt #
######################

dirAgg=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Collosal/procd
dirTabl=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Collosal/Tabl

#awk  'BEGIN{FS="\t";OFS=","}{print $3,$4,$5,$6}' ${dirAgg}/TERRA_acc_agg.dat > ${dirTabl}/TERRA_tabl.csv

##############
# GRAND Data #
##############

#awk 'BEGIN{FS="\t";OFS=","}{if(NR==1) print $3; else for(i=1;i<=12;i++) print $3}' ${dirAgg}/GRAND_acc_agg.dat > ${dirTabl}/GRAND_tabl.csv

############
# GRIDSOIL #
############

awk 'BEGIN{FS="\t";OFS=","}{if(NR==1) print $2,$3,$4,$5,$6; else for(i=1;i<=708;i++) print $2,$3,$4,$5,$6}' ${dirAgg}/GRIDSOIL_acc_agg.dat > ${dirTabl}/GRIDSOIL_tabl.csv

########
# GRWL #
########

awk 'BEGIN{FS="\t";OFS=","}{if(NR==1) print $2,$3,$4,$5,$6; else for(i=1;i<=708;i++) print $2,$3,$4,$5,$6}' ${dirAgg}/GRWL_acc_agg.dat > ${dirTabl}/GRWL_tabl.csv

#######
# GSW #
#######

awk 'BEGIN{FS="\t";OFS=","}{if(NR==1) print $2,$3,$4,$5; else for(i=1;i<=708;i++) print $2,$3,$4,$5}' ${dirAgg}/GSW_acc_agg.dat > ${dirTabl}/GSW_tabl.csv

