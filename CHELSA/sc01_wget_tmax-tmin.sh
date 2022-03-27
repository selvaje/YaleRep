#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_tmax-tmin.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_tmax-tmin.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget_tmax-tmin.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc01_wget_tmax-tmin.sh


# for VAR in tmax tmin  ; do 
# cd /project/fas/sbsc/ga254/dataproces/CHELSA/$VAR
# export VAR
# for YEAR in $(seq 1979 2013) ; do
# export YEAR 
# echo  01 02 03 04 05 06 07 08 09 10 11 12 | xargs  -n 1 -P 12 bash -c $'
# MONTH=$1
# M=$(echo $MONTH | awk -v MONTH=$MONTH \'{ print int(MONTH) }\' )

# if [ $M -eq  1  ] ; then sleep 1 ; fi  
# if [ $M -eq  2  ] ; then sleep 30 ; fi  
# if [ $M -eq  3  ] ; then sleep 60 ; fi  
# if [ $M -eq  4  ] ; then sleep 90 ; fi  
# if [ $M -eq  5  ] ; then sleep 120 ; fi  
# if [ $M -eq  6  ] ; then sleep 150 ; fi  
# if [ $M -eq  7  ] ; then sleep 180 ; fi  
# if [ $M -eq  8  ] ; then sleep 210 ; fi  
# if [ $M -eq  9  ] ; then sleep 240 ; fi  
# if [ $M -eq 10  ] ; then sleep 270 ; fi  
# if [ $M -eq 11  ] ; then sleep 300 ; fi  
# if [ $M -eq 12  ] ; then sleep 330 ; fi  

# wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_${MONTH}.7z
# 7za e CHELSA_${VAR}_${YEAR}_${MONTH}.7z

# gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  CHELSA_${VAR}_${M}_${YEAR}_V1.2.sdat    CHELSA_${VAR}_${M}_${YEAR}_V1.2.tif 
# gdal_edit.py  -a_ullr -180 84 180 -90    CHELSA_${VAR}_${M}_${YEAR}_V1.2.tif 
# rm  CHELSA_${VAR}_${M}_${YEAR}_V1.2.sdat  CHELSA_${VAR}_${M}_${YEAR}_V1.2.sdat.aux.xml CHELSA_${VAR}_${M}_${YEAR}_V1.2.prj  CHELSA_${VAR}_${M}_${YEAR}_V1.2.sgrd CHELSA_${VAR}_${YEAR}_${MONTH}.7z 

# ' _

# done
# done 


for VAR in tmean  ; do 
cd /project/fas/sbsc/ga254/dataproces/CHELSA/$VAR
export VAR
for YEAR in $(seq 1979 2013) ; do
export YEAR 
echo  01 02 03 04 05 06 07 08 09 10 11 12 | xargs  -n 1 -P 12 bash -c $'
MONTH=$1
M=$(echo $MONTH | awk -v MONTH=$MONTH \'{ print int(MONTH) }\' )

if [ $M -eq  1  ] ; then sleep 1 ; fi  
if [ $M -eq  2  ] ; then sleep 30 ; fi  
if [ $M -eq  3  ] ; then sleep 60 ; fi  
if [ $M -eq  4  ] ; then sleep 90 ; fi  
if [ $M -eq  5  ] ; then sleep 120 ; fi  
if [ $M -eq  6  ] ; then sleep 150 ; fi  
if [ $M -eq  7  ] ; then sleep 180 ; fi  
if [ $M -eq  8  ] ; then sleep 210 ; fi  
if [ $M -eq  9  ] ; then sleep 240 ; fi  
if [ $M -eq 10  ] ; then sleep 270 ; fi  
if [ $M -eq 11  ] ; then sleep 300 ; fi  
if [ $M -eq 12  ] ; then sleep 330 ; fi  

wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_temp_${YEAR}_${MONTH}.7z
7za e CHELSA_temp_${YEAR}_${MONTH}.7z

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  CHELSA_temp_${M}_${YEAR}_V1.2.sdat    CHELSA_tmea_${M}_${YEAR}_V1.2.tif 
gdal_edit.py  -a_ullr -180 84 180 -90    CHELSA_tmea_${M}_${YEAR}_V1.2.tif 
rm  CHELSA_temp_${M}_${YEAR}_V1.2.sdat  CHELSA_temp_${M}_${YEAR}_V1.2.sdat.aux.xml CHELSA_temp_${M}_${YEAR}_V1.2.prj  CHELSA_temp_${M}_${YEAR}_V1.2.sgrd CHELSA_temp_${YEAR}_${MONTH}.7z 

' _

done
done 
