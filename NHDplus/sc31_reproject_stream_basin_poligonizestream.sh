#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_reproject_stream_basin.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_reproject_stream_basin.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_reproject_stream_basin.sh
#SBATCH --mem=40000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc31_reproject_stream_basin_poligonizestream.sh

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus
export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT


gdalbuildvrt -overwrite  -te $( getCorners4Gwarp /project/fas/sbsc/ga254/dataproces/NHDplus/tif_merge/NHDplus_90m.tif )   $DIR/tif_streambasin/stream.vrt  $MERIT/stream_tiles_final20d/{stream_h04v02.tif,stream_h06v02.tif,stream_h08v02.tif,stream_h10v02.tif,stream_h04v04.tif,stream_h06v04.tif,stream_h08v04.tif,stream_h10v04.tif} 

# gdalbuildvrt -overwrite  -te -73 40 76 44    $DIR/tif_streambasin/stream.vrt  $MERIT/stream_tiles_final20d/{stream_h04v02.tif,stream_h06v02.tif,stream_h08v02.tif,stream_h10v02.tif,stream_h04v04.tif,stream_h06v04.tif,stream_h08v04.tif,stream_h10v04.tif} 

# gdal_translate  -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/tif_streambasin/stream.vrt    $DIR/tif_streambasin/stream_crop.tif

rm -rf /dev/shm/loc_4poly
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh /dev/shm  loc_4poly $DIR/tif_streambasin/stream_crop.tif  r.in.gdal 

r.thin input=stream_crop output=stream_thin  --o
r.to.vect -s -t   input=stream_thin   output=stream type=line --o
rm -f   $DIR/tif_streambasin/stream_shp.*
v.out.ogr   input=stream   type=line  out_type=line  format=ESRI_Shapefile output=$DIR/tif_streambasin/stream_shp.shp  --o 

rm -f $DIR/tif_streambasin/stream_shpNAD83.*

ogr2ogr  -s_srs EPSG:4326    -t_srs "+proj=eqdc +lat_1=28 +lat_2=45 +lon_0=-96  +ellps=GRS80 +datum=NAD83 +units=m no_defs"  $DIR/tif_streambasin/stream_shpNAD83.shp  $DIR/tif_streambasin/stream_shp.shp
gdal_rasterize -ot Byte   -a_nodata 0 -burn 1   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co  BIGTIFF=YES   -tr 90 90   $DIR/tif_streambasin/stream_shpNAD83.shp  $DIR/tif_streambasin/stream_shpNAD83_big.tif
gdal_translate -ot Byte  -co COMPRESS=DEFLATE  -co ZLEVEL=9  $DIR/tif_streambasin/stream_shpNAD83_big.tif   $DIR/tif_streambasin/stream_shpNAD83.tif
rm -f  $DIR/tif_streambasin/stream_shpNAD83_big.tif







