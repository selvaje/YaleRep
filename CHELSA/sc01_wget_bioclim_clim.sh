#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_bioclim_clim.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_bioclim_clim.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget_prec.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc01_wget_bioclim_clim.sh
# data range 1979 2013

for VAR in  01 02 03 04 05 06 07 08 09 $(seq 10 19 )  ; do 
cd /project/fas/sbsc/ga254/dataproces/CHELSA/bio$( expr ${VAR}  \* 1 )_clim

export VAR

wget  https://www.wsl.ch/lud/chelsa/data/bioclim/integer/CHELSA_bio10_${VAR}_land.7z  
7za e CHELSA_bio10_${VAR}_land.7z  

gdal_translate  -a_ullr -180 84 180 -90      -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   CHELSA_bio10_$( expr ${VAR}  \* 1  ).tif     CHELSA_bio10_$( expr ${VAR}  \* 1  )_c.tif  
mv  CHELSA_bio10_$( expr ${VAR}  \* 1  )_c.tif     CHELSA_bio10_$( expr ${VAR}  \* 1  ).tif  
rm CHELSA_bio10_${VAR}_land.7z 

done

