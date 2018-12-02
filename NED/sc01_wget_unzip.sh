#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_unzip.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_unzip.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget_unzip.sh

#  sbatch /gpfs/home/fas/sbsc/ga254/scripts/NED/sc01_wget_unzip.sh

export ZIP=/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/NED/zip
export TIF=/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/NED/tif

cd $ZIP

curl -l  ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/ > /tmp/list.txt 
cat  /tmp/list.txt | grep zip | grep USGS | grep "("      > /tmp/list_zip_USGS1.txt 
cat  /tmp/list.txt | grep zip | grep USGS | grep -v "("   > /tmp/list_zip_USGS2.txt 
cat  /tmp/list.txt | grep zip | grep -v USGS              > /tmp/list_zip_NOUSGS.txt 

wget "ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/USGS_NED_1_n71w148_IMG (2).zip" 
wget "ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/USGS_NED_1_n71w149_IMG (2).zip"
wget "ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/USGS_NED_1_n58w135_IMG (2).zip"

unzip USGS_NED_1_n71w148_IMG\ \(2\).zip
unzip USGS_NED_1_n71w149_IMG\ \(2\).zip
unzip USGS_NED_1_n58w135_IMG\ \(2\).zip

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  USGS_NED_1_n71w148_IMG.img $TIF/n71w148.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  USGS_NED_1_n71w149_IMG.img $TIF/n71w149.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  USGS_NED_1_n58w135_IMG.img $TIF/n58w135.tif 

rm -r $TIF/n*w*.tif.aux.xml    $ZIP/* 


cat /tmp/list_zip_USGS2.txt | xargs -n 1 -P 12  bash -c $'
file=$1
filename=$(basename $file .zip)
wget ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/$file
unzip -o  $file
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $filename.img $TIF/${filename:11:7}.tif  
rm $ZIP/${filename}*
rm $TIF/${filename:11:7}.tif.aux.xml
rm -r $ZIP/${filename:11:7}
' _ 


cat /tmp/list_zip_NOUSGS.txt    | xargs -n 1 -P 10  bash -c $'
file=$1
filename=$(basename $file .zip)
wget ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/NED/1/IMG/$file
unzip -o  $file
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 img${filename}_1.img $TIF/${filename}.tif  
rm $ZIP/*${filename}* 
rm $TIF/${filename}.tif.aux.xml
rm -r $ZIP/${filename}
' _ 

rm /tmp/list_zip_*.txt  $ZIP/*.url  $ZIP/*.pdf  $ZIP/ned_1arcsec_g.*

gdalbuildvrt   -allow_projection_difference  -overwrite  $TIF/all_tif.vrt $TIF/*.tif 

exit 

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NED/sc02_gdalwarp.sh 
