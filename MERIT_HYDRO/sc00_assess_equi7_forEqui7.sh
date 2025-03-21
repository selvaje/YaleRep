#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7_forEqui7.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7_forEqui7.sh.%J.err
#SBATCH --mem-per-cpu=45000

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7_forEqui7.sh 

source ~/bin/gdal
source ~/bin/grass 
source ~/bin/pktools

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO 
RAM=/dev/shm

cd $INDIR/elv_equi7/EU

# gdalbuildvrt  elv.vrt EU_042_018.tif  EU_048_036.tif EU_042_024.tif  EU_054_018.tif EU_042_030.tif  EU_054_024.tif EU_048_018.tif  EU_054_030.tif EU_048_024.tif  EU_054_036.tif EU_048_030.tif EU_060_036.tif EU_060_030.tif EU_060_024.tif  EU_060_018.tif 
# gdal_translate  -co COMPRESS=DEFLATE   -co ZLEVEL=9  $INDIR/elv_equi7/EU/elv.vrt   $INDIR/test/dem.tif
# rm -r $INDIR/elv_equi7/EU/elv.vrt  

# cd $INDIR/dep_equi7/EU

# gdalbuildvrt  dep.vrt  EU_042_018.tif  EU_048_018.tif  EU_054_018.tif 
# gdal_translate  -co COMPRESS=DEFLATE   -co ZLEVEL=9  $INDIR/elv_equi7/EU/dep.vrt   $INDIR/test/dep.tif
# rm -r $INDIR/dep_equi7/EU/dep.vrt  

cd $INDIR/test 

rm -rf  $INDIR/test/grassdb/loc_equi7
grass76 -f -text -c dem_inEqui7.tif   -e  $INDIR/test/grassdb/loc_equi7 
cp $INDIR/test/dem_inEqui7.tif $RAM
cp $INDIR/test/dep_inEqui7.tif $RAM
cp $INDIR/test/cellarea_inEqui7.tif  $RAM


# gdal_translate -projwin $( getCorners4Gtranslate   $INDIR/test/dem_inEqui7.tif )  --config GDAL_CACHEMAX 10000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES /gpfs/gibbs/pi/hydro/ga254/dataproces/GEO_AREA/area_tif/equi7100m/all_tif.vrt  $INDIR/test/cellarea_inEqui7.tif 
# gdal_calc.py --NoDataValue=0  -A cellarea_inEqui7.tif --calc="( A / 1000000  )"   --outfile=cellarea_inEqui7_tmp.tif
# gdal_translate   --config GDAL_CACHEMAX 10000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES   $INDIR/test/cellarea_inEqui7_tmp.tif   $INDIR/test/cellarea_inEqui7.tif


cp /gpfs/gibbs/pi/hydro/hydro/dataproces/STREAM_SHP/norway/OSM_20Jan_EQUI7/norway_gis_osm_waterways_free_1.tif  $RAM/norway_gis_osm_waterways_free_1_e.tif
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.external  input=$RAM/norway_gis_osm_waterways_free_1_e.tif   output=burn   --overwrite 

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.external  input=$RAM/dem_inEqui7.tif  output=dem_Equi7  --overwrite
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.external  input=$RAM/dep_inEqui7.tif  output=dep_Equi7  --overwrite 
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.external  input=$RAM/cellarea_inEqui7.tif  output=cellarea  --overwrite 
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.info  dem_Equi7
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.info  dep_Equi7

######                                                                             the direction is re-calculate in r.watershed and in r.stream.extract 

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.mapcalc " dem_burn  =  if ( isnull(burn),   dem_Equi7 , dem_Equi7 -  ( burn + 21 )   ) "

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.watershed -b  elevation=dem_Equi7  depression=dep_Equi7 accumulation=accumulation flow=cellarea  drainage=direction  memory=40000 --o 
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r direction 
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16 format=GTiff nodata=-10  input=direction  output=$INDIR/test/direction_ws_inEqui7.tif 

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r accumulation
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m -f   createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff    input=accumulation output=$INDIR/test/accumulation_inEqui7.tif

# accumulation done wit cell area produce an accumulation with 0 in sea area                                                        
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.mapcalc " accumulation_null =   if (  isnull(dem_burn), null(), accumulation  ) "  --o  
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.info  accumulation_null
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r accumulation_null
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m -f   createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff    input=accumulation_null output=$INDIR/test/accumulation_null_inEqui7.tif

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.info  accumulation_null
                                                                                                                              # 5 x 5 100m cell  
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.stream.extract elevation=dem_Equi7 accumulation=accumulation_null depression=dep_Equi7 threshold=0.05  direction=direction stream_raster=stream stream_vector=stream_v   memory=40000 --o --verbose
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec r.info  stream
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r stream
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r direction
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  /gpfs/loomis/home.grace/sbsc/ga254/.grass7/addons/bin/r.stream.basins  -l stream_rast=stream  direction=direction  basins=lbasin  memory=40000 --o --verbose  
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.colors -r lbasin

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=stream       output=$INDIR/test/stream_inEqui7.tif 
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=lbasin       output=$INDIR/test/lbasin_inEqui7.tif   
grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction    output=$INDIR/test/direction_ex_inEqui7.tif
                                                                                                                  ########## -30983990      28830844
pkgetmask  -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES   -min  -99999999 -max 99999999 -i $INDIR/test/accumulation_null_inEqui7.tif  -o $INDIR/test/accumulation_null_bin_inEqui7.tif 

pksetmask   -m  $INDIR/test/accumulation_null_bin_inEqui7.tif  -msknodata 0 -nodata -999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -i  $INDIR/test/accumulation_null_inEqui7.tif   -o  $INDIR/test/accumulation_nodataset_inEqui7.tif 

rm $RAM/dem_inEqui7.tif   $RAM/dep_inEqui7.tif   $INDIR/test/accumulation_null_inEqui7.tif   $INDIR/test/accumulation_null_bin_inEqui7.tif  $INDIR/test/accumulation_null_inEqui7.tif $RAM/norway_gis_osm_waterways_free_1_e.tif

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  v.out.ogr  --overwrite format=ESRI_Shapefile  input=stream_v  type=line      output=$INDIR/test/stream_inEqui7.shp 


 
