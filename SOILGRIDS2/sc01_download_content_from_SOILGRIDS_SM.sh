#!/bin/bash                                      
#SBATCH -p transfer                                                                                                                
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00                                                                                                         
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc01_download_content_from_SOILGRIDS_SM.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc01_download_content_from_SOILGRIDS_SM.sh.%A_%a.err
#SBATCH --mem=20G
#SBATCH --array=1-4%2

##### ===================================================== [ SCRIPT INFO ] =================================================================
##### This script downloads the .vrt file  (/VSICURL/) from SoilGrids FTP server, reconverting it as GEOTiff and reprojecting it as EPSG:4326
##### =======================================================================================================================================

##### ================================================== [ TERMINAL LAUNCHING ] =============================================================
##### for var in clay sand silt ; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc01_download_${var}_${depth}_content_from_SOILGR
##### IDS_SM.sh  --export=var=$var,depth=$depth  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc01_download_content_from_SOILGRIDS_SM.sh  ;  done ;  done 
##### =======================================================================================================================================

##### ===================================================== [ DATASET INFO ] ================================================================
##### DOWNLOADED
##### [var]: sand silt clay bdod                                     [depth]: 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm 
##### NOT DOWNLOADED:
##### [var]: cec cfvo nitrogen ocd phh2o soc                         [depth]: 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm
##### [var]: ocs                                                     [depth]: 0-30cm 
##### [var]: wrb                                                     [depth]: sub-variables needs to be treated separately
##### =======================================================================================================================================

ulimit -c 0
module load StdEnv
source ~/bin/gdal3

export var=$var     #### Just to be sure that looping variables are imported in the sbatch
export depth=$depth #### Just to be sure that looping variables are imported in the sbatch                                                                                             
export INPUT_URL=/vsicurl/https://files.isric.org/soilgrids/latest/data
export OUTPUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2

#####              X      Y
##### full Size: 159246  58034
##### half size: 79623   29017
##### -srcwin xoff yoff xsize ysize 

if [  $SLURM_ARRAY_TASK_ID = 1    ] ;  then xoff=0     yoff=0     xsize=79623 ysize=29017 ; tile=UL   ; fi
if [  $SLURM_ARRAY_TASK_ID = 2    ] ;  then xoff=0     yoff=29017 xsize=79623 ysize=29017 ; tile=LL   ; fi
if [  $SLURM_ARRAY_TASK_ID = 3    ] ;  then xoff=79623 yoff=0     xsize=79623 ysize=29017 ; tile=UR   ; fi
if [  $SLURM_ARRAY_TASK_ID = 4    ] ;  then xoff=79623 yoff=29017 xsize=79623 ysize=29017 ; tile=LR   ; fi

echo "VAR: $var TILE: $tile DEPTH: $depth  Content - SOILGRIDS2 (.vrt GDAL_translate operation)"

export GDAL_HTTP_TIMEOUT=300
export GDAL_HTTP_MAX_RETRY=5
export GDAL_CACHEMAX=10000

##### GDAL TRANSLATE FOR TILING THE MAP FROM THE FTP SERVER 

mkdir -p $OUTPUT/$var/homolosine_250m

if [ -e           $OUTPUT/$var/homolosine_250m/${var}_${depth}_${tile}.tif ] ; then
    echo the file $OUTPUT/$var/homolosine_250m/${var}_${depth}_${tile}.tif already exist 
else 
    gdal_translate --debug on\
		   -co GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR\
		   -srcwin $xoff $yoff $xsize $ysize\
		   -co BIGTIFF=YES\
		   -co COMPRESS=DEFLATE\
		   -co ZLEVEL=9\
		   -of GTiff\
		   $INPUT_URL/$var/${var}_${depth}_mean.vrt\
		   $OUTPUT/$var/homolosine_250m/${var}_${depth}_${tile}.tif

fi 

exit

if [ $SLURM_ARRAY_TASK_ID -eq 3 ]; then
    ##### Get the job ID of the current job
    current_jobid=$(squeue -u $USER -o "%.9i %.100j" | grep sc01_download_${var}_${depth}_content_from_SOILGRIDS_SM.sh | awk '{print $1}' | tr '\n' ':' | sed 's/:$//')
    ##### Submit the next job with a dependency on the current job
    sleep 600 
    sbatch --export=var=$var,depth=$depth \
	   --dependency=afterany:${current_jobid} /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc02_merge_tiles_from_SOILGRIDS_SM.sh
fi



#  if surlm n_array = 4 ; then 

#  sbatch --afterany=sc01_download_${var}_${depth}_content_from_SOILGRIDS.sh   /vast/palmer/home.grace/sm3665/scripts/download/sc02_merge_tiles_from_SOILGRIDS.sh




#fi

##### FIX il check del job id, se è ancora pending (quindi è sulla queue) non lanciare il sc02 (gdalwarp)
##### il nome del gdalwarp sc02 va parametrizzato, e deve prendersi usando l'export le variabili $var $depth
