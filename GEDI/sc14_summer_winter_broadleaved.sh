#!/bin/bash -l
#SBATCH -n 1 -c 5 -N 1
#SBATCH -t 5:00:00  
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc14_summer_winter_broadleaved_%J.sh.err
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc14_summer_winter_broadleaved_%J.sh.out
#SBATCH --mem=10G 
#SBATCH --job-name=sc14_summer_winter_broadleaved.sh
#SBATCH --array=1-1148

### sbatch --export=string=x_y_more  /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc14_summer_winter_broadleaved.sh


### --array=1-1148

# created: Oct 7, 2020 10:43 PM
# author: Zhipeng Tang

# This script contains three steps


####################################### Step 1 #################################################
# create a global txt file 
################################################################################################



#### to check for cancelled jobs. 
#########  grep CANCELLED  /gpfs/gibbs/pi/hydro/hydro/stderr1/*.sh.*.err | grep ICE | awk -F "_" -F "." '{  print  $3 }' | awk -F "_"  '{  print  $2 }' 

source ~/bin/gdal3
source ~/bin/pktools

export RAM=/dev/shm
export BB=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/QC_TXT
export SHP=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/summer_winter_broadleaved_shp
export TIF=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_tif

### SLURM_ARRAY_TASK_ID=107
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

echo $file 
echo $ID

mkdir -p $SHP/{summer,winter}
mkdir -p $TIF/{summer,winter}

# Read the array values with space

################   DIR=summer #########################

ls $BB/${string}_{2019.06,2019.07,2019.08}*.txt  | xargs -n 1 -P 6 bash -c $'
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _


DIR=summer

cat $RAM/${string}_*_inTile_$ID.txt >  $SHP/${DIR}/point_inTile_$ID.txt  
rm  $RAM/${string}_*_inTile_$ID.txt

## check if ${DIR}/point_inTile_$ID.txt is empty

if test -s $SHP/${DIR}/point_inTile_$ID.txt; then

GDAL_CACHEMAX=8000
rm -f $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx} 
pkascii2ogr -x 0 -y 1 -n "Hight" -ot "Real" -i $SHP/$DIR/point_inTile_$ID.txt -o $RAM/${string}_inTile_$ID.shp
gdal_rasterize  -init -9 -a_nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "${string}_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Float32 $RAM/${string}_inTile_$ID.shp $TIF/$DIR/pointF_inTile_alltypes_$ID.tif
### see classes in  /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc03_classsplit_displacement.sh 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $TIF/$DIR/pointF_inTile_alltypes_$ID.tif -m  /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input/ESALC_2018.tif --operator='>' --msknodata 82.5 --nodata -9 --operator='<' --msknodata 49.5 --nodata -9 -o $TIF/$DIR/pointF_inTile_$ID.tif

rm -f  $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx}

MAX=$(pkstat -max  -i   $TIF/$DIR/pointF_inTile_$ID.tif  | awk '{ print $2  }' )
if [ $MAX =  "-9"  ] ; then 
rm  -f $TIF/$DIR/pointF_inTile_$ID.tif 
fi 

else

echo $SHP/${DIR}/point_inTile_$ID.txt is empty
rm $SHP/${DIR}/point_inTile_$ID.txt
fi 


################   DIR=winter #########################

ls $BB/${string}_{2019.12,2020.01,2020.02}*.txt  | xargs -n 1 -P 6 bash -c $'
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _


DIR=winter

cat $RAM/${string}_*_inTile_$ID.txt >  $SHP/${DIR}/point_inTile_$ID.txt  
rm  $RAM/${string}_*_inTile_$ID.txt

## check if ${DIR}/point_inTile_$ID.txt is empty

if test -s $SHP/${DIR}/point_inTile_$ID.txt; then

GDAL_CACHEMAX=8000
rm -f $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx} 
pkascii2ogr -x 0 -y 1 -n "Hight" -ot "Real" -i $SHP/$DIR/point_inTile_$ID.txt -o $RAM/${string}_inTile_$ID.shp
gdal_rasterize  -init -9 -a_nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "${string}_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Float32 $RAM/${string}_inTile_$ID.shp $TIF/$DIR/pointF_inTile_alltypes_$ID.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $TIF/$DIR/pointF_inTile_alltypes_$ID.tif -m  /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input/ESALC_2018.tif --operator='>' --msknodata 82.5 --nodata -9 --operator='<' --msknodata 49.5 --nodata -9 -o $TIF/$DIR/pointF_inTile_$ID.tif

rm -f  $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx}

MAX=$(pkstat -max  -i   $TIF/$DIR/pointF_inTile_$ID.tif  | awk '{ print $2  }' )
if [ $MAX =  "-9"  ] ; then 
rm  -f $TIF/$DIR/pointF_inTile_$ID.tif 
fi 

else

echo $SHP/${DIR}/point_inTile_$ID.txt is empty
rm $SHP/${DIR}/point_inTile_$ID.txt
fi 



exit 





mkdir -p $SW_txt

rm -f $SW_txt/*.txt 
 
cd $SW_txt

### 20??.??.??_h5_list


cat $(ls $QC_txt/*allfilter* | grep -E  "2019.07|2019.08|2019.09") > summer.txt


cat $(ls $QC_txt/*allfilter* | grep -E  "2019.11|2019.12|2020.01") > winter.txt
 

## create SHP files

ls $QC_txt/*allfilter* | grep -E  "2019.07|2019.08|2019.09"  | xargs -n 1 -P 6 bash -c $'
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _


