#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_rasterFilter.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_rasterFilter.sh.%A_%a.err
#SBATCH --job-name=sc04_rasterFilter.sh
#SBATCH --mem=30G
#SBATCH --array=1-8

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc04_rasterFilter.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  
source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export file=$(ls $MERIT/flow_tiles/flow_{h04v02,h06v02,h08v02,h10v02,h04v04,h06v04,h08v04,h10v04}_pos.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _pos.tif )
export tile=$(echo $filename | sed 's/flow_//g')



GDAL_CACHEMAX=20000
#filtering 
# pkfilter -of GTiff  -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -f max -dy 3 -dy 3 -i $NHDP/raster_90m/NHDP_${filename}_90m.tif  -o $NHDP/raster_filter/NHDP_${filename}_90m.tif

# pkfilter -of GTiff  -nodata -9999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -f max -dy 3 -dy 3 -i $file -o $NHDP/raster_filter/HYDRO_${filename}_90m.tif 

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -projwin $(getCorners4Gtranslate $file) /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/upa/all_tif_dis.vrt  $NHDP/raster_90m/MERIT_${filename}_90m.tif 
# pkfilter -of GTiff  -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -f max -dy 3 -dy 3 -i $NHDP/raster_90m/MERIT_${filename}_90m.tif  -o $NHDP/raster_filter/MERIT_${filename}_90m.tif 
# rm -f $NHDP/raster_filter/MERIT_${filename}_90m.vrt

## mskstr
pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_uniq_$tile.tif -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $NHDP/raster_90m/MERIT_${filename}_90m.tif -o $NHDP/raster_mskstr/MERIT_${filename}_90m_mskstr.tif

pksetmask -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_uniq_$tile.tif   -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $file                                      -o $NHDP/raster_mskstr/HYDRO_${filename}_90m_mskstr.tif

pksetmask -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_uniq_$tile.tif   -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $NHDP/raster_90m/NHDP_${filename}_90m.tif  -o $NHDP/raster_mskstr/NHDP_${filename}_90m_mskstr.tif
