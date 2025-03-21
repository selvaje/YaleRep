#!/bin/bash                                                                              
#SBATCH -p day
#SBATCH -n 1 -c 10 -N 1
#SBATCH -t 24:00:00                                                                                                         
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc02_merge_tiles_from_SOILGRIDS_SM.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc02_merge_tiles_from_SOILGRIDS_SM.sh.%J.err
#SBATCH --job-name=sc02_merge_tiles_from_SOILGRIDS_SM.sh                                              
#SBATCH --mem=50G

###### ==============================================[DESCRIPTION]========================================================
###### This script will merge the .tif tiles already downloaded using (/VSICURL/) from SoilGrids FTP server,
###### creating the single .vrt and then creating a single GTiff in 250m and 10km resoluion reprojected in EPSG:4326
###### --------------------------------------------------------------
###### tesinng mem per cpu instead of total mem : SBATCH --mem=50G
###### ===================================================================================================================

###### ==============================================[SBATCH LINE]========================================================
###### for var in clay sand silt ; do ; for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do ;
###### tifnumber=$(ll /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/${var}/homolosine_250m/${var}_${depth}_??.tif | wc -l ) ;
###### if [ $tifnumber -eq 4  ]  ; then ;  sbatch --job-name=sc02_${var}_${depth}_merge_tiles_from_SOILGRIDS_SM.sh
###### --export=var=$var,depth=$depth  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc02_merge_tiles_from_SOILGRIDS_SM.sh  ;
###### fi; done ; done
###### ==================================================================================================================== 

ulimit -c 0
module load StdEnv
source ~/bin/gdal3

###### import looping variables
export var=$var                               
export depth=$depth 

###### setting roots                                                                                                            
export pi_root=/gpfs/gibbs/pi/hydro/hydro/dataproces
export pj_root=/gpfs/gibbs/project/sbsc/sm3665/dataproces
export sc_root=/vast/palmer/scratch/sbsc/sm3665/dataproces

###### setting variables                                    
export INPUT=${pi_root}/SOILGRIDS2/${var}/homolosine_250m
export OUTPUTh250=${pi_root}/SOILGRIDS2/${var}/homolosine_250m
export OUTPUTw250=${pi_root}/SOILGRIDS2/${var}/wgs84_250m
export OUTPUTw10=${pi_root}/SOILGRIDS2/${var}/wgs84_10km
export GDAL_CACHEMAX=45000
export OMP_NUM_THREADS=10  # Set the number of OpenMP threads

###### ============================================================================
###### gdalbuildvrt to merge .tif files into a single .vrt file

if [ -f $OUTPUTh250/${var}_${depth}_mean.vrt ] ; then
    echo  $OUTPUTh250/${var}_${depth}_mean.vrt  already exist
else

echo MERGING VAR: ${var} DEPTH: ${depth}

gdalbuildvrt  -overwrite \
	      $OUTPUTh250/${var}_${depth}_mean.vrt $INPUT/${var}_${depth}_??.tif

echo GDALBUILDVRT COMPLETED

fi

###### ============================================================================
###### gdalwarp to convert the .vrt file to a single GTiff

mkdir -p $OUTPUTw250

if [ -f $OUTPUTw250/${var}_${depth}_mean_wgs84.tif ] ; then
    echo  $OUTPUTw250/${var}_${depth}_mean_wgs84.tif  already exist
else

gdalwarp -r nearest \
	 -te -180.0 -60.0 191.0 85.0 \
	 -tr 0.00208333333333333333333333333 0.00208333333333333333333333333 \
	 -overwrite \
	 -t_srs EPSG:4326 \
	 -co COMPRESS=DEFLATE \
	 -co ZLEVEL=9 \
	 -wo NUM_THREADS=10 \
	 -multi \
	 $OUTPUTh250/${var}_${depth}_mean.vrt\
	 $OUTPUTw250/${var}_${depth}_mean_wgs84.tif

echo GDALWARP COMPLETED

fi


###### ============================================================================
###### gdal_translate to create a downsampled 10km copy of the 250m tiff

mkdir -p $OUTPUTw10

if [ -f $OUTPUTw10/${var}_${depth}_mean_wgs84_10km.tif ] ; then
    echo  $OUTPUTw10/${var}_${depth}_mean_wgs84_10km.tif  already exist
else


gdal_translate -tr 0.08333333333333333333333333 0.08333333333333333333333333 \
	       -co COMPRESS=LZW\
	       -r nearest\
	       -co ZLEVEL=9 \
	       $OUTPUTw250/${var}_${depth}_mean_wgs84.tif $OUTPUTw10/${var}_${depth}_mean_wgs84_10km.tif
               #input 250m tif -> output 10km tif

echo GDALTRANSLATE COMPLETED

fi
