#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_wget.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/LCESA/sc01_wget.sh

cd /project/fas/sbsc/ga254/dataproces/LCESA/input 

for YEAR in $(seq 1992 2015 ) ;  do 
    wget  ftp://geo10.elie.ucl.ac.be/v207/ESACCI-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.0.7.tif
done 



