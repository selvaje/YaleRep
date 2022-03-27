#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7c.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7c.sh.%J.err
#SBATCH --mem-per-cpu=45000

#### sbatch /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7c.sh 

source ~/bin/gdal
source ~/bin/grass 

INDIR=/project/fas/sbsc/hydro/dataproces/MERIT_HYDRO 
RAM=/dev/shm



cd $INDIR/test 
rm -rf  $INDIR/test/grassdb/loc_wgs84
grass76 -text -c dem_wgs84.tif   -e  $INDIR/test/grassdb/loc_wgs84 
cp $INDIR/test/dem_wgs84.tif $RAM/dem.tif
cp $INDIR/test/dep_wgs84.tif $RAM/dep.tif
cp $INDIR/test/accumulation_fillnodata_wgs84_msk.tif  $RAM/accumulation.tif 

grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external input=$RAM/dem.tif  output=dem --overwrite 
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external input=$RAM/dep.tif  output=dep --overwrite 
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.external input=$RAM/accumulation.tif  output=accumulation --overwrite 
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.info  dem
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.info  dep
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec r.info  accumulation


# grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.watershed -b  elevation=dem  depression=dep accumulation=accumulation drainage=direction  memory=40000 --o 
# grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r accumulation
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.stream.extract elevation=dem  accumulation=accumulation  depression=dep  threshold=10  direction=direction stream_raster=stream  memory=40000 --o --verbose  ;  
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r stream
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r direction
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  /gpfs/loomis/home.grace/sbsc/ga254/.grass7/addons/bin/r.stream.basins  -l stream_rast=stream  direction=direction  basins=lbasin  memory=40000 --o --verbose  
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.colors -r lbasin

grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=stream       output=$INDIR/test/stream_warp.tif 
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=lbasin       output=$INDIR/test/lbasin_warp.tif  
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction    output=$INDIR/test/direction_warp.tif       
grass76 $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff nodata=-9999    input=accumulation output=$INDIR/test/accumulation.tif       

rm $RAM/*.tif



  
