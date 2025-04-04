#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/hydro/stdout/sc05_weightedAVE.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/hydro/stderr/sc05_weightedAVE.sh.%A_%a.err
#SBATCH --job-name=sc05_weightedAVE.sh
#SBATCH --mem-per-cpu=10G
#SBATCH --array=1-116

###### complete job array:#    --array=1-116
###### ==============================================[SBATCH LINE]========================================================
###### for var in clay sand silt ; do sbatch --exclude=r805u25n04,r806u14n01  --export=var=$var  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc05_weightedAVE.sh; done 
###### ===================================================================================================================

module load StdEnv
source ~/bin/gdal3  &> /dev/null 

find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr 
find  /dev/tmp/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
export RAM=/dev/shm
export var=$var

###### Corners4Gtranslate variables for getting the tile corners locations
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/
export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export filename=$(basename $file .tif  )
export tile=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

###### Variable trace in sterr and stdout
~/bin/echoerr "var ${var}  tile ${tile} IDarray ${SLURM_ARRAY_TASK_ID}"
echo    "var ${var}  tile ${tile} IDarray ${SLURM_ARRAY_TASK_ID}"

###### --------------------------------------------------------------------------------------------------------------
###### This script computes a weighted average of soil data across depths (0-200 cm) using six GeoTIFF input rasters.
###### Each layer is weighted by its depth range, summed, and divided by 200 cm.
###### The output is a compressed GeoTIFF file with depth-averaged values. 

export GDAL_CACHEMAX=6000
gdal_calc.py -A $DIR/$var/wgs84_250m_grow/${var}_0-5cm_${tile}.tif \
	     -B $DIR/$var/wgs84_250m_grow/${var}_5-15cm_${tile}.tif \
	     -C $DIR/$var/wgs84_250m_grow/${var}_15-30cm_${tile}.tif \
	     -D $DIR/$var/wgs84_250m_grow/${var}_30-60cm_${tile}.tif \
	     -E $DIR/$var/wgs84_250m_grow/${var}_60-100cm_${tile}.tif \
	     -F $DIR/$var/wgs84_250m_grow/${var}_100-200cm_${tile}.tif \
--format=GTiff   --outfile=$RAM/${var}_0-200cm_$tile.tif  --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=BIGTIFF=YES    --overwrite --NoDataValue=-32768   --type=Int16   \
           --calc="(      ((5      *  (A.astype(float))) + \
                           (10     *  (B.astype(float))) + \
                           (15     *  (C.astype(float))) + \
                           (30     *  (D.astype(float))) + \
                           (40     *  (E.astype(float))) + \
                           (100    *  (F.astype(float))))  \
                            / 200 )"

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/${var}_0-200cm_$tile.tif  $DIR/$var/wgs84_250m_grow/${var}_0-200cm_$tile.tif 


if [ $SLURM_ARRAY_TASK_ID -eq 116 ]; then
sleep 3000 

gdalbuildvrt -overwrite $DIR/$var/wgs84_250m_grow/${var}_0-200cm.vrt $DIR/$var/wgs84_250m_grow/${var}_0-200cm_h??v??.tif
		 
gdal_translate -tr 0.008333333333333333333333333 0.008333333333333333333333333  -r nearest  -co COMPRESS=LZW  -co ZLEVEL=9 $DIR/$var/wgs84_250m_grow/${var}_0-200cm.vrt  $DIR/$var/wgs84_250m_grow/${var}_0-200cm_1km.tif

fi
