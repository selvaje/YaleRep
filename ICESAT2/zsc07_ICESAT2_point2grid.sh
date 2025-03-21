#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc07_ICESAT2_point2grid.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc07_ICESAT2_point2grid.sh.%A_%a.err
#SBATCH --job-name=sc07_ICESAT2_point2grid.sh
#SBATCH --mem=5G
#SBATCH --array=1-1148

######  --array=1-1148
### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc07_ICESAT2_point2grid.sh
#### to check for cancelled jobs. 
#########  grep CANCELLED  /gpfs/gibbs/pi/hydro/hydro/stderr1/*.sh.*.err | grep ICE | awk -F "_" -F "." '{  print  $3 }' | awk -F "_"  '{  print  $2 }' 

source ~/bin/gdal3
source ~/bin/pktools

export RAM=/dev/shm
export TIF=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/tif
export SHP=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/shp
export  BB=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/blockfile

##  SLURM_ARRAY_TASK_ID=107
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

echo $file 
echo $ID

ls $BB/blockfile*.txt  | xargs -n 1 -P 6 bash -c $' 
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _

cat $RAM/blockfile*_inTile_$ID.txt > $SHP/point_inTile_$ID.txt
rm  $RAM/blockfile*_inTile_$ID.txt 

echo create the shp
rm -f $SHP/point_inTile_$ID.{shp,prj,dbf,shx}
pkascii2ogr  -x 0 -y 1  -n "Hight" -ot "Real"    -i $SHP/point_inTile_$ID.txt   -o $SHP/point_inTile_$ID.shp


echo rasterize 
export GDAL_CACHEMAX=8000

gdal_rasterize -co COMPRESS=DEFLATE -co ZLEVEL=9 -burn 1  -l "point_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Byte     $SHP/point_inTile_$ID.shp $TIF/pointB_inTile_$ID.tif
MAX=$(pkstat -max  -i  $TIF/pointB_inTile_$ID.tif   | awk '{ print int($2)  }' )

if [ $MAX -eq 0  ] ; then 
rm  $SHP/point_inTile_$ID.shp $TIF/pointB_inTile_$ID.tif
else 
gdal_rasterize -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "point_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Float32  $SHP/point_inTile_$ID.shp $TIF/pointF_inTile_$ID.tif
fi 




exit 
below for higher resolution 

gdal_rasterize -co COMPRESS=DEFLATE -co ZLEVEL=9 -burn 255  -l "point_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.0000833333333333 0.0000833333333333 -ot Byte     $SHP/point_inTile_$ID.shp $TIF/pointB_inTile_$ID.tif
gdal_rasterize -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "point_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.0000833333333333 0.0000833333333333 -ot Float32  $SHP/point_inTile_$ID.shp $RAM/pointF_inTile_$ID.tif

echo  transfer the hight to neighboroud  pixel
pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 3 -dy 3      -f max -i  $RAM/pointF_inTile_$ID.tif   -o $RAM/pointF3F_inTile_$ID.tif
rm -f $RAM/pointF_inTile_$ID.tif 
echo  aggregate at lower resolution (=landsat resolution)
pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 3 -dy 3 -d 3 -f max -i  $RAM/pointF3F_inTile_$ID.tif -o $TIF/pointF3D_inTile_$ID.tif 

rm -f  $RAM/pointF3F_inTile_$ID.tif
