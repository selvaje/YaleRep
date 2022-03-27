#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 02:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_winter_refill.sh.%A.%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_winter_refill.sh.%A.%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_winter_refill.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/SNOWESA/sc03_winter_refill.sh

export DIR=/project/fas/sbsc/ga254/dataproces/SNOWESA/month



echo 11 12 01 02  | xargs -n 1  -P 4 bash -c $' 
pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/Snow_M03.tif  -msknodata 100 -nodata 100 -i $DIR/Snow_M$1.tif  -o $DIR/Snow_M${1}_fill.tif
gdal_edit.py  -a_nodata 255 $DIR/Snow_M${1}_fill.tif
' _ 


