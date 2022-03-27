#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10  -N 1  
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_equi_formsaggregation4figure.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_equi_formsaggregation4figure.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_equi_formsaggregation4figure.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc31_equi_formsaggregation4figure.sh

ulimit -c 0

export MERIT=/gpfs/loomis/project/sbsc/ga254/dataproces/MERIT/gdrive100m
export RAM=/dev/shm
export KM=1.00

source ~/bin/gdal
source ~/bin/pktools 

##export VAR=rough-magnitude
export VAR=dev-magnitude


ls $MERIT/${VAR}/${VAR}_100M_MERIT_??_???_???.tif  | xargs -n 1 -P 10  bash -c $' 
file=$1 
export filename=$(basename $file .tif )

export CT=${filename:25:2}  ### for the dev-mag
## export CT=${filename:27:2}  ### for the rough-mag

pkfilter  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Float32 -nodata -9999  -dx 10 -dy 10 -d 10  -f mean   -i $file -o $RAM/$filename.tif 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Float32  -m $MERIT/../../EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE_KM$KM.tif -msknodata 0 -nodata -9999 -i $RAM/$filename.tif -o  $MERIT/${VAR}_1km/$filename.tif
rm -f $RAM/$filename.tif
' _
 

echo  AF AN AS EU NA OC SA 
echo  AF AN AS EU NA OC SA   | xargs -n 1 -P 7  bash -c $' 
CT=$1
gdalbuildvrt  -srcnodata -9999  -vrtnodata -9999  -overwrite    $MERIT/${VAR}_1km/${CT}_${VAR}_1km.vrt  $MERIT/${VAR}_1km/${VAR}_100M_MERIT_${CT}_???_???.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    -ot Float32   $MERIT/${VAR}_1km/${CT}_${VAR}_1km.vrt     $MERIT/${VAR}_1km/${CT}_${VAR}_1km.tif  
rm -f   $MERIT/${VAR}/${CT}_${VAR}_1km.vrt  
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Byte -min -100 -max 99999999999 -data 1 -nodata 0 -i  $MERIT/${VAR}_1km/${CT}_${VAR}_1km.tif -o  $MERIT/${VAR}_1km/${CT}_${VAR}_1km_msk.tif

gdal_translate -srcwin $(oft-bb $MERIT/${VAR}_1km/${CT}_${VAR}_1km_msk.tif 1 | grep "Band 1" | awk \'{ print $6 - 10  ,$7 -10 , $8-$6+1 + 20  , $9-$7+1 + 20}\')  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND       $MERIT/${VAR}_1km/${CT}_${VAR}_1km.tif     $MERIT/${VAR}_1km/${CT}_${VAR}_1km_crop.tif
mv    $MERIT/${VAR}_1km/${CT}_${VAR}_1km_crop.tif    $MERIT/${VAR}_1km/${CT}_${VAR}_1km.tif
rm -f  $MERIT/${VAR}_1km/${CT}_${VAR}_1km_msk.tif

' _ 


