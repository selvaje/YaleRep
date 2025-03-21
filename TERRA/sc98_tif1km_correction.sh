#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours  
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc98_tif1km_correction.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc98_tif1km_correction.sh.%J.err
#SBATCH --job-name sc98_tif1km_correction.sh
#SBATCH --mem=20G

source ~/bin/gdal3

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/tmin_acc/1992 
GDAL_CACHEMAX=15000
gdal_translate -a_nodata -9999 -ot Int16 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.0083333333333333333333 0.0083333333333333333333 tmin_1992_06.vrt tmin_1992_06_10p.tif 

gdalinfo -mm tmin_1992_06_10p.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }'  >  tmin_1992_06_10p.mm 


exit 
