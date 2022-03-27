#!/bin/bash
#SBATCH -p day
#SBATCH -J sc01_wget_dissolve_country.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_rasterize.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_rasterize.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GADM/sc02_rasterize.sh

# country shapefile 

# from https://gadm.org/download_world.html

INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_shp
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_tif

# rasterize based on the GID_0 that is as number in ID_0 ; 256 country 

gdal_rasterize --config GDAL_CACHEMAX 8000 -te -180 -90 180 84  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -at -ot  UInt32 -a_srs EPSG:4326 -l  gadm36   -a  ID_0  -a_nodata 0 -tap -tr  0.008333333333333 0.008333333333333   $INDIR/gadm36.shp  $OUTDIR/gadm36_ID_0.tif 


paste -d " " <(ogrinfo -al -geom=NO    gadm36.shp | grep " ID_0" ) <(ogrinfo -al -geom=NO    gadm36.shp | grep " GID_0" ) <(ogrinfo -al -geom=NO    gadm36.shp | grep " NAME_0" ) |   awk  '{ print $4 , $8 , $12 , $13 , $14 , $15 , $16 , $17  }'  |   uniq | sort  -k 1,1 -g  | uniq >    $OUTDIR/gadm36_ID_GID_NAME.txt 
