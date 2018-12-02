#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_tmax-tmin_climat.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_tmax-tmin_climat.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget_tmax-tmin_climat.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc01_wget_tmax-tmin_climat.sh

for VAR in tmax tmin  ; do 
cd /project/fas/sbsc/ga254/dataproces/CHELSA/${VAR}_clim
export VAR
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

wget   https://www.wsl.ch/lud/chelsa/data/climatologies/temp/integer/${VAR}/CHELSA_${VAR}10_${MONTH}_land.7z
7za e  CHELSA_${VAR}10_${MONTH}_land.7z

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 CHELSA_${VAR}10_${M}_1979-2013_V1.2_land.tif  CHELSA_${VAR}_${M}_V1.2.tif 
gdal_edit.py  -a_ullr -180 84 180 -90   CHELSA_${VAR}_${M}_V1.2.tif 
rm    CHELSA_${VAR}10_${M}_1979-2013_V1.2_land.tif   CHELSA_${VAR}10_${MONTH}_land.7z

' _

done


