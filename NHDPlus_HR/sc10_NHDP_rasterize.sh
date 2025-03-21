#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_NHDP_rasterize.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_NHDP_rasterize.sh.%A_%a.err
#SBATCH --job-name=sc10_NHDP_rasterize.sh
#SBATCH --mem=70G
#SBATCH --array=1-8

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc10_NHDP_rasterize.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  
source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export RAM=/dev/shm
export NHDP=/gpfs/loomis/project/sbsc/hydro/dataproces/NHDPlus_HR
export file=$(ls $MERIT/flow_tiles/flow_{h04v02,h06v02,h08v02,h10v02,h04v04,h06v04,h08v04,h10v04}_pos.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _pos.tif )
export tile=$(echo $filename | sed 's/flow_//g')

### cd /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/shp_flow
### rm NHDPLUS_NHDFlowline_VAA.vrt 
### ogrmerge.py -single  -progress -skipfailures -t_srs EPSG:4326 -s_srs EPSG:4326 -overwrite_ds -f VRT -o NHDPLUS_NHDFlowline_VAA.vrt NHDPLUS_*_NHDFlowline_VAA.shp

GDAL_CACHEMAX=60000

# stream rasterize 
# rm -fr $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream_$tile.tif 
# gdal_rasterize -te $(getCorners4Gwarp $file) -burn 1 -l merged -a_nodata 0 -ot Byte  -tr 0.0008333333333333333 0.0008333333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 $NHDP/shp_flow/NHDPLUS_NHDFlowline_VAA.vrt  $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream_$tile.tif 


rm -fr $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10m_$tile.tif 
gdal_rasterize -te $(getCorners4Gwarp $file) -burn 1 -l merged -a_nodata 0 -ot Byte  -tr 0.00008333333333333333 0.00008333333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 $NHDP/shp_flow/NHDPLUS_NHDFlowline_VAA.vrt  $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10m_$tile.tif 

pkfilter -ot UInt16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -dy 100 -dx 100 -d 100  -f sum  -i $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10m_$tile.tif  -o $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream1kmDensity_$tile.tif 

pkfilter -ot UInt16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -dy 1000 -dx 1000 -d 1000  -f sum  -i $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10m_$tile.tif  -o $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_$tile.tif 

exit 

# flow rasterize 
# NHDPLUS__1  flow value 
rm -fr $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif 
gdal_rasterize -co BIGTIFF=YES  -te $(getCorners4Gwarp  $file)  -a 'NHDPLUS__1'   -l merged  -a_nodata -9999  -ot Float32   -tr 0.00008333333333333333 0.00008333333333333333  -co COMPRESS=DEFLATE -co ZLEVEL=9 $NHDP/shp_flow/NHDPLUS_NHDFlowline_VAA.vrt  $RAM/NHDPLUS_NHDFlowline_flow_$tile.tif 

rm -f $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif 
gdalwarp -srcnodata  -9999 -dstnodata -9999999 -ot Float32 -r max -tr 0.0008333333333333333 0.0008333333333333333  -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/NHDPLUS_NHDFlowline_flow_$tile.tif    $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif 
rm -f $RAM/NHDPLUS_NHDFlowline_flow_$tile.tif  
gdalinfo -mm $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.mm




