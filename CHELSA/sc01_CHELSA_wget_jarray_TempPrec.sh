#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 00:30:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_CHELSA_wget_jarray_TempPrec.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_CHELSA_wget_jarray_TempPrec.sh.%A_%a.err
#SBATCH --mem-per-cpu=2000M
#SBATCH --array=1-1680%10

###############  1-1680

module purge 
source ~/bin/gdal   


####  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/CHELSA/sc01_CHELSA_wget_jarray_TempPrec.sh  
####  for VAR in prec tmax tmin tmean; do for YEAR in {1979..2013} ; do for MES in {01..12} ; do echo $VAR ${YEAR} ${MES} ; done ; done ; done > /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_list.txt  
   
LINE=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_list.txt   | head -n $SLURM_ARRAY_TASK_ID | tail -1 )

VAR=$(echo $LINE | awk '{ print $1 }' )
YEAR=$(echo $LINE | awk '{ print $2 }' )
MES=$(echo $LINE | awk '{ print $3 }' )

#### the following variables have one layer per month

###  Monthly precipitation  ---  "CHELSA_prec_"
###  Max. temperature  ---  "CHELSA_tmax_"
###  Min. temperature  ---  "CHELSA_tmin_"
###  Mean temperature  ---  "CHELSA_tmean_"

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA 
cd $INDIR/$VAR

wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_${MES}_V1.2.1.tif
gdal_edit.py -a_nodata 65535  -a_ullr -180  84 180 -90 -a_srs EPSG:4326  $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_${MES}_V1.2.1.tif 

 



