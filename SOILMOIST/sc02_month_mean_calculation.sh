#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_month_mean_calculation.sh.%A.%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_month_mean_calculation.sh.%A.%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_month_mean_calculation.sh
#SBATCH --array=1-34

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/SOILMOIST/sc02_month_mean_calculation.sh

# SLURM_ARRAY_TASK_ID=5
export YEAR=$(expr $SLURM_ARRAY_TASK_ID + 1983 ) # start from 1984 
export DIR=/project/fas/sbsc/ga254/dataproces/SOILMOIST

echo 01 02 03 04 05 06 07 08 09 10 11 12  | xargs -n 1 -P 4 bash -c $'
MM=$1

if [ $MM = '01'  ] ; then  MMbef=12 ; MMaft=02 ; YEARbef=$(expr $YEAR - 1 )  ; YEARaft=$YEAR ; fi 
if [ $MM = '02'  ] ; then  MMbef=01 ; MMaft=03 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '03'  ] ; then  MMbef=02 ; MMaft=04 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '04'  ] ; then  MMbef=03 ; MMaft=05 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '05'  ] ; then  MMbef=04 ; MMaft=06 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '06'  ] ; then  MMbef=05 ; MMaft=07 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '07'  ] ; then  MMbef=06 ; MMaft=08 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '08'  ] ; then  MMbef=07 ; MMaft=09 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '09'  ] ; then  MMbef=08 ; MMaft=10 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '10'  ] ; then  MMbef=09 ; MMaft=11 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '11'  ] ; then  MMbef=10 ; MMaft=12 ; YEARbef=$YEAR               ; YEARaft=$YEAR ; fi 
if [ $MM = '12'  ] ; then  MMbef=11 ; MMaft=01 ; YEARbef=$YEAR               ; YEARaft=$(expr $YEAR + 1 ) ; fi 


gdalbuildvrt -separate -sd 2 -overwrite   $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.2.vrt   $( ls -CF   $DIR/$YEARbef/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEARbef}${MMbef}*-fv04.2.nc | tail -5 )   $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}*-fv04.2.nc  $( ls -CF   $DIR/$YEARaft/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEARaft}${MMaft}*-fv04.2.nc | head  -5 ) 
pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -f median --nodata -9999 -i $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.2.vrt -o $DIR/${YEAR}_mean/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.2.tif 

rm $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.2.vrt

' _ 
