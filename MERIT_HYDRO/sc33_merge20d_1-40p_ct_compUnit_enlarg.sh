#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 36  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc33_merge20d_1-40p_ct_compUnit_enlarg.sh.%J.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc33_merge20d_1-40p_ct_compUnit_enlarg.sh.%J.err
#SBATCH --job-name=sc33_merge20d_1-40p_ct_compUnit_enlarg.sh
#SBATCH --mem=100G

####    sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc33_merge20d_1-40p_ct_compUnit_enlarg.sh


ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export CPU=$SLURM_CPUS_ON_NODE

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr

export GDAL_CACHEMAX=5000
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt    $SCMH/lbasin_compUnit_tiles_enlarg/bid*_msk.tif    $SCMH/lbasin_compUnit_large_enlarg/bid???_msk.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt $SCMH/lbasin_compUnit_tiles_enlarg_ct/bid*_msk.tif $SCMH/lbasin_compUnit_large_enlarg_ct/bid???_msk.tif

ls $SCMH/lbasin_tiles_final20d_1p/lbasin_h??v??.tif | xargs -n 1 -P $CPU  bash -c $' 
GDAL_CACHEMAX=5000
file=$( basename $1 .tif)

gdal_translate -a_nodata 0 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $1) -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -tr 0.0041666666666666666 0.0041666666666666666 -r mod   -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt $RAM/${file}_5p.tif 

echo filter ct

gdal_translate -a_nodata 0  -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $1) -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -tr 0.0041666666666666666 0.0041666666666666666 -r mod  -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt $RAM/${file}_5p_ct.tif 

' _ 

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt.ovr              $RAM/*_5p.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt.ovr.ovr          $RAM/*_10p.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt.ovr.ovr.ovr      $RAM/*_20p.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt.ovr.ovr.ovr.ovr  $RAM/*_40p.tif

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt.ovr              $RAM/*_5p_ct.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt.ovr.ovr          $RAM/*_10p_ct.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt.ovr.ovr.ovr      $RAM/*_20p_ct.tif
# gdalbuildvrt -srcnodata 0 -vrtnodata 0  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt.ovr.ovr.ovr.ovr  $RAM/*_40p_ct.tif

echo "lbasin_compUnit_enlarg lbasin_compUnit_enlarg_ct"  | xargs -n 1 -P 2 bash -c $'
file=$1
GDAL_CACHEMAX=5000
gdal_translate -a_nodata 0 -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co TILED=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/lbasin_compUnit_overview/$file.vrt.ovr $SCMH/lbasin_compUnit_overview/${file}_5p.tif

' _    & 

echo "lbasin_compUnit_enlarg lbasin_compUnit_enlarg_ct"  | xargs -n 1 -P 2 bash -c $'
file=$1
GDAL_CACHEMAX=30000

gdal_translate -a_nodata 0 -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co TILED=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/lbasin_compUnit_overview/$file.vrt   $SCMH/lbasin_compUnit_overview/${file}.tif

' _ 

rm $RAM/*.tif $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.vrt.o*   $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg.vrt.o*
