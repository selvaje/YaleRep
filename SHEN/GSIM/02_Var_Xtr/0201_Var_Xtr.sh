#!/bin/bash 

export dirVar=/mnt/shared/data_from_yale/dataproces
export dirOut=/data/shen/Discharge/Data_Proc/02_Var_Xtr/VRT

######################
# build colossal vrt #
######################

# vrt_Lst=(ppt tmax)

# echo ${vrt_Lst[@]} | xargs -n 1 -P 2 bash -c $'
# var=$1

# declare -a var_Lst

# for year in {1958..2016}
# do
#     for mon in {01..12}
#     do
#         vrtLst+=(${dirVar}/TERRA/${var}_acc/${year}/${var}_${year}_${mon}.vrt)
#     done
# done

# echo ${vrtLst[@]}

# gdalbuildvrt -separate ${dirOut}/TERRA_acc_${var}.vrt ${vrtLst[@]}

# ' _


###########
# var Xtr #
###########

export dirGSIM=/data/shen/Discharge/Data_Proc/02_Var_Xtr/GSIM_Summ
export dirVRT=/data/shen/Discharge/Data_Proc/02_Var_Xtr/VRT
export dirOut=/data/shen/Discharge/Data_Proc/02_Var_Xtr/Colossal

#awk -F, '{print $2,$3}' ${dirGSIM}/TS_summ_!phi_snapped.csv > ${dirGSIM}/coord_!phi_snapped.dat

vrt_Lst=(ppt tmax)
echo ${vrt_Lst[@]} | xargs -n 1 -P 2 bash -c $'
var=$1
cat ${dirGSIM}/coord_!phi_snapped.dat  | gdallocationinfo -geoloc ${dirVRT}/TERRA_acc_${var}.vrt > ${dirOut}/TERRA_acc_${var}_RAW.dat
' _


# cut -d, -f1-6 ${dirGSIM}/TS_summ_!phi_snapped.csv | xargs -n 1 -P 70 bash -c $'
# line=$1
# fds=($(echo $line | tr "," " "))
# var_Lst=(tmax)
 
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


####  
### seq can go from 1 to 708 . it identify the date inside the GSIM/metadata/date.txt
# seq 5 708 | xargs -n 1 -P 2 bash -c $'

# ID=$1 # date label 

# GDRIVE=/mnt/shared/data_from_yale/dataproces
# dirDate=/mnt/shared/data_from_yale/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/metadata
# dirLoc=/mnt/shared/data_from_yale/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/x_y_date
# dirOut=/mnt/shen/shen
# GSIMmean=/mnt/shared/data_from_yale/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping

# DATE=$(awk -v ID=$ID \'{ if(NR==ID+1824) print $2 }\' ${dirDate}/date.txt)
# DA_TE=$(echo $DATE | awk -F - \'{ print $1"_"$2 }\')
# YYYY=$(echo $DATE | awk -F - \'{ print $1 }\')
# MM=$(echo $DATE | awk -F - \'{ print $2 }\')

# echo $DATE 

# DATE1=$(awk -v n=1  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' ${dirDate}/date.txt)
# DA_TE1=$(echo $DATE1 | awk -F - \'{ print $1"_"$2 }\')
# YYYY1=$(echo $DATE1  | awk -F - \'{ print $1 }\')
# MM1=$(echo $DATE1    | awk -F - \'{ print $2 }\')

# DATE2=$(awk -v n=2  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' ${dirDate}/date.txt)
# DA_TE2=$(echo $DATE2 | awk -F - \'{ print $1"_"$2 }\')
# YYYY2=$(echo $DATE2  | awk -F - \'{ print $1 }\')
# MM2=$(echo $DATE2    | awk -F - \'{ print $2 }\')

# DATE3=$(awk -v n=3  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' ${dirDate}/date.txt)
# DA_TE3=$(echo $DATE3 | awk -F - \'{ print $1"_"$2 }\')
# YYYY3=$(echo $DATE3  | awk -F - \'{ print $1 }\')
# MM3=$(echo $DATE3    | awk -F - \'{ print $2 }\')

