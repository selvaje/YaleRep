#!/bin/bash 

##############
# TERRA Data #
##############

dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/TERRA
export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/TERRA

# var_Lst=(tmin soil tmax ppt)

# for var in ${var_Lst[@]}
# do	   
#     if [ -f ${dirQC}/${var}_wc.dat ]; then
#         rm ${dirQC}/${var}_wc.dat
#     fi
#     touch ${dirQC}/${var}_wc.dat
# done
    
# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# var_Lst=(tmin soil tmax ppt)

# for var in ${var_Lst[@]}
# do
#     wc -l ${dirRAW}/${var}_${fds[0]}.dat >>  ${dirQC}/${var}_wc.dat
# done
# ' _

# for var in ${var_Lst[@]}
# do
#    echo $var 
#      awk '{print $1}' ${dirQC}/${var}_wc.dat | sort | uniq -c
# #   awk '{if ($1 != 3540) print}' ${dirQC}/${var}_wc.dat | tee  ${dirQC}/error.dat
# done

#awk -F "/" '{print $NF}' ${dirQC}/error.dat  | cut -d "_" -f2- | cut -d "." -f1 | tee ${dirQC}/error_ID.dat 

#egrep -f ${dirQC}/error_ID.dat  ${dirGSIM}/TS_summ_!phi_snapped.csv > ${dirQC}/TS_summ_error.csv

#egrep -v -f ${dirQC}/error_ID.dat  ${dirGSIM}/TS_summ_!phi_snapped.csv > ${dirQC}/TS_summ_wo_error.csv

awk -F, '{print $1}' ${dirQC}/TS_summ_wo_error.csv > ${dirQC}/ID_wo_error.dat

# back to VarXtr script

###############
# GRANDE DATA #
###############

# dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/GRAND
# export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/GRAND

# if [ -f ${dirQC}/GRAND_wc.dat ]; then
#     rm ${dirQC}/GRAND_wc.dat
# fi
# touch ${dirQC}/GRAND_wc.dat

# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# wc -l ${dirRAW}/GRAND_${fds[0]}.dat >>  ${dirQC}/GRAND_wc.dat
# ' _

#awk '{print $1}' ${dirQC}/GRAND_wc.dat | sort | uniq -c

#####################
# Static Variables  #
#####################

#dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
#dirVar=/mnt/shared/data_from_yale/dataproces

############
# GRIDSOIL #
############

# export dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/SOILGRIDS
# export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/SOILGRIDS

#varArr=(AWCtS CLYPPT SNDPPT SLTPPT WWP)

# for var in ${varArr[@]}
# do	   
#     if [ -f ${dirQC}/${var}_wc.dat ]; then
#         rm ${dirQC}/${var}_wc.dat
#     fi
#     touch ${dirQC}/${var}_wc.dat
# done
    
# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# varArr=(AWCtS CLYPPT SNDPPT SLTPPT WWP)

# for var in ${varArr[@]}
# do
#     wc -l ${dirRAW}/${var}_${fds[0]}.dat >>  ${dirQC}/${var}_wc.dat
# done
# ' _

# for var in ${varArr[@]}
# do
#    echo $var 
#      awk '{print $1}' ${dirQC}/${var}_wc.dat | sort | uniq -c
# done

########
# GRWL #
########

# export dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/GRWL
# export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/GRWL

# varArr=(canal delta lake river water)

# for var in ${varArr[@]}
# do	   
#     if [ -f ${dirQC}/${var}_wc.dat ]; then
#         rm ${dirQC}/${var}_wc.dat
#     fi
#     touch ${dirQC}/${var}_wc.dat
# done
    
# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# varArr=(canal delta lake river water)

# for var in ${varArr[@]}
# do
#     wc -l ${dirRAW}/${var}_${fds[0]}.dat >>  ${dirQC}/${var}_wc.dat
# done
# ' _

# for var in ${varArr[@]}
# do
#    echo $var 
#      awk '{print $1}' ${dirQC}/${var}_wc.dat | sort | uniq -c
# done

#######
# GSW #
#######

# export dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/GSW
# export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/GSW

# varArr=(extent occurrence recurrence seasonality)

# for var in ${varArr[@]}
# do	   
#     if [ -f ${dirQC}/${var}_wc.dat ]; then
#         rm ${dirQC}/${var}_wc.dat
#     fi
#     touch ${dirQC}/${var}_wc.dat
# done
    
# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# varArr=(extent occurrence recurrence seasonality)

# for var in ${varArr[@]}
# do
#     wc -l ${dirRAW}/${var}_${fds[0]}.dat >>  ${dirQC}/${var}_wc.dat
# done
# ' _

# for var in ${varArr[@]}
# do
#    echo $var 
#      awk '{print $1}' ${dirQC}/${var}_wc.dat | sort | uniq -c
# done
