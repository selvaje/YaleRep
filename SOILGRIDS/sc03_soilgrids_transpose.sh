#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc03_soilgrids_transpose.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc03_soilgrids_transpose.sh.%J.err
#SBATCH --job-name=sc03_soilgrids_transpose.sh
#SBATCH --mem-per-cpu=20G

# for var in  SLTPPT_WeAv CLYPPT_WeAv SNDPPT_WeAv WWP_WeAv AWCtS_WeAv  ; do  sbatch --export=var=$var /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc03_soilgrids_transpose.sh ; done  

source ~/bin/gdal3
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS

export FOLDER=$var
export VAR=$( ls $DIR/$FOLDER )
export NAM=$( basename $VAR .tif )
export NAsource=$( gdalinfo $DIR/$FOLDER/$VAR | grep "NoData" | awk -F "=" '{ print $2   }' )
export RAM=/dev/shm
GDAL_CACHEMAX=16000


#####    FIRST   ###############
#### ... Prepare the tile with the transposed peninsula
echo ------
echo First : Prepare the tile with the transposed peninsula
echo ------

##  CUT
gdal_translate  -of VRT  -projwin  -180 75 -169 60 $DIR/$FOLDER/$VAR  $RAM/${NAM}_cropwest.vrt

##  MASK
pksetmask -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/displacement/camp.tif  -msknodata 0 -nodata ${NAsource} -i $RAM/${NAM}_cropwest.vrt  -o $RAM/${NAM}_transpose2east.tif

##  TRANSPOSE
gdal_edit.py  -a_ullr 180 75 191 60 $RAM/${NAM}_transpose2east.tif

#####    SECOND   ###############
####   split the global coverage into four tiles
echo ------
echo SECOND:split the global coverage into four tiles
echo ------

echo  BUILDVRT 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 85  -169  60 ${DIR}/${FOLDER}/${VAR}  ${RAM}/${NAM}_ta.vrt   # upper left
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -169 85   180  60 ${DIR}/${FOLDER}/${VAR}  ${RAM}/${NAM}_tb.vrt   # upper center right 
gdal_translate -a_nodata ${NAsource}  -of VRT -projwin  -180 60   180 -60 ${DIR}/${FOLDER}/${VAR}  ${RAM}/${NAM}_tc.vrt   # lower left   center right 

####   Take tile a and mask (remove) the peninsula (amsk.tif)
echo ------
echo  Take tile a and mask the peninsula
echo ------

pksetmask -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/displacement/camp.tif -msknodata 1 -nodata ${NAsource} -i ${RAM}/${NAM}_ta.vrt -o ${RAM}/${NAM}_ta_msk.tif

#####   THIRD   ###############
## merge
echo ------
echo merge all vrts
echo ------

gdalbuildvrt -srcnodata ${NAsource} -vrtnodata ${NAsource} -te -180 -60 191 85 $RAM/${NAM}.vrt ${RAM}/${NAM}_ta_msk.tif $RAM/${NAM}_t{b,c}.vrt  $RAM/${NAM}_transpose2east.tif
gdal_translate      -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/${NAM}.vrt   $DIR/out_TranspGrow/${NAM}_trans.tif
rm -f ${RAM}/*

