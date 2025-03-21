#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc45_SE_data_prep.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc45_SE_data_prep.sh.%J.err
#SBATCH --job-name=sc45_SE_data_prep.sh
#SBATCH --mem=5G

source ~/bin/pktools

# cp /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/eu_x_y_hight_predictors_select.txt /vast/palmer/home.grace/ga254/SE_data/exercise/tree_height/txt/eu_x_y_height_predictors_select.txt

SE=/vast/palmer/home.grace/ga254/SE_data/exercise/tree_height

# rm -f $SE/geodata_vector/eu_x_y_height.gpkg
# awk '{print $1 ,  $2 , $3}'                       $SE/txt/eu_x_y_height_predictors_select.txt > $SE/txt/eu_x_y_height.txt
# pkascii2ogr -f GPKG -a_srs EPSG:4326 -n "height" -ot Real  -i $SE/txt/eu_x_y_height.txt   -o $SE/geodata_vector/eu_x_y_height.gpkg


export EU=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe

echo min med max | xargs -n 1 -P 3 bash -c $' 
var=$1
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/glad_ard/glad_ard_SVVI_$var.tif       -o  $SE/geodata_raster/glad_ard_SVVI_${var}_msk.tif
' _

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/treecover2000/treecover.tif          -o  $SE/geodata_raster/treecover.tif


pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/Forest_height/Forest_height_2019.tif  -o  $SE/geodata_raster/forestheight.tif

# chelsa 
# # BIO 18 Precipitation of Warmest Quarter (mm)
# # BIO 04 Temperature Seasonality (standard deviation * 100)

echo CHELSA_bio4 CHELSA_bio18 | xargs -n 1 -P 2 bash -c $' 
file=$1
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/chelsa/$file.tif               -o  $SE/geodata_raster/$file.tif 
' _

# geomorpho90m
# # dev.magnitude
# # convergence
# # northness 
# # eastness
# # elev

echo dev.magnitude convergence northness eastness elev |  xargs -n 1 -P 3 bash -c $' 
file=$1
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/geomorpho90m/$file.tif               -o  $SE/geodata_raster/$file.tif 
' _

# hydrography90m
# outlet_dist_dw_basin
# cti 


file=outlet_dist_dw_basin
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/hydrography90m/$file.tif               -o  $SE/geodata_raster/$file.tif 

file=cti
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -2147483648 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -2147483648 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -2147483648 \
-i  $EU/hydrography90m/$file.tif               -o  $SE/geodata_raster/$file.tif 

# soilgrids
## BLDFIE_WeigAver    BLDFIE : Bulk density (fine earth) in kg / cubic-meter at depth 
## ORCDRC_WeigAver    ORCDRC : Soil organic carbon content (fine earth fraction) in g per kg at depth
## CECSOL_WeigAver    CECSOL : Cation exchange capacity of soil in cmolc/kg at depth

echo BLDFIE_WeigAver ORCDRC_WeigAver CECSOL_WeigAver |  xargs -n 1 -P 2 bash -c $' 
file=$1
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata 65535 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata 65535 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata 65535 \
-i  $EU/soilgrids/$file.tif               -o  $SE/geodata_raster/$file.tif 
' _

# soiltemp
# "SBIO4_Temperature_Seasonality_5_15cm"
# "SBIO3_Isothermality_5_15cm"

echo SBIO4_Temperature_Seasonality_5_15cm SBIO3_Isothermality_5_15cm |  xargs -n 1 -P 2 bash -c $' 
file=$1
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  $EU/glad_ard/glad_ard_all_min6_msk01.tif  -msknodata 0  -nodata -9999 \
-m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0  -nodata -9999 \
-m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0  -nodata -9999 \
-i  $EU/soilgrids/$file.tif                   -o $SE/geodata_raster/$file.tif 
' _
