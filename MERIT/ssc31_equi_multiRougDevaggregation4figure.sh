#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 20  -N 1  
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_equi_multiRougDevaggregation4figure.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_equi_multiRougDevaggregation4figure.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_equi_multiRougDevaggregation4figure.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc31_equi_multiRougDevaggregation4figure.sh

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_BK
export RAM=/dev/shm
export KM=5.00

for VAR in deviation multirough ; do 
if  [ $VAR = "deviation" ]  ; then export VAR2=devi   ; fi 
if  [ $VAR = "multirough" ] ; then export VAR2=roug  ; fi 

export VAR

# ls /gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT_BK/${VAR}/tiles/??_???_???_${VAR2}_mag.tif    | xargs -n 1 -P 20  bash -c $' 
# file=$1 
# export filename=$(basename $file .tif )
# export CT=${filename:0:2}
# pkfilter  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Float32 -nodata -9999  -dx 50 -dy 50 -d 50  -f mean   -i $file -o $RAM/$filename.tif 
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Float32  -m $MERIT/../EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE_KM$KM.tif -msknodata 0 -nodata -9999 -i $RAM/$filename.tif -o  $SCRATCH/${VAR}/tiles_5km/$filename.tif
# rm -f $RAM/$filename.tif 
# ' _
 
echo  AF AN AS EU NA OC SA 
echo  AF AN AS EU NA OC SA   | xargs -n 1 -P 7  bash -c $' 
CT=$1
gdalbuildvrt  -srcnodata -9999  -vrtnodata -9999  -overwrite    $SCRATCH/${VAR}/${CT}_${VAR2}_5km.vrt  $SCRATCH/${VAR}/tiles_5km/${CT}_???_???_*.tif  
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    -ot Float32   $SCRATCH/${VAR}/${CT}_${VAR2}_5km.vrt     $SCRATCH/${VAR}/${CT}_${VAR2}_5km.tif
rm -f   $SCRATCH/${VAR}/${CT}_${VAR2}_5km.vrt  
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Byte -min -100 -max 99999999999 -data 1 -nodata 0 -i  $SCRATCH/${VAR}/${CT}_${VAR2}_5km.tif -o  $SCRATCH/${VAR}/${CT}_${VAR2}_5km_msk.tif

gdal_translate -srcwin $(oft-bb $SCRATCH/${VAR}/${CT}_${VAR2}_5km_msk.tif 1 | grep "Band 1" | awk \'{ print $6 - 10  ,$7 -10 , $8-$6+1 + 20  , $9-$7+1 + 20}\')  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND       $SCRATCH/${VAR}/${CT}_${VAR2}_5km.tif     $SCRATCH/${VAR}/${CT}_${VAR2}_5km_crop.tif
mv    $SCRATCH/${VAR}/${CT}_${VAR2}_5km_crop.tif    $SCRATCH/${VAR}/${CT}_${VAR2}_5km.tif
rm -f  $SCRATCH/${VAR}/${CT}_${VAR2}_5km_msk.tif
' _ 

done 
