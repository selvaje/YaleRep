#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_monthlymean.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_monthlymean.sh.%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_monthlymean.sh
#SBATCH --array=1-12

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/SNOWESA/sc02_monthlymean.sh

export DIR=/project/fas/sbsc/ga254/dataproces/SNOWESA/input 

# SLURM_ARRAY_TASK_ID=1
export MONTH=$SLURM_ARRAY_TASK_ID

if [ $MONTH -lt 10 ] ; then  MONTH=$( echo 0$MONTH) ; fi 

echo -180   0  -90 90 a   >  $DIR/tile$MONTH.txt
echo  -90   0    0 90 b   >> $DIR/tile$MONTH.txt
echo    0   0   90 90 c   >> $DIR/tile$MONTH.txt
echo   90   0  180 90 d   >> $DIR/tile$MONTH.txt
echo -180 -90  -90  0 e   >> $DIR/tile$MONTH.txt
echo  -90 -90    0  0 f   >> $DIR/tile$MONTH.txt
echo    0 -90   90  0 g   >> $DIR/tile$MONTH.txt
echo   90 -90  180  0 h   >> $DIR/tile$MONTH.txt

# AWCts = Saturated water content   follow the same but calculate the mean 
# sl1 to sl7 are different depths in 0,5,15,30,60,100,200cm and need to be summed to obtain one grid with the total saturated water content from 0 to 2m. Information how to sum up is given here on p.3:
# http://gsif.isric.org/lib/exe/fetch.php?media=wiki:soilgrids250m_global_gridded_preprint.pdf

cat   $DIR/tile$MONTH.txt | xargs -n 5  -P 8 bash -c $' 

gdalbuildvrt -overwrite -separate   -te $1 $2 $3 $4    $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0_$5.vrt  $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}*-v2.0.tif 
pkstatprofile -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -nodata 255 -nodata 254  -f max  -i $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0_$5.vrt -o $DIR/../month/Snow_M${MONTH}_$5.tif
gdal_edit.py -a_ullr  $(  getCorners4Gtranslate   $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0_$5.vrt )    $DIR/../month/Snow_M${MONTH}_$5.tif

' _ 

gdalbuildvrt  -overwrite    $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0.vrt  $DIR/../month/Snow_M${MONTH}_?.tif
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0.vrt  $DIR/../month/Snow_M${MONTH}.tif
# rm $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0.vrt  $DIR/../month/Snow_M${MONTH}_?.tif $DIR/ESACCI-LC-L4-Snow-Cond-AggOcc-500m-P13Y7D-2000-2012-2000${MONTH}-v2.0_?.vrt  $DIR/tile$MONTH.txt 


