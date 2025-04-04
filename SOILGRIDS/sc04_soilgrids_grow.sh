#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc04_soilgrids_grow.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc04_soilgrids_grow.sh.%A_%a.err
#SBATCH --job-name=sc04_soilgrids_grow.sh
#SBATCH --mem-per-cpu=30G
#SBATCH --array=1-116

#######1-116
# for var in  SLTPPT_WeAv CLYPPT_WeAv SNDPPT_WeAv WWP_WeAv AWCtS_WeAv  ; do  sbatch --export=var=$var /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc04_soilgrids_grow.sh ; done  

source ~/bin/gdal3

#### SLURM_ARRAY_TASK_ID=7
#### var=SLTPPT_WeAv

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
export NAM=$( echo $var | awk '{ gsub ("_"," " ) ; print $1  }'  )

export RAM=/dev/shm
GDAL_CACHEMAX=15000

export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/
export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export tile=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

echoerr ${NAM}_trans_$tile.tif 

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/out_TranspGrow/${NAM}_WeigAver_trans.tif $RAM/${NAM}_trans_$tile.tif 

gdal_fillnodata.py  -co COMPRESS=DEFLATE -co ZLEVEL=9   -md 4000  -si 1  $RAM/${NAM}_trans_$tile.tif $RAM/${NAM}_trans_${tile}_tmp.tif
gdal_translate  -projwin $(getCorners4Gtranslate $file)     -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/${NAM}_trans_${tile}_tmp.tif   $DIR/${var}_tiles20d/${var}_${tile}.tif
###  remove temporal files
rm -f $RAM/${NAM}_trans_$tile.tif   $RAM/${NAM}_trans_$tile.tif 


if [ $SLURM_ARRAY_TASK_ID -eq 116   ] ; then
sleep 3000 
GDAL_CACHEMAX=20000
gdalbuildvrt -overwrite -srcnodata 65535  -vrtnodata 65535 $DIR/${var}_tiles20d/${var}_transGrow.vrt    $DIR/${var}_tiles20d/${var}_h??v??.tif 
gdal_translate -a_nodata 65535  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r nearest  -tr 0.0083333333333 0.0083333333333 $DIR/${var}_tiles20d/${var}_transGrow.vrt  $DIR/${var}_tiles20d/${var}_transGrow_1km.tif
fi


