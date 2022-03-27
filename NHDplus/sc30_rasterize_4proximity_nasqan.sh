#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_rasterize_4proximity_nasqan.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_rasterize_4proximity_nasqan.sh.%J.out
#SBATCH --mail-user=email
#SBATCH --job-name=sc30_rasterize_4proximity_nasqan.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc30_rasterize_4proximity_nasqan.sh

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus

echo rasteri the full network 
# rm -f $DIR/tmp/select.*  $DIR/tif/*.tif  

# riga fatta sul portatile perche sqlite non e supportato 
# scp  -r     ga254@grace1.hpc.yale.edu:/project/fas/sbsc/ga254/dataproces/NHDplus/ds641_nasqan_wbd12/nasqan_basins  .
# mkdir ds641_nasqan_wbd12_NAD83m 
# 
# for file in nasqan_basins/b*.shp ; do filename=$(basename $file .shp  )  ; ogr2ogr -t_srs "+proj=eqdc +lat_1=28 +lat_2=45 +lon_0=-96      +datum=NAD83 +units=m +no_defs" -dialect sqlite -f "ESRI Shapefile" -sql "select ST_ExteriorRing(geometry) as geometry from $filename" ds641_nasqan_wbd12_NAD83m/$filename.shp  $file ; done
#  scp -r ds641_nasqan_wbd12_NAD83m/      ga254@grace1.hpc.yale.edu:/project/fas/sbsc/ga254/dataproces/NHDplus/


ls $DIR/ds641_nasqan_wbd12_NAD83m/b*.shp  | xargs -n 1 -P 4 bash -c  $'
file=$1
filename=$(basename $file .shp  )

# -te xmin ymin xmax ymax
xmin=$(ogrinfo -al -so  $file  | grep Extent | awk \'{ gsub("[(,)]"," " ) ; print $2 - 10000  }\' )
ymin=$(ogrinfo -al -so  $file  | grep Extent | awk \'{ gsub("[(,)]"," " ) ; print $3 - 10000  }\' )
xmax=$(ogrinfo -al -so  $file  | grep Extent | awk \'{ gsub("[(,)]"," " ) ; print $5 + 10000  }\' )
ymax=$(ogrinfo -al -so  $file  | grep Extent | awk \'{ gsub("[(,)]"," " ) ; print $6 + 10000  }\' )

rm -f $DIR/tif_nasqan_wbd12_NAD83m/${filename}_proximity.tif
gdal_rasterize  -te $xmin $ymin $xmax $ymax   -ot  Byte -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -tap -tr  90 90  -burn 1  $file    $DIR/tif_nasqan_wbd12_NAD83m/$filename.tif
gdal_proximity.py -of  GTiff   -ot  Int16  -distunits GEO  -values 1 -nodata 0  -maxdist 4000 $DIR/tif_nasqan_wbd12_NAD83m/${filename}.tif  $DIR/tif_nasqan_wbd12_NAD83m/${filename}_proximity.tif
' _


sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc32_clipingsinglebasin.sh



