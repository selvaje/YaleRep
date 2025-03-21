#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_soilmoist_meanMonthlyAllTS.sh.%A.%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_soilmoist_meanMonthlyAllTS.sh.%A.%a.err
#SBATCH --job-name=sc03_soilmoist_meanMonthlyAllTS.sh
#SBATCH --mem-per-cpu=15000M

# copy to grace
#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/SOILMOIST/sc03_soilmoist_meanMonthlyAllTS.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILMOIST


# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILMOIST/sc03_soilmoist_meanMonthlyAllTS.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILMOIST
# mkdir $DIR/ALLmeanTS
export OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILMOIST/ALLmeanTS

echo 01 02 03 04 05 06 07 08 09 10 11 12  | xargs -n 1 -P 12 bash -c $'
MM=$1

gdalbuildvrt -separate -sd 2 -overwrite  -a_srs EPSG:4326  $OUT/${MM}_ALLTS.vrt  $( for YEAR in {1979..2019}; do ls $DIR/$YEAR/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED-${YEAR}${MM}*-fv04.7.nc; done )

pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -f mean --nodata -9999 -i $OUT/${MM}_ALLTS.vrt -o $OUT/${MM}_ALLTSmean.tif

rm $OUT/${MM}_ALLTS.vrt
' _
