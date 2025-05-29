#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 2:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_tiles_setting.sh_%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_tiles_setting.sh_%J.err
#SBATCH --job-name=sc10_tiles_setting.sh
#SBATCH --mem=20G

ulimit -c 0

####      sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc10_tiles_setting.sh

source ~/bin/gdal3
source ~/bin/pktools

export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

rm -f  $SCMH/tiles_comp/tile_ID*.{shp,shx,prj,dbf,tif} 


## must be less then 2^63 -1   (2 147 483 647 cell) 

seq 1 59    | xargs -n 1 -P 4  bash -c $' 
ID=$1

rm -fr  $SCMH/tiles_comp/tile_ID$ID.{shp,shx,prj,dbf}
ogr2ogr  -overwrite  -f "ESRI Shapefile"  -where  "id  = \'$ID\' "  $SCMH/tiles_comp/tile_ID$ID.shp   $SCMH/tiles_comp/tilesComp.shp    >/dev/null 2>&1 

CT=$( ogrinfo -al   -where  " id  = \'$ID\' " $SCMH/tiles_comp/tilesComp.shp  | grep " Continent" | awk \'{  print $4 }\' )

GDAL_CACHEMAX=2000
gdal_rasterize --config GDAL_CACHEMAX 4000  -burn 255  -tr 0.00833333333333333333 0.00833333333333333333  -ot Byte   -a_srs EPSG:4326 -a_nodata 0   \
-te $(getCornersOgr4Gwarp  $SCMH/tiles_comp/tile_ID$ID.shp     | awk \'{ printf("%3.1f %3.1f %3.1f %3.1f\\n", $1  , $2 , $3  , $4  ) }\' ) \
-co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co TILED=YES    $SCMH/tiles_comp/tile_ID$ID.shp  $SCMH/tiles_comp/tile_${CT}_ID$ID.tif   >/dev/null 2>&1 
rm -fr  $SCMH/tiles_comp/tile_ID$ID.{shp,shx,prj,dbf}

echo tile_${CT}_ID$ID.tif $( gdalinfo $SCMH/tiles_comp/tile_${CT}_ID$ID.tif  | grep "Size is" | awk \'{ gsub(","," ") ;  print $3 , $4 , $3 * $4 * 100  , $3 * $4 * 100  / 1000000000 }\' ) 

' _    |   sort -gr -k 5,5 > $SCMH/tiles_comp/tileComp_size.txt 


##### compute memory requirement 
##                                                                                                                    with 5 it works for the stream/basin delineation  9 for the TERRA climate 
awk '{ print  int(substr($1,11,3))   ,   $1  , int(( $4/1000000 * 31 )) , int(( $4/1000000 * 31 ) +  ( $4/1000000 * 31 / 10 ) )  }'  $SCMH/tiles_comp/tileComp_size.txt  > $SCMH/tiles_comp/tileComp_size_memory_tmp.txt

awk '{ if ($4<5000) {print $1, $2, $3, 5000} else { print $1, $2, $3, $4  }  }'  $SCMH/tiles_comp/tileComp_size_memory_tmp.txt >    $SCMH/tiles_comp/tileComp_size_memory.txt 

rm -f  $SCMH/tiles_comp/tiles_comp_shp.{shp,shx,prj,dbf}
gdaltindex  $SCMH/tiles_comp/tiles_comp_shp.shp $SCMH/tiles_comp/tile_??_ID*.tif 



###### continental mask 
gdalbuildvrt SA_msk.ovr  SA??_msk.tif   SA?_msk.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 SA_msk.ovr SA_msk.tif 

gdalbuildvrt NA_msk.ovr  NA??_msk.tif   NA?_msk.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 NA_msk.ovr NA_msk.tif 

gdalbuildvrt AF_msk.ovr  AF??_msk.tif   AF?_msk.tif 
gdal_translate  -co COMPREFF=DEFLATE -co ZLEVEL=9 AF_msk.ovr AF_msk.tif 
