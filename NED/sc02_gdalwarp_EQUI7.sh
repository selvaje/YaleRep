#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10 -N 1  
#SBATCH -t 1:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_gdalwarp_EQUI7.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_gdalwarp_EQUI7.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_gdalwarp_EQUI7.sh 
#SBATCH --mem-per-cpu=5000


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NED/sc02_gdalwarp_EQUI7.sh 

export NEDS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/NED/tif
export NEDP=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif
export EQUI7=/project/fas/sbsc/ga254/dataproces/EQUI7
export RAM=/dev/shm

export CT=NA

# gdalbuildvrt -srcnodata  -3.4028234663852886e+38 -vrtnodata -9999 $NEDS/all_tif.vrt $NEDS/*.tif  -overwrite 


ls   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/*.tif | xargs -n 1 -P 10  bash -c $' 
file=$1 
filename=$(basename $file )

gdalwarp -srcnodata -9999 -dstnodata -9999  -te  $(  getCorners4Gwarp  $file )   -wm 4000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs "$EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj" -tr 100 100 -r bilinear $NEDS/all_tif.vrt /dev/shm/$filename -overwrite

MAX=$(pkstat -max -i  /dev/shm/$filename  | awk \'{ print $2 }\')
if [ $MAX ==  "-9999" ] ; then 
rm -f /dev/shm/$filename 
else 
pksetmask -co COMPRESS=DELATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $file  -msknodata -9999 -nodata -9999 -i /dev/shm/$filename  -o   $NEDP/$filename 
rm -f /dev/shm/$filename 
fi

' _ 

rm -f /dev/shm/*.tif 

gdalbuildvrt -overwrite  $NEDP/all_${CT}_tif.vrt  $NEDP${CT}_???_???.tif  
rm $NEDS/tile_equi7_${CT}_warp.txt 

