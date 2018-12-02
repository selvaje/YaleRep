
# source https://cgiarcsi.community/data/global-aridity-and-pet-database/ 


cd /project/fas/sbsc/ga254/dataproces/PET_ARID/ARIDITY/

wget https://www.dropbox.com/sh/e5is592zafvovwf/AACSS163OQ2nm5m1jmlZk4Gva/Global%20PET%20and%20Aridity%20Index/Global%20Aridity%20-%20Annual.zip 


pksetmask -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m   AI_annual/ai_yr   -msknodata  -2147483647 -nodata -1 -i   AI_annual/ai_yr   -o     AI_annual.tif 
gdal_edit.py -a_ullr  -180 90 180 -60  AI_annual.tif  



cd /project/fas/sbsc/ga254/dataproces/PET_ARID/PET
wget https://www.dropbox.com/sh/e5is592zafvovwf/AAB-D21XrVb3A5IxG5oT5Oooa/Global%20PET%20and%20Aridity%20Index/Global%20PET%20-%20Monthly.zip?dl=0

unzip "Global PET - Monthly.zip?dl=0"

ls PET_he_monthly/pet_he_*/w001001.adf | xargs -n 1 -P 6  bash -c $' 
file=$1 
filename=$( basename $( dirname  $file   ) ) 
gdalbuildvrt  -overwrite   $filename.vrt $file 
gdal_translate  -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9    $filename.vrt    $filename.tif 
gdal_edit.py -a_ullr  -180 90 180 -60   $filename.tif 

' _ 
