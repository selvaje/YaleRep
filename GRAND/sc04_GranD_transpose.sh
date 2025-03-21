#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 14:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_GranD_transpose.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_GranD_transpose.sh.%A_%a.err
#SBATCH --job-name=sc04_GranD_transpose.sh
#SBATCH --mem-per-cpu=15G
#SBATCH --array=1-60

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRAND/sc04_GranD_transpose.sh

source ~/bin/gdal3
source ~/bin/pktools

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND
tif=$(ls $DIR/out/GRanD_????.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 

export tifname=$( basename $tif .tif )
export NAsource=$( gdalinfo $tif | grep "NoData" | awk -F "=" '{ print $2   }' )
export RAM=/dev/shm
GDAL_CACHEMAX=8000

#####    FIRST   ###############
#### ... Prepare the tile with the transposed peninsula
echo ------
echo First : Prepare the tile with the transposed peninsula
echo ------

##  CUT
gdal_translate  -of VRT  -projwin  -180 75 -169 60 $tif  $RAM/${tifname}_cropwest.vrt

##  MASK
pksetmask -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif  -msknodata 0 -nodata ${NAsource} -i $RAM/${tifname}_cropwest.vrt  -o $DIR/out/${tifname}_transpose2east.tif

##  TRANSPOSE
gdal_edit.py  -a_ullr 180 75 191 60 $DIR/out/${tifname}_transpose2east.tif

#####    SECOND   ###############
####   split the global coverage into four tiles
echo ------
echo SECOND:split the global coverage into four tiles
echo ------

echo  BUILDVRT 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 85  -169  60 $tif   ${RAM}/${tifname}_ta.vrt     # upper left
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -169 85   180  60 $tif   $DIR/out/${tifname}_tb.vrt   # upper center right 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 60   180 -60 $tif   $DIR/out/${tifname}_tc.vrt   # lower left   center right 

####   Take tile a and mask (remove) the peninsula (amsk.tif)
echo ------
echo  Take tile a and mask the peninsula
echo ------

pksetmask -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata ${NAsource} -i ${RAM}/${tifname}_ta.vrt -o $DIR/out/${tifname}_ta_msk.tif

#####   THIRD   ###############
## merge
echo ------
echo merge all vrts
echo ------

gdalbuildvrt -srcnodata ${NAsource} -vrtnodata ${NAsource} -te -180 -60 191 85 $DIR/out/${tifname}_dis.vrt $DIR/out/${tifname}_ta_msk.tif $DIR/out/${tifname}_t{b,c}.vrt $DIR/out/${tifname}_transpose2east.tif

gdal_translate  -tr 0.008333333333333333 0.008333333333333333 -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/out/${tifname}_dis.vrt  $DIR/out/${tifname}_dis_1km.tif 
rm $RAM/${tifname}*

exit 
## enlarge    ############################## enlarge of 200 =  10 * 5 * 4  = the same as TERRA 10 
## did not do it the enlargement becouse already masked with elevation in the previus script.
