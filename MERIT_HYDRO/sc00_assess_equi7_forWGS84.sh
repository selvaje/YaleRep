#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7_forWGS84.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7_forWGS84.sh.%J.err
#SBATCH --mem-per-cpu=45000

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7_forWGS84.sh 

source ~/bin/gdal
source ~/bin/grass 
source ~/bin/pktools

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO 
RAM=/dev/shm

cd $INDIR/test 

rm -rf  $INDIR/test/grassdb/loc_wgs84
grass76 -f -text -c dem_inWGS84.tif   -e  $INDIR/test/grassdb/loc_wgs84 
cp $INDIR/test/dem_inWGS84.tif $RAM
cp $INDIR/test/dep_inWGS84.tif $RAM

cp /gpfs/gibbs/pi/hydro/hydro/dataproces/STREAM_SHP/norway/OSM_20Jan_WGS84/norway_gis_osm_waterways_free_1.tif  $RAM 

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external   input=$RAM/norway_gis_osm_waterways_free_1.tif   output=burn   --overwrite 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external   input=$RAM/dem_inWGS84.tif  output=dem_WGS84   --overwrite 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external   input=$RAM/dep_inWGS84.tif  output=dep_WGS84   --overwrite 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.info  dem_WGS84
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.info  dep_WGS84

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.cell.area  output=cellarea  units=km2 --o
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r cellarea

# grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff  input=cellarea output=$INDIR/test/cellarea_fromWGS84.tif

######                                                           the direction is re-calculate in r.watershed and in r.stream.extract 

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.mapcalc " dem_burn  =  if ( isnull(burn),   dem_WGS84 , dem_WGS84 -  ( burn + 21 )   ) " 

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.watershed -b  elevation=dem_burn  depression=dep_WGS84   accumulation=accumulation flow=cellarea  drainage=direction  memory=40000 --o 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r direction 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction  output=$INDIR/test/direction_ws_fromWGS84.tif  
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r accumulation
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff  input=accumulation output=$INDIR/test/accumulation_fromWGS84.tif   

# accumulation done wit cell area produce an accumulation with 0 in sea area 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.mapcalc " accumulation_null = if (  isnull(dem_burn), null(), accumulation  ) " 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r accumulation_null
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff  input=accumulation_null output=$INDIR/test/accumulation_null_fromWGS84.tif   

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.stream.extract elevation=dem_burn  accumulation=accumulation_null  depression=dep_WGS84  threshold=0.05  direction=direction stream_raster=stream  stream_vector=stream_v  memory=40000 --o --verbose 
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r stream
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r direction
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  /gpfs/loomis/home.grace/sbsc/ga254/.grass7/addons/bin/r.stream.basins  -l stream_rast=stream  direction=direction  basins=lbasin  memory=40000 --o --verbose  
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r lbasin

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0  input=stream   output=$INDIR/test/stream_fromWGS84.tif 

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0  input=lbasin   output=$INDIR/test/lbasin_fromWGS84.tif  
grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction  output=$INDIR/test/direction_ex_fromWGS84.tif


pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -min -99999999 -max 99999999 -i $INDIR/test/accumulation_null_fromWGS84.tif -o  $INDIR/test/accumulation_null_bin_fromWGS84.tif 
pksetmask -m  $INDIR/test/accumulation_null_bin_fromWGS84.tif  -msknodata 0 -nodata -999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -i  $INDIR/test/accumulation_null_fromWGS84.tif -o  $INDIR/test/accumulation_nodataset_fromWGS84.tif   

# cropping 
for file in stream_fromWGS84.tif lbasin_fromWGS84.tif direction_ex_fromWGS84.tif  direction_ws_fromWGS84.tif  accumulation_fromWGS84.tif accumulation_nodataset_fromWGS84.tif  dem_inWGS84.tif dep_inWGS84.tif ; do 
filename=$( basename $file .tif )
gdal_translate --config GDAL_CACHEMAX 30000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -projwin 4 70 20 57 $INDIR/test/$file $INDIR/test/${filename}_c.tif 
done 

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  v.out.ogr  --overwrite format=ESRI_Shapefile  type=line input=stream_v       output=$INDIR/test/stream_inWGS84.shp

rm  $RAM/dem_inWGS84.tif  $RAM/dep_inWGS84.tif



 
