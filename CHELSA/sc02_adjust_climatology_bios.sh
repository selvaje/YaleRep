#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 00:30:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_adjust_climatology_bios.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_adjust_climatology_bios.sh.%A_%a.err
#SBATCH --mem-per-cpu=8000M
#SBATCH --array=1-19
#SBATCH --job-name=sc02_adjust_climatology_bios.sh

source ~/bin/gdal3

####  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/CHELSA/sc02_adjust_climatology_bios.sh
# # Check here for more details: http://chelsa-climate.org/wp-admin/download-page/CHELSA_tech_specification.pdf

# # BIO 01 Annual mean temperature as the mean of the monthly temperatures (°C)
# # BIO 02 Mean diurnal air temperature range  (°C)
# # BIO 03 Isothermality (BIO2/BIO7 * 100)
# # BIO 04 Temperature Seasonality (standard deviation * 100)
# # BIO 05 Max Temperature of Warmest Month (°C)
# # BIO 06 Min Temperature of Coldest Month (°C)
# # BIO 07 Temperature Annual Range (BIO5 - BIO6) (°C)
# # BIO 08 Mean Temperature of Wettest Quarter (°C)
# # BIO 09 Mean Temperature of Driest Quarter (°C)
# # BIO 10 Mean Temperature of Warmest Quarter (°C)
# # BIO 11 Mean Temperature of Coldest Quarter (°C)
# # BIO 12 Annual Precipitation (mm)
# # BIO 13 Precipitation of Wettest Month (mm)
# # BIO 14 Precipitation of Driest Month (mm)
# # BIO 15 Precipitation Seasonality (Coefficient of Variation * 100)
# # BIO 16 Precipitation of Wettest Quarter (mm)
# # BIO 17 Precipitation of Driest Quarter (mm)
# # BIO 18 Precipitation of Warmest Quarter (mm)
# # BIO 19 Precipitation of Coldest Quarter (mm)

CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA    
file=$CHELSA/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_bio${SLURM_ARRAY_TASK_ID}_1981-2010_V.2.1.tif
filename=$(basename $file)


GDAL_CACHEMA=5000
## Fix properties, compress and repair
gdal_translate -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_nodata 65535   -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $file $CHELSA/climatologies/bio/$filename
