#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7a.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7a.sh.%J.err
#SBATCH --mem-per-cpu=45000

#### sbatch /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7a.sh 

source ~/bin/gdal
source ~/bin/grass 
source ~/bin/pktools

INDIR=/project/fas/sbsc/hydro/dataproces/MERIT_HYDRO 
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

# rm -rf  $INDIR/test/grassdb/location
# grass76 -text -c dem.tif   -e  $INDIR/test/grassdb/location 
# cp $INDIR/test/dem.tif $RAM/dem.tif
# cp $INDIR/test/dep.tif $RAM/dep.tif
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec r.external input=$RAM/dem.tif  output=dem --overwrite 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec r.external input=$RAM/dep.tif  output=dep --overwrite 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec r.info  dem
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec r.info  dep

# ##                                                                                    the direction is re-calculate in r.watershed and in r.stream.extract 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.watershed -b  elevation=dem  depression=dep accumulation=accumulation drainage=direction  memory=40000 --o 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.colors -r accumulation
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.colors -r direction 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction    output=$INDIR/test/direction_ws.tif       

# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.stream.extract elevation=dem  accumulation=accumulation  depression=dep  threshold=10  direction=direction stream_raster=stream  memory=40000 --o --verbose  ;  
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.colors -r stream
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.colors -r direction
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  /gpfs/loomis/home.grace/sbsc/ga254/.grass7/addons/bin/r.stream.basins  -l stream_rast=stream  direction=direction  basins=lbasin  memory=40000 --o --verbose  
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.colors -r lbasin

# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=stream       output=$INDIR/test/stream.tif 
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=UInt32 format=GTiff nodata=0    input=lbasin       output=$INDIR/test/lbasin.tif  
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Int16  format=GTiff nodata=-10  input=direction    output=$INDIR/test/direction_ex.tif       
# grass76 $INDIR/test/grassdb/location/PERMANENT --exec  r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,TILED=YES" type=Float32 format=GTiff    input=accumulation output=$INDIR/test/accumulation.tif       

                                                                                                                  ########## -30983990      28830844
pkgetmask  -ot Byte --config GDAL_CACHEMAX 3000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES   -min  -99999999 -max 99999999 -i $INDIR/test/accumulation.tif  -o $INDIR/test/accumulation_bin.tif 

pksetmask --config GDAL_CACHEMAX 3000   -m  $INDIR/test/accumulation_bin.tif  -msknodata 0 -nodata -999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -i  $INDIR/test/accumulation.tif   -o  $INDIR/test/accumulation_nodataset.tif

pkfillnodata --config GDAL_CACHEMAX 3000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -m  $INDIR/test/accumulation_bin.tif  -d  4 -i $INDIR/test/accumulation_nodataset.tif -o $INDIR/test/accumulation_fillnodata.tif


rm $RAM/*.tif



 
