#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc27_merge20d_1-40p_ct.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc27_merge20d_1-40p_ct.sh.%J.err
#SBATCH --job-name=sc27_merge20d_1-40p_ct.sh
#SBATCH --mem=80G

## for var in lbasin basin lstream outlet dir ; do   sbatch --export=var=$var  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc27_merge20d_1-40p_ct.sh  ; done 
## sbatch --dependency=afterany:$(myq | grep sc23_tiling20d_lbasin_reclass.sh | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc27_merge20d_1-40p_ct.sh 

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export var=$var 

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

#### building full tif for ID extraction ; # the overview is not transfered with gdal_translate 

if [ $var = basin ]  ; then export ND=0   ; fi
if [ $var = lbasin ]  ; then export ND=0   ; fi
if [ $var = lstream ]  ; then export ND=0   ; fi
if [ $var = outlet ]  ; then export ND=0   ; fi
if [ $var = dir    ]  ; then export ND=-10 ; fi

rm -f $SCMH/${var}_tiles_final20d_ovr/*  
### vrt in 1p
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_1p/all_${var}_dis.vrt                  $SCMH/${var}_tiles_final20d_1p/${var}_h??v??.tif
### vrt in ovr 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt                   $SCMH/${var}_tiles_final20d_1p/${var}_h??v??.tif
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt.ovr               $SCMH/${var}_tiles_final20d_5p/${var}_h??v??_5p.tif
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt.ovr.ovr           $SCMH/${var}_tiles_final20d_10p/${var}_h??v??_10p.tif
# gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt.ovr.ovr.ovr       $SCMH/${var}_tiles_final20d_20p/${var}_h??v??_20p.tif
# gdalbuildvrt -srcnodata $ND -vrtnodata $ND -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt.ovr.ovr.ovr.ovr   $SCMH/${var}_tiles_final20d_40p/${var}_h??v??_40p.tif

gdalbuildvrt -srcnodata $ND -vrtnodata $ND  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85   $SCMH/${var}_tiles_final20d_ovr/all_${var}_ct_dis.vrt                   $SCMH/${var}_tiles_final20d_1p_ct/${var}_h??v??_ct.tif
gdalbuildvrt -srcnodata $ND -vrtnodata $ND  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85   $SCMH/${var}_tiles_final20d_ovr/all_${var}_ct_dis.vrt.ovr               $SCMH/${var}_tiles_final20d_5p_ct/${var}_h??v??_5p_ct.tif
gdalbuildvrt -srcnodata $ND -vrtnodata $ND  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85   $SCMH/${var}_tiles_final20d_ovr/all_${var}_ct_dis.vrt.ovr.ovr           $SCMH/${var}_tiles_final20d_10p_ct/${var}_h??v??_10p_ct.tif
# gdalbuildvrt -srcnodata $ND -vrtnodata $ND  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85   $SCMH/${var}_tiles_final20d_ovr/all_${var}_ct_dis.vrt.ovr.ovr.ovr       $SCMH/${var}_tiles_final20d_20p_ct/${var}_h??v??_20p_ct.tif
# gdalbuildvrt -srcnodata $ND -vrtnodata $ND  -a_srs EPSG:4326  -overwrite  -te -180 -60 191 85   $SCMH/${var}_tiles_final20d_ovr/all_${var}_ct_dis.vrt.ovr.ovr.ovr.ovr   $SCMH/${var}_tiles_final20d_40p_ct/${var}_h??v??_40p_ct.tif

echo "all_${var} all_${var}_ct"  | xargs -n 1 -P 2 bash -c $'
file=$1
GDAL_CACHEMAX=30000
if [ $var = lbasin ] ; then 
gdal_translate -a_nodata $ND -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_ovr/${file}_dis.vrt.ovr $SCMH/${var}_tiles_final20d_ovr/${file}_5p.tif  
# gdal_translate -a_nodata $ND -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_ovr/${file}_dis.vrt.ovr.ovr.ovr $SCMH/${var}_tiles_final20d_ovr/${file}_20p.tif  
# gdal_translate -a_nodata $ND -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_ovr/${file}_dis.vrt.ovr.ovr.ovr.ovr $SCMH/${var}_tiles_final20d_ovr/${file}_40p.tif  
fi 

gdal_translate -a_nodata $ND -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_ovr/${file}_dis.vrt     $SCMH/${var}_tiles_final20d_ovr/${file}.tif

gdal_translate -a_nodata $ND -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_ovr/${file}_dis.vrt.ovr.ovr $SCMH/${var}_tiles_final20d_ovr/${file}_10p.tif  
' _ 

# rm -f $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis.vrt.*  $SCMH/${var}_tiles_final20d_ovr/all_${var}_dis_ct.vrt.*
