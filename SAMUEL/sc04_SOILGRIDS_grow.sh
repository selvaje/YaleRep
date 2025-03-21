#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/sc04_SOILGRIDS_grow.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/sc04_SOILGRIDS_grow.sh.%A_%a.err
#SBATCH --job-name=sc04_SOILGRIDS_grow.sh
#SBATCH --mem-per-cpu=20G
#SBATCH --array=1-116

###### ==============================================[SBATCH LINE]========================================================
###### for var in clay sand silt ; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch
###### --job-name=sc04_SOILGRIDS_grow_${var}_${depth}.sh --export=var=$var,depth=$depth
###### /vast/palmer/home.grace/sm3665/scripts/download/sc04_SOILGRIDS_grow.sh ; done ; done
###### ===================================================================================================================

###### =================================================[DEBUG LINE]=========================================================
###### SCRIPT FOR GETTING A LIST OF ALL KILLED JOBS TILE 
###### grep Warn -B 2  /vast/palmer/scratch/sbsc/sm3665/stderr/sc04_SOILGRIDS_grow.sh.*.err | grep 60-100 | awk '{printf "%s," ,$8}'
###### 

############## RAM cleaner [file older than N days]
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr 
find  /dev/tmp/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr

############### tool calling
source ~/bin/gdal3

############### import looping variables 
export var=$var
export depth=$depth

############### setting roots
###### group pi remote storage root
#export pi_root=/gpfs/gibbs/pi/hydro/hydro/dataproces
###### personal project root
#export pj_root=/gpfs/gibbs/project/sbsc/sm3665/dataproces
###### testing scratch root
#export sc_root=/vast/palmer/scratch/sbsc/sm3665/dataproces


export pi_root=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess

#export pj_root=/gpfs/gibbs/project/sbsc/sm3665/dataproces

export sc_root=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess


############### setting variables
###### working variables
export DIR=${pi_root}/${var}/transposing
export OUTDIR=${sc_root}/${var}/wgs84_250m_grow
export RAM=/dev/shm
GDAL_CACHEMAX=15000
export input_vrt=${DIR}/${var}_${depth}_mean_wgs84_trasp.vrt

mkdir -p $OUTDIR
###### Corners4Gtranslate variables for getting the tile corners locations
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/
export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export filename=$(basename $file .tif  )
export tile=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

###### Variable trace in sterr and stdout
/home/sm3665/bin/echoerr "var ${var} depth ${depth} tile ${tile} IDarray ${SLURM_ARRAY_TASK_ID}"
echo "var ${var} depth ${depth} tile ${tile} IDarray ${SLURM_ARRAY_TASK_ID}"

############### WORKFLOW
###### 1 - GDAL_translate with file extenson clipping
gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2 }') \
	       -co COMPRESS=DEFLATE \
	       -co ZLEVEL=9 \
	       $input_vrt\
	       ${RAM}/${var}_${depth}_trans_${tile}.tif

###### 2 - GDAL_fillnodata.py for filling nodata
gdal_fillnodata.py -co COMPRESS=DEFLATE \
		   -co ZLEVEL=9 \
		   -md 4000 \
		   -si 1 \
		   ${RAM}/${var}_${depth}_trans_${tile}.tif\
		   ${RAM}/${var}_${depth}_trans_${tile}_tmp.tif

###### 3 - GDAL_translate with final clipping
gdal_translate -projwin $(getCorners4Gtranslate $file) \
	       -co COMPRESS=DEFLATE \
	       -co ZLEVEL=9 \
	       ${RAM}/${var}_${depth}_trans_${tile}_tmp.tif\
	       $OUTDIR/${var}_${depth}_${tile}.tif

###### 4 - tmp files cleaning
rm $RAM/${var}_${depth}_trans_${tile}.tif
rm $RAM/${var}_${depth}_trans_${tile}_tmp.tif

###### 5 - next job call
if [ $SLURM_ARRAY_TASK_ID -eq 116 ]; then
    echo "[ All tasks completed.]"
fi
