#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 10:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc26_tiling20d_lbasin_reclass_ctcreate.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc26_tiling20d_lbasin_reclass_ctcreate.sh.%A_%a.err
#SBATCH --job-name=sc26_tiling20d_lbasin_reclass_ctcreate.sh
#SBATCH --array=1-116
#SBATCH --mem=40G

#### 116  tiles 20 degree full 
###  h26v04 tile with full covarege (no sea) array 78

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc26_tiling20d_lbasin_reclass_ctcreate.sh
#### sbatch  --dependency=afterany:$( myq | grep sc22_tiling20d_lbasin_sieve.sh | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc26_tiling20d_lbasin_reclass_ctcreate.sh
ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=11

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_tiles_final20d/lbasin_h??v??.tif   | head -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
export filename=$( basename $file .tif ) 
export tile=${filename:7:6}
export GDAL_CACHEMAX=8000

echo pkreclass $SCMH/lbasin_tiles_final20d/lbasin_$tile.tif    # final number of lbasin from 1982923 to 1445576
pkreclass -ot UInt32 -code  $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_all.txt  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2  -i $file -o $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif

gdal_edit.py -a_nodata 0  $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif
# gdal_edit.py -a_ullr  $( getCorners4Gtranslate $file  )    $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif
# gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif
# gdal_edit.py -a_ullr  $( getCorners4Gtranslate $file   )   $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif
# gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif

### create a unique streamID as lbasin and save in lstream 
 
pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $SCMH/stream_tiles_final20d_1p/stream_${tile}.tif -msknodata 0 -nodata 0  -i  $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif -o $SCMH/lstream_tiles_final20d_1p/lstream_${tile}.tif

### usefull for the oft-bb
pkstat -src_min $(gdalinfo -mm $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif | grep Computed | awk -F "=" '{ print int($2) }')  -hist -i $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif  | awk -v SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID  -v tile=$tile  'BEGIN { print 0 , 0,  "lbasin_" tile ".tif" , 0 }{ if ( $2!=0 ) {print $1 , $2 , "lbasin_" tile ".tif" , SLURM_ARRAY_TASK_ID  } }' >  $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}_histile.txt 

echo apply ct 

echo lbasin basin outlet lstream dir | xargs -n 1 -P 4 bash -c $'
var=$1

if [ $var = lstream  ]  ; then
# color lstream with the same color of lbasin 

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES  -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_ct.txt $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ct.tif

else 

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES  -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif $SCMH/${var}_tiles_final20d_1p/${var}_hist_ct.txt $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ct.tif

fi 
' _


echo pkfilter usefull for the overview  

for var in lbasin basin outlet lstream dir ; do 
export var=$var 
if [ $var = basin  ]  ; then export ND=0   ; fi
if [ $var = lbasin ]  ; then export ND=0   ; fi
if [ $var = lstream ]  ; then export ND=0   ; fi
if [ $var = outlet ]  ; then export ND=0   ; fi
if [ $var = dir    ]  ; then export ND=-10 ; fi

echo 5 10 20 40 | xargs -n 1 -P 4 bash -c $' 
P=$1
pkfilter -nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2  -ot Byte   -of GTiff -dx $P  -dy  $P -d  $P -f mode -i  $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ct.tif -o $SCMH/${var}_tiles_final20d_${P}p_ct/${var}_${tile}_${P}p_ct.tif

pkfilter -nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2  -ot UInt32 -of GTiff -dx $P  -dy  $P -d  $P  -f mode -i  $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif -o $SCMH/${var}_tiles_final20d_${P}p/${var}_${tile}_${P}p.tif

' _ 

# building tif with the overview 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt               $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt.ovr           $SCMH/${var}_tiles_final20d_5p_ct/${var}_${tile}_5p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt.ovr.ovr       $SCMH/${var}_tiles_final20d_10p_ct/${var}_${tile}_10p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt.ovr.ovr.ovr   $SCMH/${var}_tiles_final20d_20p_ct/${var}_${tile}_20p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt.ovr.ovr.ovr.ovr $SCMH/${var}_tiles_final20d_40p_ct/${var}_${tile}_40p_ct.tif 

gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt                 $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt.ovr             $SCMH/${var}_tiles_final20d_5p/${var}_${tile}_5p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt.ovr.ovr         $SCMH/${var}_tiles_final20d_10p/${var}_${tile}_10p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt.ovr.ovr.ovr     $SCMH/${var}_tiles_final20d_20p/${var}_${tile}_20p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt.ovr.ovr.ovr.ovr $SCMH/${var}_tiles_final20d_40p/${var}_${tile}_40p.tif 

GDAL_CACHEMAX=30000  
gdal_translate -a_nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co COPY_SRC_OVERVIEWS=YES  -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vrt      $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.tif
gdal_translate -a_nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co COPY_SRC_OVERVIEWS=YES  -co NUM_THREADS=2 -co TILED=YES $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vrt $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ct_ovr.tif 

rm $SCMH/${var}_tiles_final20d_1p_ct/${var}_${tile}_ctovr.vr* $SCMH/${var}_tiles_final20d_1p/${var}_${tile}_ovr.vr*

done 


# start to merge the results 
if [ $SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_MAX  ] ; then 

for var in  lbasin basin lstream outlet dir ; do   
sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc26_tiling20d_lbasin_reclass_ctcreate.sh   | awk '{ print $1  }' | uniq )     --export=var=$var  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc27_merge20d_1-40p_ct.sh  
done

## sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep   sc25_tiling20d_lbasin_reclass.sh  | awk '{ print $1  }' | uniq )    /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc30_tiling20d_lbasin_oftbb_prep.sh
sleep 60
fi

