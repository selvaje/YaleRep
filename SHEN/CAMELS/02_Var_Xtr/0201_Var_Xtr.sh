#!/bin/bash 

function lst_const_stat(){
    local args=("$@")
    local varNames=(${args[@]::((${#args[@]} - 3))})
    local agg_Lst=(${args[-3]})
for var in ${varNames[@]}
do
    agg_Lst+=(${args[-2]}/${args[-1]}_${var}_grep.dat)
done
paste -d "\t" ${agg_Lst[@]} > ${args[-2]}/${args[-1]}_agg.dat
echo "ID" ${varNames[@]} | tr " " "\t"> ${args[-2]}/header.dat
cat ${args[-2]}/header.dat ${args[-2]}/${args[-1]}_agg.dat > ${args[-2]}/temp.dat
mv ${args[-2]}/temp.dat ${args[-2]}/${args[-1]}_agg.dat
}

function lst_const_dynm(){
    local args=("$@")
    local varNames=(${args[@]::((${#args[@]} - 3))})
    local agg_Lst=(${args[-3]})
for var in ${varNames[@]}
do
    agg_Lst+=(${args[-2]}/${args[-1]}_${var}_grep.dat)
done
paste -d "\t" ${agg_Lst[@]} > ${args[-2]}/${args[-1]}_agg.dat
}

##############
# TERRA Data #
##############

######################
# build colossal vrt #
######################

# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirOut=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/VRT

#vrt_Lst=(tmin tmax ppt soil)

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

# gdalbuildvrt -separate ${dirOut}/TERRA_acc_${var}.vrt ${vrtLst[@]}

# ' _

# var Xtr #

# export dirSnp=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Snap_pts
# export dirVRT=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/VRT
# export dirOut=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Collosal

# varLst=(tmin)
# echo ${varLst[@]} | xargs -n 1 -P 2 bash -c $'
# var=$1
# awk \'{print $2,$3}\' ${dirSnp}/CAMEL_post_snap.dat  | gdallocationinfo -geoloc ${dirVRT}/TERRA_acc_${var}.vrt > ${dirOut}/RAW/TERRA_acc_${var}_RAW.dat
# echo $var > ${dirOut}/procd/TERRA_acc_${var}_grep.dat
# grep Value ${dirOut}/RAW/TERRA_acc_${var}_RAW.dat  | cut -d: -f2  >> ${dirOut}/procd/TERRA_acc_${var}_grep.dat
# wc -l ${dirOut}/procd/TERRA_acc_${var}_grep.dat
# ' _

#Generate ID TS tabl 

# echo -e "ID\t Date"   > ${dirOut}/procd/ID_date_monthly.dat

# while read -r line; do
#     for year in {1958..2016}
#       do
#          for mon in {01..12}
#          do
# 	     echo -e "${line}\t ${year}-${mon}" >> ${dirOut}/procd/ID_date_monthly.dat
# 	 done
#     done
# done < ${dirSnp}/CAMEL_ID.dat

#lst_const_dynm ${varLst[@]} ${dirOut}/procd/ID_date_monthly.dat ${dirOut}/procd TERRA_acc


##############
# GRAND Data #
##############

######################
# build colossal vrt #
######################

#dirVar=/mnt/shared/data_from_yale/dataproces
#dirOut=/data/shen/Discharge/Data_Proc/02_Var_Xtr/VRT

# declare -a var_Lst

# for year in {1958..2016}
# do
#      vrtLst+=(${dirVar}/GRAND/${year}_acc/GRanD_${year}.vrt)
# done

# echo ${vrtLst[@]}

# gdalbuildvrt -separate ${dirOut}/GRAND_acc.vrt ${vrtLst[@]}

###########
# var Xtr #
###########

# export dirVar=/mnt/shared/data_from_yale/dataproces
# export dirSnp=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Snap_pts
# export dirVRT=/data/shen/Discharge/Data_Proc/02_Var_Xtr/VRT
# export dirOut=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Collosal

# awk '{print $2,$3}' ${dirSnp}/CAMEL_post_snap.dat  | gdallocationinfo -geoloc ${dirVRT}/GRAND_acc.vrt > ${dirOut}/RAW/GRAND_acc_RAW.dat
# echo "GRAND" > ${dirOut}/procd/GRAND_acc_GRAND_grep.dat
# grep Value ${dirOut}/RAW/GRAND_acc_RAW.dat | cut -d: -f2 >> ${dirOut}/procd/GRAND_acc_GRAND_grep.dat
# wc -l ${dirOut}/procd/GRAND_acc_GRAND_grep.dat

#Generate ID TS tabl 

# echo -e "ID\t Date"   > ${dirOut}/procd/ID_date_yearly.dat

# while read -r line; do
#     for year in {1958..2016}
#     do
# 	     echo -e "${line}\t ${year}" >> ${dirOut}/procd/ID_date_yearly.dat
#     done
# done < ${dirSnp}/CAMEL_ID.dat

#lst_const_dynm "GRAND" ${dirOut}/procd/ID_date_yearly.dat ${dirOut}/procd GRAND_acc

# ############
# # GRIDSOIL #
# ############

#varLst=(AWCtS CLYPPT SNDPPT SLTPPT WWP)

# echo ${varLst[@]} | xargs -n 1 -P 5 bash -c $'
# var=$1
# awk \'{print $2,$3}\' ${dirSnp}/CAMEL_post_snap.dat  | gdallocationinfo -geoloc ${dirVar}/SOILGRIDS/${var}_acc/${var}_WeigAver.vrt > ${dirOut}/RAW/GRIDSOIL_acc_${var}_RAW.dat
# grep Value ${dirOut}/RAW/GRIDSOIL_acc_${var}_RAW.dat | cut -d: -f2 > ${dirOut}/procd/GRIDSOIL_acc_${var}_grep.dat
# wc -l ${dirOut}/procd/GRIDSOIL_acc_${var}_grep.dat
# ' _

#lst_const_stat ${varLst[@]} ${dirSnp}/CAMEL_ID.dat ${dirOut}/procd GRIDSOIL_acc

# ########
# # GRWL #
# ########

#varLst=(canal delta lake river water)

# echo ${varLst[@]} | xargs -n 1 -P 5 bash -c $'
# var=$1
# #awk \'{print $2,$3}\' ${dirSnp}/CAMEL_post_snap.dat  | gdallocationinfo -geoloc ${dirVar}/GRWL/GRWL_${var}_acc/GRWL_${var}.vrt > ${dirOut}/RAW/GRWL_acc_${var}_RAW.dat
# grep Value ${dirOut}/RAW/GRWL_acc_${var}_RAW.dat | cut -d: -f2 > ${dirOut}/procd/GRWL_acc_${var}_grep.dat
# wc -l ${dirOut}/procd/GRWL_acc_${var}_grep.dat
# ' _

#lst_const_stat ${varLst[@]} ${dirSnp}/CAMEL_ID.dat ${dirOut}/procd GRWL_acc

# #######
# # GSW #
# #######

#varLst=(extent occurrence recurrence seasonality)

# echo ${varLst[@]} | xargs -n 1 -P 4 bash -c $'
# var=$1
# awk \'{print $2,$3}\' ${dirSnp}/CAMEL_post_snap.dat  | gdallocationinfo -geoloc ${dirVar}/GSW/${var}_acc/${var}.vrt > ${dirOut}/RAW/GSW_acc_${var}_RAW.dat
# grep Value ${dirOut}/RAW/GSW_acc_${var}_RAW.dat | cut -d: -f2 > ${dirOut}/procd/GSW_acc_${var}_grep.dat
# wc -l ${dirOut}/procd/GSW_acc_${var}_grep.dat
# ' _

#lst_const_stat ${varLst[@]} ${dirSnp}/CAMEL_ID.dat ${dirOut}/procd GSW_acc

