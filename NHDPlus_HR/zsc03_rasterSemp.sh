#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_rasterSemp.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_rasterSemp.sh.%A_%a.err
#SBATCH --job-name=sc03_rasterSemp.sh
#SBATCH --mem=30G
#SBATCH --array=1-8

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc03_rasterSemp.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  

source ~/bin/gdal3
source ~/bin/pktools 

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export file=$(ls $MERIT/flow_tiles/flow_{h04v02,h06v02,h08v02,h10v02,h04v04,h06v04,h08v04,h10v04}_pos.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _pos.tif )

### gdalbuildvrt -srcnodata -9999   -vrtnodata -9999 -overwrite $NHDP/raster/all_tif.vrt $NHDP/raster/*.tif 

GDAL_CACHEMAX=20000
rm -f $NHDP/raster_1km/NHDP_${filename}_1km.tif 
gdalwarp -overwrite   -wo NUM_THREADS=2 -multi -te $(getCorners4Gwarp $file) -srcnodata -9999  -dstnodata -9999 -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r max -t_srs EPSG:4326 \
-tr 0.008333333333333333  0.008333333333333333  $NHDP/raster/all_tif.vrt  $NHDP/raster_1km/NHDP_${filename}_1km.tif

rm -f $NHDP/raster_90m/NHDP_${filename}_90m.tif 
gdalwarp -overwrite   -wo NUM_THREADS=2 -multi -te $(getCorners4Gwarp $file) -srcnodata -9999  -dstnodata -9999 -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r max -t_srs EPSG:4326 \
-tr 0.0008333333333333333 0.0008333333333333333  $NHDP/raster/all_tif.vrt  $NHDP/raster_90m/NHDP_${filename}_90m.tif







