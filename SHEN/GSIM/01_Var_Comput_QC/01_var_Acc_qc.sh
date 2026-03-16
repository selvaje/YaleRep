#!/bin/bash

export dirDatSet=/mnt/shared/data_from_yale/dataproces
export dirOut=/data/shen/Discharge/Data_Proc/GSIM/01_Var_Comput_QC/01_Var_Range

########################
# Data completion test #
########################

# yrLst=($(seq 1958 2019))
# monLst=($(seq -f "%02g" 01 12))

#################
# TERRA dataSet #
#################

# SetNam=TERRA
# varLst=(tmin soil)

# if [ -d ${dirOut}/${SetNam} ]; then
#     rm -rf ${dirOut}/${SetNam}
# fi

# mkdir ${dirOut}/${SetNam}

# echo "dynamic var check" > ${dirOut}/QC_dynam_Summ.dat

# for var in ${varLst[@]}
# do
# #    mkdir ${dirOut}/${SetNam}/${var}
#     for year in ${yrLst[@]}
#     do
# #	mkdir ${dirOut}/${SetNam}/${var}/${year}
# 	for mon in ${monLst[0]}
# 	do
#             echo ${SetNam} $var $year $mon
# 	done
#     done
# done  | xargs -n 4 -P 70 bash -c $'
# datSet=$1
# var=$2
# year=$3
# mon=$4
# #echo $var $year $mon
# fname=${var}_${year}_${mon}
# valNX=$(gdalinfo -mm ${dirDatSet}/${datSet}/${var}/${fname}.tif|grep Computed|cut -d= -f2 | awk -F, \'{print $1,$2}\')
# echo $fname $valNX > ${dirOut}/${datSet}/${year}/QC_${year}_${mon}.dat
# nfiles=$(find ${dirDatSet}/${datSet}/${var}_acc/${year}/tiles20d -type f | wc -l)
# echo ${dirDatSet}/${datSet}/${var}_acc/${year}/tiles20d ${nfiles} | tee -a  ${dirOut}/QC_dynam_Summ.dat
# for accF in $(ls ${dirDatSet}/${datSet}/${var}_acc/${year}/tiles20d/${var}_${year}_${mon}*.tif)
# do
#     fname=${basename -s .tif $accF}
#     valNX=$(gdalinfo -mm ${accF}|grep Computed|cut -d= -f2 | awk -F, \'{print $1,$2}\')
#     echo $fname $valNX >> ${dirOut}/${datSet}/${var}/${year}/QC_${year}_{mon}.dat
# done
# ' _

#################
# GRAND dataSet #
#################

# yrLst=($(seq 1958 2017))

# SetNam=GRAND

# if [ -d ${dirOut}/${SetNam} ]; then
#     rm -rf ${dirOut}/${SetNam}
# fi

# mkdir ${dirOut}/${SetNam}

# for year in ${yrLst[@]}
# do
# #   mkdir ${dirOut}/${SetNam}/${year}
#     echo ${SetNam} $year
# done  | xargs -n 2 -P 70 bash -c $'
# datSet=$1
# year=$2
# nfiles=$(find ${dirDatSet}/${datSet}/${year}_acc/tiles20d -type f | wc -l)
# echo ${dirDatSet}/${datSet}/${year}_acc/tiles20d ${nfiles} | tee -a  ${dirOut}/QC_dynam_Summ.dat
# ' _

#############
# static    #
#############

# echo "static var check" > ${dirOut}/QC_stat_Summ.dat

# setLst=(SOILGRIDS GRWL)

# for SetNam in ${setLst[@]}
# do
# # if [ -d ${dirOut}/${SetNam} ]; then
# #     rm -rf ${dirOut}/${SetNam}
# # fi

# # mkdir ${dirOut}/${SetNam}

# ls -d ${dirDatSet}/${SetNam}/*_acc/tiles20d/  | xargs -n 1 -P 70 bash -c $'
# datPath=$1
# nfiles=$(find $datPath -type f | wc -l)
# echo ${datPath} ${nfiles} | tee -a  ${dirOut}/QC_stat_Summ.dat
# ' _
# done

#########################
# Tif value range check #
#########################

#################
# TERRA dataSet #
#################

yrLst=($(seq 1958 2019))
monLst=($(seq -f "%02g" 01 12))

SetNam=TERRA
varLst=(tmin)

# if [ -d ${dirOut}/${SetNam} ]; then
#     rm -rf ${dirOut}/${SetNam}
# fi

# mkdir ${dirOut}/${SetNam}

# for var in ${varLst[@]}
# do
#     mkdir ${dirOut}/${SetNam}/${var}
#     for year in ${yrLst[@]}
#     do
# 	mkdir ${dirOut}/${SetNam}/${var}/${year}
# 	for mon in ${monLst[@]}
# 	do
#             echo ${SetNam} $var $year $mon
# 	done
#     done
# done  | xargs -n 4 -P 70 bash -c $'
# datSet=$1
# var=$2
# year=$3
# mon=$4
# #echo $var $year $mon
# fname=${var}_${year}_${mon}
# valMNX=$(gdalinfo -mm ${dirDatSet}/${datSet}/${var}/${fname}.tif|grep Computed|cut -d= -f2 | awk -F, \'{print $1,$2}\')
# echo $fname $valMNX | tee ${dirOut}/${datSet}/${var}/${year}/QC_range_${year}_${mon}.dat
# for accF in $(ls ${dirDatSet}/${datSet}/${var}_acc/${year}/tiles20d/${var}_${year}_${mon}*.tif)
# do
#     fname=$(basename -s .tif $accF)
#     valMNX=$(gdalinfo -mm ${accF}|grep Computed|cut -d= -f2 | awk -F, \'{print $1,$2}\')
#     echo $fname $valMNX | tee -a ${dirOut}/${datSet}/${var}/${year}/QC_range_${year}_${mon}.dat
# done
# ' _


#################################################
# comparison between pre_acc vs post_acc values #
#################################################

if [ -f ${dirOut}/${SetNam}/QC_range_${SetNam}.dat ]; then
    rm -f ${dirOut}/${SetNam}/QC_range_${SetNam}.dat
fi     

touch ${dirOut}/${SetNam}/QC_range_${SetNam}.dat

for var in ${varLst[@]}
do
    for year in ${yrLst[@]}
    do
	for mon in ${monLst[@]}
	do
            echo ${SetNam} $var $year $mon
	done
    done
done  | xargs -n 4 -P 70 bash -c $'
datSet=$1
var=$2
year=$3
mon=$4
echo $var $year $mon
awk -f range_comp.awk ${dirOut}/${datSet}/${var}/${year}/QC_range_${year}_${mon}.dat >>  ${dirOut}/${datSet}/QC_range_${datSet}.dat
' _


sort ${dirOut}/${SetNam}/QC_range_${SetNam}.dat > ${dirOut}/${SetNam}/QC_range_${SetNam}_sort.dat
