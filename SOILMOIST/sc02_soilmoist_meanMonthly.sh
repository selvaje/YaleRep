#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_soilmoist_meanMonthly.sh.%A.%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_soilmoist_meanMonthly.sh.%A.%a.err
#SBATCH --job-name=sc02_soilmoist_meanMonthly.sh
#SBATCH --array=1-41

# copy to grace
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/SOILMOIST/sc02_soilmoist_meanMonthly.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILMOIST


# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILMOIST/sc02_soilmoist_meanMonthly.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export YEAR=$(expr $SLURM_ARRAY_TASK_ID + 1978 ) # start from 1979 because 1978 has no coverage for all months
export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILMOIST

mkdir $DIR/${YEAR}_mean

echo 01 02 03 04 05 06 07 08 09 10 11 12  | xargs -n 1 -P 12 bash -c $'
MM=$1

gdalbuildvrt -separate -sd 2 -overwrite  -a_srs EPSG:4326 $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.7.vrt  $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}*-fv04.7.nc

pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -f mean --nodata -9999 -i $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.7.vrt -o $DIR/${YEAR}_mean/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.7.tif

rm $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}-fv04.7.vrt
' _


exit
