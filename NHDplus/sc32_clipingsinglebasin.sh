#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4  -N 1
#SBATCH -t 4:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc32_clipingsinglebasin.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc32_clipingsinglebasin.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc32_clipingsinglebasin.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc32_clipingsinglebasin.sh

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus
export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

ls $DIR/tif_nasqan_wbd12_NAD83m/b????????_proximity.tif   | xargs -n 1 -P 4 bash -c  $' 
file=$1
filename=$( basename $file _proximity.tif   )
gdal_translate -projwin  $( getCorners4Gtranslate $file)  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/tif_streambasin_NAD83m/lbasin_NAD83m.tif    $DIR/tif_lbasin_NAD83m/${filename}_lbasin.tif 

IDMAX=$(pkstat  -hist -i   $DIR/tif_lbasin_NAD83m/${filename}_lbasin.tif   | grep -v " 0"  | sort -gr -k 2,2  | awk \'{ if (NR==1) print $1   }\' ) 

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $( echo $IDMAX - 0.5 | bc ) -max  $( echo $IDMAX  + 0.5 | bc )   -data 1 -nodata 0 -i    $DIR/tif_lbasin_NAD83m/${filename}_lbasin.tif   -o   $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1.tif  

rm -f  $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1_shp.*
gdal_polygonize.py  -f "ESRI Shapefile"  -mask $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1.tif      $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1.tif  $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1_shp.shp  


gdal_rasterize  -ot  Byte -a_nodata 0 -burn 1    -co COMPRESS=DEFLATE -co ZLEVEL=9 -tap -tr  90 90  $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1_shp.shp     $DIR/tif_lbasin_NAD83m/${filename}_lbasin0-1_shp.tif   
' _ 

