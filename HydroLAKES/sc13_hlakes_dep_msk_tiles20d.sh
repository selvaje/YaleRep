#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc13_hlakes_dep_msk_tiles20d.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc13_hlakes_dep_msk_tiles20d.sh.%A_%a.err
#SBATCH --job-name=sc13_hlakes_dep_msk_tiles20d.sh
#SBATCH --mem=30G
#SBATCH --array=1-116

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc13_hlakes_dep_msk_tiles20d.sh

source ~/bin/gdal3
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export RAM=/dev/shm
export SCMH=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=10000

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Int32 -a_nodata 0 -projwin $(getCorners4Gtranslate $file) $MERIT/dep/all_tif_dis.vrt                 $RAM/MERITdep_${tile}_msk.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Int32 -a_nodata 0 -projwin $(getCorners4Gtranslate $file) $DIR/tif_ID/all_tif_HydroLAKES_dep_rec.vrt $RAM/HydroLAKES_${tile}_msk.tif 

gdalbuildvrt  -overwrite  -srcnodata 0 -vrtnodata 0   $RAM/MERITdep_HydroLAKES_${tile}_msk.vrt   $RAM/MERITdep_${tile}_msk.tif  $RAM/HydroLAKES_${tile}_msk.tif

pksetmask -ot Byte -of GTiff  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $RAM/MERITdep_HydroLAKES_${tile}_msk.vrt   -p '>'   -msknodata 0.5 -nodata 1 \
-i $RAM/MERITdep_HydroLAKES_${tile}_msk.vrt   -o  $SCMH/dep_lakes_final20d_1p/dep_${tile}.tif
gdal_edit.py -a_nodata 0 $SCMH/dep_lakes_final20d_1p/dep_${tile}.tif

rm -f $RAM/MERITdep_${tile}_msk.tif $RAM/HydroLAKES_${tile}_msk.tif $RAM/MERITdep_HydroLAKES_${tile}_msk.vrt 

MAX=$(pkstat -max  -i $SCMH/dep_lakes_final20d_1p/dep_${tile}.tif    | awk '{ print int($2)  }' )
if [ $MAX -eq  0  ] ; then
rm -f $SCMH/dep_lakes_final20d_1p/dep_${tile}.tif
fi 

