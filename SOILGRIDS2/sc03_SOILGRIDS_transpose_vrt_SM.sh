#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH --cpus-per-task=1
#SBATCH -t 10:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc03_SOILGRIDS_transpose_vrt_SM.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc03_SOILGRIDS_transpose_vrt_SM.sh.%J.err
#SBATCH --mem-per-cpu=30G

###### ==============================================[SBATCH LINE]========================================================
###### for var in clay sand silt ; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc03_SOILGRIDS_transpose_vrt_${var}_${depth}.sh --export=var=$var,depth=$depth  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc03_SOILGRIDS_transpose_vrt_SM.sh  ;  done ;  done
###### ===================================================================================================================       


###### ----------------------- 0 -----------------------
###### variable settings

source ~/bin/gdal3
source ~/bin/pktools
###### import looping variables
export var=$var                                                                                      
export depth=$depth
###### setting roots
export pi_root=/gpfs/gibbs/pi/hydro/hydro/dataproces
export pj_root=/gpfs/gibbs/project/sbsc/sm3665/dataproces #for testing only
export sc_root=/vast/palmer/scratch/sbsc/sm3665/dataproces #for testing only
###### setting variables
export DIR=${pi_root}/SOILGRIDS2/${var}/wgs84_250m
export DIR10=${pi_root}/SOILGRIDS2/${var}/wgs84_10km
export OUT=${pi_root}/SOILGRIDS2/${var}/transposing
export VAR=${var}_${depth}_mean_wgs84.tif
export NAM=${var}_${depth}_mean_wgs84
export NAsource=$(gdalinfo $DIR/$VAR | grep "NoData" | awk -F "=" '{ print $2 }')
export RAM=/dev/shm
GDAL_CACHEMAX=20000

###### ----------------------- 1 -----------------------
###### Prepare the tile with the transposed peninsula

mkdir -p $OUT

echo "VAR: $var DEPTH: $depth  Content - SOILGRIDS2 transposing operation"

###### CUT
echo cutting

gdal_translate  -of VRT  -projwin  -180 75 -169 60 $DIR/$VAR  $RAM/${NAM}_cropwest.vrt

###### MASK
echo masking

pksetmask -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9\
	  -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/displacement/camp.tif\
	  -msknodata 0\
	  -nodata ${NAsource}\
	  -i $RAM/${NAM}_cropwest.vrt\
	  -o $OUT/${NAM}_cropwest.tif 

###### TRANSPOSE
echo transposing 

gdal_translate    -a_ullr 180 75 191 60  $OUT/${NAM}_cropwest.tif  $OUT/${NAM}_transpose2east.tif

###### ----------------------- 2 -----------------------
###### SPLIT
echo Splitting

echo  BUILDVRT 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 85  -169  60 ${DIR}/${VAR}  ${RAM}/${NAM}_ta.vrt
###### upper left
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -169 85   180  60 ${DIR}/${VAR}  ${RAM}/${NAM}_tb.vrt
###### upper center right 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 60   180 -60 ${DIR}/${VAR}  ${RAM}/${NAM}_tc.vrt
###### lower left   center right 

###### ----------------------- 3 -----------------------
echo 'Taking tile a and mask remove  the peninsula mask.tif'

pksetmask -of GTiff   -co COMPRESS=DEFLATE\
	  -co ZLEVEL=9\
	  -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/displacement/camp.tif\
	  -msknodata 1\
	  -nodata ${NAsource}\
	  -i ${RAM}/${NAM}_ta.vrt\
	  -o ${RAM}/${NAM}_ta_msk.tif

##### ----------------------- 4 -----------------------
echo Merge all vrts with gdalbuildvrt

gdalbuildvrt -srcnodata ${NAsource}\
	     -vrtnodata ${NAsource}\
	     -te -180 -60 180 85\
	     $RAM/${NAM}.vrt ${RAM}/${NAM}_ta_msk.tif $RAM/${NAM}_t{b,c}.vrt  


##### ----------------------- 5 -----------------------
##### gdal_translate to create a downsampled copy of the GTiff
##### input 250m tif -> output 10km tif

echo 10km transposed .tif file creted

echo "250m transposed .tif file creted"
gdal_translate -co COMPRESS=DEFLATE\
	       -co ZLEVEL=9\
	       $RAM/${NAM}.vrt   $OUT/${NAM}_body.tif  

##### creating global .vrt no-transpose

gdalbuildvrt -srcnodata ${NAsource}\
             -vrtnodata ${NAsource}\
              $OUT/${NAM}_notrasp.vrt  \
              $OUT/${NAM}_body.tif $OUT/${NAM}_cropwest.tif

gdal_translate -tr 0.08333333333333333333333333 0.08333333333333333333333333 \
               -co COMPRESS=LZW\
               -r nearest\
               -co ZLEVEL=9 \
               $OUT/${NAM}_notrasp.vrt   $OUT/${NAM}_notrasp_10km.tif 

##### creating global .vrt transpose                                                                                                                                                

gdalbuildvrt -srcnodata ${NAsource}\
             -vrtnodata ${NAsource}\
              $OUT/${NAM}_trasp.vrt  \
              $OUT/${NAM}_body.tif $OUT/${NAM}_transpose2east.tif 

gdal_translate -tr 0.08333333333333333333333333 0.08333333333333333333333333 \
               -co COMPRESS=LZW\
               -r nearest\
               -co ZLEVEL=9 \
               $OUT/${NAM}_trasp.vrt   $OUT/${NAM}_trasp_10km.tif 

rm -f ${RAM}/*
