#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 1:30:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc11_GEDI_point2grid.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc11_GEDI_point2grid.sh.%A_%a.err
#SBATCH --job-name=sc11_GEDI_point2grid.sh
#SBATCH --mem=5G
#SBATCH --array=1-1148

######  337 for testing
######  --array=1-1148

### x_y_sensitivity 

### for string  in x_y_allfilter x_y_day x_y_coveragebeam x_y_degrade; do sbatch --export=string=$string  /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc11_GEDI_point2grid.sh ; done 

#### to check for cancelled jobs. 
#########  grep CANCELLED  /gpfs/gibbs/pi/hydro/hydro/stderr1/*.sh.*.err | grep ICE | awk -F "_" -F "." '{  print  $3 }' | awk -F "_"  '{  print  $2 }' 

source ~/bin/gdal3
source ~/bin/pktools

export RAM=/dev/shm
export BB=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/QC_TXT
export SHP=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_shp
export TIF=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif

### SLURM_ARRAY_TASK_ID=107
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

echo $file 
echo $ID

mkdir -p $BB
mkdir -p $SHP/{af,dy,cb,st,de}
mkdir -p $TIF/{af,dy,cb,st,de}

# Read the array values with space


ls $BB/${string}_*.txt  | xargs -n 1 -P 6 bash -c $'
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _


if [ $string = x_y_allfilter ]       ;  then DIR=af  ; fi 
if [ $string = x_y_day ]             ;  then DIR=dy  ; fi 
if [ $string = x_y_coveragebeam ]    ;  then DIR=cb  ; fi 
if [ $string = x_y_sensitivity ]     ;  then DIR=st  ; fi 
if [ $string = x_y_degrade ]         ;  then DIR=de  ; fi 

cat $RAM/${string}_*_inTile_$ID.txt >  $SHP/${DIR}/point_inTile_$ID.txt  
rm  $RAM/${string}_*_inTile_$ID.txt

## check if ${DIR}/point_inTile_$ID.txt is empty

if test -s $SHP/${DIR}/point_inTile_$ID.txt; then

GDAL_CACHEMAX=8000
rm -f $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx} 
pkascii2ogr -x 0 -y 1 -n "Hight" -ot "Real" -i $SHP/$DIR/point_inTile_$ID.txt -o $RAM/${string}_inTile_$ID.shp
gdal_rasterize  -init -9 -a_nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "${string}_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Float32 $RAM/${string}_inTile_$ID.shp $TIF/$DIR/pointF_inTile_$ID.tif
rm -f  $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx}

MAX=$(pkstat -max  -i   $TIF/$DIR/pointF_inTile_$ID.tif  | awk '{ print $2  }' )
if [ $MAX =  "-9"  ] ; then 
rm  -f $TIF/$DIR/pointF_inTile_$ID.tif 
fi 

else

echo $SHP/${DIR}/point_inTile_$ID.txt is empty
rm $SHP/${DIR}/point_inTile_$ID.txt
fi 
