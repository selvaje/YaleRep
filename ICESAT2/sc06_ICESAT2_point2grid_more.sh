#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 1:30:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc06_ICESAT2_point2grid_more.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc06_ICESAT2_point2grid_more.sh.%A_%a.err
#SBATCH --job-name=sc06_ICESAT2_point2grid_more.sh
#SBATCH --mem=5G
#SBATCH --array=1-1148

######  337 for testing
######  --array=1-1148

### for NUM in 70 75 80 85 90 95 ; do sbatch --export=num=$NUM /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc06_ICESAT2_point2grid_more.sh ; done

### sbatch --export=string=x_y_more /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc06_ICESAT2_point2grid_more.sh 

#### to check for cancelled jobs. 
#########  grep CANCELLED  /gpfs/gibbs/pi/hydro/hydro/stderr1/*.sh.*.err | grep ICE | awk -F "_" -F "." '{  print  $3 }' | awk -F "_"  '{  print  $2 }' 

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export RAM=/dev/shm
export BB=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/QC_TXT
export SHP=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/QC_shp
export TIF=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/QC_tif

### SLURM_ARRAY_TASK_ID=107
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

export string=x_y_more_${num}
export DIR=icesat2_${num}

echo $file 
echo $ID

mkdir -p $SHP/${DIR}
mkdir -p $TIF/${DIR}

# Read the array values with space


ls $BB/${string}_*.txt  | xargs -n 1 -P 6 bash -c $'
BLOCK=$1
filename=$(basename $BLOCK .txt )
paste -d " " $BLOCK  <( gdallocationinfo -geoloc -valonly $file  <  <(awk \'{ print $1 , $2 }\' $BLOCK ) )  | awk \'{if ($4!="") print $1, $2, $3  }\' >  $RAM/${filename}_inTile_$ID.txt
' _


cat $RAM/${string}_*_inTile_$ID.txt >  $SHP/${DIR}/point_inTile_$ID.txt  
rm  $RAM/${string}_*_inTile_$ID.txt

## check if ${DIR}/point_inTile_$ID.txt is empty

if test -s $SHP/${DIR}/point_inTile_$ID.txt; then

GDAL_CACHEMAX=8000

# point to raster by gdal 
# rm -f $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx} 
# pkascii2ogr -x 0 -y 1 -n "Hight" -ot "Real" -i $SHP/$DIR/point_inTile_$ID.txt -o $RAM/${string}_inTile_$ID.shp
# gdal_rasterize  -init -9 -a_nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a "Hight" -l "${string}_inTile_$ID" -te $(getCorners4Gwarp $file) -tr 0.00025 0.00025 -ot Float32 $RAM/${string}_inTile_$ID.shp $TIF/$DIR/pointF_inTile_$ID.tif
# rm -f  $RAM/${string}_inTile_$ID.{shp,prj,dbf,shx}

# point to raster by grass 

cp $file $RAM
grass78  -f -text --tmp-location  -c $RAM/${ID}_elv.tif  <<'EOF'
r.external  input=$RAM/${ID}_elv.tif output=elv  --o
g.region res=0.00025  --o
r.in.xyz  type=FCELL  input=$SHP/$DIR/point_inTile_$ID.txt  output=point_inTile_$ID    method=median separator=space  --o 
r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9 input=point_inTile_$ID output=$TIF/$DIR/pointF_inTile_${ID}_gr.tif
EOF

rm -f $RAM/${ID}_elv.tif 

MAX=$(pkstat -max  -i   $TIF/$DIR/pointF_inTile_${ID}_gr.tif  | awk '{ print $2  }' )
if [ $MAX =  "-9"  ] ; then 
rm  -f $TIF/$DIR/pointF_inTile_${ID}_gr.tif 
fi 

else

echo $SHP/${DIR}/point_inTile_$ID.txt is empty
rm $SHP/${DIR}/point_inTile_$ID.txt
fi 
