#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 10 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_unzip.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_unzip.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget_unzip.sh

#  sbatch /gpfs/home/fas/sbsc/ga254/scripts/3DEP/sc01_wget_unzip.sh

export ZIP=/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/3DEP/zip
export TIF=/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/3DEP/tif

cd $ZIP

cat /project/fas/sbsc/ga254/dataproces/3DEP/list_zip.txt | xargs -n 1 -P 10  bash -c $'
file=$1
filename=$(basename $file .zip)
wget https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/1m/IMG/$file 
unzip -o  $file
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $filename.img $TIF/$filename.tif  
rm ${filename}*
rm $TIF/${filename}.tif.aux.xml
' _ 