# DATE4=$(awk -v n=4  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' ${dirDate}/date.txt)
# DA_TE4=$(echo $DATE4 | awk -F - \'{ print $1"_"$2 }\')
# YYYY4=$(echo $DATE4  | awk -F - \'{ print $1 }\')
# MM4=$(echo $DATE4    | awk -F - \'{ print $2 }\')

# DATE5=$(awk -v n=5  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' ${dirDate}/date.txt)
# DA_TE5=$(echo $DATE5 | awk -F - \'{ print $1"_"$2 }\')
# YYYY5=$(echo $DATE5  | awk -F - \'{ print $1 }\')
# MM5=$(echo $DATE5    | awk -F - \'{ print $2 }\')

# echo $DA_TE  $YYYY $MM  $DA_TE1 $YYYY1 $MM1 $DA_TE2 $YYYY2 $MM2 $DA_TE3 $YYYY3 $MM3 $DA_TE4 $YYYY4 $MM4 $DA_TE5 $YYYY5 $MM5

# paste -d " " \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt      < ${dirLoc}/x_y_${DA_TE}.txt )  \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt   < ${dirLoc}/x_y_${DA_TE}.txt )  \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt   < ${dirLoc}/x_y_${DA_TE}.txt )  \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt   < ${dirLoc}/x_y_${DA_TE}.txt )  \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY4/ppt_${YYYY4}_$MM4.vrt   < ${dirLoc}/x_y_${DA_TE}.txt )  \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY5/ppt_${YYYY5}_$MM5.vrt   < ${dirLoc}/x_y_${DA_TE}.txt )  > ${dirOut}/predictors_values_a_${DA_TE}.txt
# paste -d " " \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt    < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY4/tmin_${YYYY4}_$MM4.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY5/tmin_${YYYY5}_$MM5.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) > ${dirOut}/predictors_values_b_${DA_TE}.txt
# paste -d " " \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt    < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY4/tmax_${YYYY4}_$MM4.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY5/tmax_${YYYY5}_$MM5.vrt < ${dirLoc}/x_y_${DA_TE}.txt ) > ${dirOut}/predictors_values_c_${DA_TE}.txt
# paste -d " " \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt       < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt     < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt     < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt     < ${dirLoc}/x_y_${DA_TE}.txt ) \
# <( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/WWP_acc/WWP_WeigAver.vrt           < ${dirLoc}/x_y_${DA_TE}.txt )  > ${dirOut}/predictors_values_d_${DA_TE}.txt

# # paste -d " " \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRAND/${YYYY}_acc/GRanD_${YYYY}.vrt          < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_canal_acc/GRWL_canal.vrt           < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_delta_acc/GRWL_delta.vrt           < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_lake_acc/GRWL_lake.vrt             < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_river_acc/GRWL_river.vrt           < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_water_acc/GRWL_water.vrt           < ${dirLoc}/x_y_${DA_TE}.txt )  > ${dirOut}/predictors_values_e_${DA_TE}.txt

# # paste -d " " \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/extent_acc/extent.vrt                    < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/occurrence_acc/occurrence.vrt            < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/recurrence_acc/recurrence.vrt            < ${dirLoc}/x_y_${DA_TE}.txt ) \
# # <( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/seasonality_acc/seasonality.vrt          < ${dirLoc}/x_y_${DA_TE}.txt )  > ${dirOut}/predictors_values_f_${DA_TE}.txt

# # paste -d " " ${GSIMmean}/stationID_x_y_value_${DA_TE}.txt ${dirOut}/predictors_values_{a,b,c,d,e,f}_${DA_TE}.txt > ${dirOut}/stationID_x_y_value_predictors_${DA_TE}.txt 
# # rm ${dirOut}/predictors_values_*_${DA_TE}.txt 

# ' _ 
