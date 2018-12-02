#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_shape_to_grid.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_shape_to_grid.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_shape_to_grid.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRanD/sc02_shape_to_grid.sh

# 1984 2015 

export DIR=/project/fas/sbsc/ga254/dataproces/GRanD

seq   1984 2015   | xargs  -n 1 -P 1  bash -c $' 
export YEAR=$1

rm -f   $DIR/shp/GRanD_Version_1_1_YEAR/GRanD_dams_v1_1_$YEAR.*
ogr2ogr -sql "SELECT CAP_MCM  FROM  GRanD_dams_v1_1  WHERE ( YEAR  <= $YEAR ) " $DIR/shp/GRanD_Version_1_1_YEAR/GRanD_dams_v1_1_$YEAR.shp $DIR/shp/GRanD_Version_1_1/GRanD_dams_v1_1.shp

cat /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt |  xargs  -n 5 -P 8  bash -c $\' 

gdal_rasterize -te $2  $5 $4 $3 -ot  UInt32 -l GRanD_dams_v1_1_$YEAR  -a  CAP_MCM  -a_nodata 0 -tap -tr  0.0008333333333333 0.0008333333333333  -co COMPRESS=LZW -co ZLEVEL=9   $DIR/shp/GRanD_Version_1_1_YEAR/GRanD_dams_v1_1_$YEAR.shp    $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/GRanD_dams_${YEAR}_$1.tif   

if [ -f  $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/GRanD_dams_${YEAR}_$1.tif ] ; then 
    MAX=$(pkstat -max -i   $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/GRanD_dams_${YEAR}_$1.tif   | cut -d " " -f 2 )
if [ $MAX -eq 0  ] ; then  rm  $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/GRanD_dams_${YEAR}_$1.tif ; fi 
fi 

\' _

rm -f   $DIR/shp/GRanD_Version_1_1_YEAR/GRanD_dams_v1_1_$YEAR.*

gdalbuildvrt -overwrite   $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/all_tif_GRanD$YEAR.vrt   $DIR/GRanD_Version_1_1_YEAR_tif/$YEAR/GRanD_dams_${YEAR}_*.tif

' _

exit 

