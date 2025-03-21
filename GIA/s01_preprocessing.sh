#!/bin/bash 

source ~/bin/gdal
source ~/bin/pktools 

# wget https://store.pangaea.de/Publications/MeierJ-etal_2017/global_irrigated_areas.zip

dirIn=/home/sbsc/ls732/DataSets/GIA/global_irrigated_areas
dirOut=/home/sbsc/ls732/DataSets/GIA/global_irrigated_areas

tifOri=global_irrigated_areas.tif
tifProc=global_irrigated_areas_4c.tif
tifBin=global_irrigated_areas_bin.tif

# to get the corners for gdal_translate
#getCorners4Gtranslate ${dirIn}/${tifOri}

# note : original geo ref incorrect

#gdal_translate  -ot Byte -a_nodata 0 -a_srs EPSG:4326 -a_ullr -180 90 180 -60 -co COMPRESS=DEFLATE -co ZLEVEL=9 ${dirIn}/${tifOri} ${dirIn}/${tifProc} 

#rm ${dirIn}/*.tfw ${dirIn}/*.ovr ${dirIn}/${tifOri} ${dirIn}/README

# binarisation 

pkgetmask -i ${dirIn}/${tifProc} -o ${dirOut}/${tifBin}  -min -1 -max 0.5  -nodata 1 -data 0 -co COMPRESS=DEFLATE -co ZLEVEL=9

#copied from README 

# Legend: 
# 0 = no irrigated area
# 1 = downscaled Siebert et al. 2013
# 2 = low agricultural suitability, high NDVI and NDVI course of vegetation
# 3 = potential multiple cropping < actual multiple cropping
# 4 = classified as cropland (according to ESA-CCI-LC and GlobCover) and low suitability

# Class 1-4 shows irrigated areas, detected by different methods.
