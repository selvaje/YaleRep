#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/SNOWESA/sc01_wget.sh

#   download at http://maps.elie.ucl.ac.be/CCI/viewer/download.php 

cd /project/fas/sbsc/ga254/dataproces/SNOWESA/input 

# wget ftp://geo10.elie.ucl.ac.be/CCI/ESACCI-LC-L4-Snow-Cond-500m-P13Y7D-2000-2012-v2.0.tif.7z 
rm -f *.tif 
7za e      ESACCI-LC-L4-Snow-Cond-500m-P13Y7D-2000-2012-v2.0.tif.7z  -mx1 -mmt=6 -m0=lzma2 
