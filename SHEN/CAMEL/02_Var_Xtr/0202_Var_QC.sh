#!/bin/bash 

##############
# TERRA Data #
##############

dirVar=/mnt/shared/data_from_yale/dataproces
dirSnp=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Snap_pts
dirOut=/data/shen/Discharge/Data_Proc/CAMEL/02_Var_Xtr/Collosal

# grep '999999' ${dirOut}/procd/TERRA_acc_agg.dat> ${dirOut}/QC/TERRA_NA.tsv
# awk -F '\t' '{print $1}' ${dirOut}/QC/TERRA_NA.tsv > ${dirOut}/QC/TERRA_NA_ID.dat
# egrep -f ${dirOut}/QC/TERRA_NA_ID.dat ${dirSnp}/CAMEL_post_snap.dat | awk 'BEGIN{OFS="\t"}{print $2,$3}' > ${dirOut}/QC/TERRA_NA_geoLoc.tsv
# paste -d $'\t'  ${dirOut}/QC/TERRA_NA_geoLoc.tsv ${dirOut}/QC/TERRA_NA.tsv  > ${dirOut}/QC/TERRA_NA_w_geoLoc.tsv

if [ -f ${dirOut}/QC/TERRA_NA_reprod.dat ]; then
    rm -f ${dirOut}/QC/TERRA_NA_reprod.dat
fi

touch ${dirOut}/QC/TERRA_NA_reprod.dat

while read -r line; do
    fds=($(echo $line | tr "\t" " "))
    yrmo=($(echo ${fds[3]} | tr "-" " "))
    echo -n ${fds[@]:0:4} >> ${dirOut}/QC/TERRA_NA_reprod.dat
    var_Lst=(tmin tmax ppt soil)
    for var in ${var_Lst[@]}
    do
        Xtr=$(gdallocationinfo -geoloc -valonly ${dirVar}/TERRA/${var}_acc/${yrmo[0]}/${var}_${yrmo[0]}_${yrmo[1]}.vrt ${fds[0]} ${fds[1]})
        echo -n " ${Xtr}"   >> ${dirOut}/QC/TERRA_NA_reprod.dat
    done
    printf "\n" >> ${dirOut}/QC/TERRA_NA_reprod.dat
done < ${dirOut}/QC/TERRA_NA_w_geoLoc.tsv

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

