#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_reproject_stream_basin.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_reproject_stream_basin.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_reproject_stream_basin.sh
#SBATCH --mem=10000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc31_reproject_stream_basin.sh

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus
export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

echo stream lbasin | xargs -n 1 -P 2 bash -c $'  
VAR=$1

gdalbuildvrt -overwrite  -te $( getCorners4Gwarp /project/fas/sbsc/ga254/dataproces/NHDplus/tif_merge/NHDplus_90m.tif )   $DIR/tif_streambasin/${VAR}.vrt  $MERIT/${VAR}_tiles_final20d/{${VAR}_h04v02.tif,${VAR}_h06v02.tif,${VAR}_h08v02.tif,${VAR}_h10v02.tif,${VAR}_h04v04.tif,${VAR}_h06v04.tif,${VAR}_h08v04.tif,${VAR}_h10v04.tif} 

gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/tif_streambasin/${VAR}.vrt   $DIR/tif_streambasin/${VAR}.tif
gdalwarp  -multi -wo   NUM_THREADS=4 -wm 4000  -overwrite -t_srs "+proj=eqdc +lat_1=28 +lat_2=45 +lon_0=-96  +ellps=GRS80 +datum=NAD83 +units=m no_defs" -co COMPRESS=DEFLATE -co ZLEVEL=9  -co  BIGTIFF=YES -tr 90 90   $DIR/tif_streambasin/${VAR}.tif    $DIR/tif_streambasin_NAD83m/${VAR}_NAD83m_tmp.tif
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/tif_streambasin_NAD83m/${VAR}_NAD83m_tmp.tif   $DIR/tif_streambasin_NAD83m/${VAR}_NAD83m.tif

rm   $DIR/tif_streambasin_NAD83m/${VAR}_NAD83m_tmp.tif

' _ 






