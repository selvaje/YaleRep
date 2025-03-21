#!/bin/bash 

function var_Xtr_Stat(){
    local args=("$@")    
    local fSTN=${args[0]}
    export dirVar=${args[1]}
    export dirOut=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}
if [ -d ${dirOut}/${datSet} ]; then
    rm -rf ${dirOut}/${datSet}
fi

mkdir ${dirOut}/${datSet}

cut -d, -f1-6 ${fSTN} | xargs -n 1 -P 70 bash -c $'
line=$1
fds=($(echo $line | tr "," " "))
for var in ${varLst[@]}
do
    if [ -f ${dirOut}/${datSet}/${var}_${fds[0]}.dat ]; then
        rm ${dirOut}/${datSet}/${var}_${fds[0]}.dat
    fi
    touch ${dirOut}/${datSet}/${var}_${fds[0]}.dat
    ls ${dirOut}/${datSet}/${var}_${fds[0]}.dat

case ${datSet} in 
SOILGRIDS )
    echo ${fds[@]:1:2} | gdallocationinfo -geoloc ${dirVar}/${datSet}/${var}_acc/${var}_WeigAver.vrt >> ${dirOut}/${datSet}/${var}_${fds[0]}.dat ;;
GRWL )
   echo ${fds[@]:1:2} | gdallocationinfo -geoloc ${dirVar}/${datSet}/${datSet}_${var}_acc/${datSet}_${var}.vrt >> ${dirOut}/${datSet}/${var}_${fds[0]}.dat;;
GSW )
  echo ${fds[@]:1:2} | gdallocationinfo -geoloc ${dirVar}/${datSet}/${var}_acc/${var}.vrt >> ${dirOut}/${datSet}/${var}_${fds[0]}.dat;;
esac 
done
' _
}

########
# MAIN #
########

##############
# TERRA Data #
##############

# dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirOut=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/TERRA
# dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/TERRA

# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# cut -d, -f1-6 ${dirQC}/TS_summ_error.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# var_Lst=(tmin soil tmax ppt)
 
# for var in ${var_Lst[@]}
# do
#     if [ -f ${dirOut}/${var}_${fds[0]}.dat ]; then
#         rm ${dirOut}/${var}_${fds[0]}.dat
#     fi
#     touch ${dirOut}/${var}_${fds[0]}.dat
#     for year in {1958..2016}
#     do
#         for mon in {01..12}
#         do
#          echo ${fds[@]:1:2} | gdallocationinfo -geoloc ${dirVar}/TERRA/${var}_acc/${year}/${var}_${year}_${mon}.vrt >> ${dirOut}/${var}_${fds[0]}.dat
#         done
#     done
# done
# ' _

###############
# GRANDE DATA #
###############

# dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirOut=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW/GRAND
# dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/GRAND

# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
 
# if [ -f ${dirOut}/GRAND_${fds[0]}.dat ]; then
#    rm ${dirOut}/GRAND_${fds[0]}.dat
# fi
# touch ${dirOut}/GRAND_${fds[0]}.dat

# for year in {1958..2016}
# do
#     echo ${fds[@]:1:2} | gdallocationinfo -geoloc ${dirVar}/GRAND/${year}_acc/GRanD_${year}.vrt >> ${dirOut}/GRAND_${fds[0]}.dat
# done
# ' _

#####################
# Static Variables  #
#####################

dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
dirVar=/mnt/shared/data_from_yale/dataproces
dirOut=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW

############
# GRIDSOIL #
############

# varArr=(AWCtS CLYPPT SNDPPT SLTPPT WWP)
# var_Xtr_Stat ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirVar} ${dirOut} SOILGRIDS ${varArr[@]}

########
# GRWL #
########

varArr=(canal delta lake river water)
var_Xtr_Stat ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirVar} ${dirOut} GRWL ${varArr[@]}

#######
# GSW #
#######

varArr=(extent occurrence recurrence seasonality)
var_Xtr_Stat ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirVar} ${dirOut} GSW ${varArr[@]}
