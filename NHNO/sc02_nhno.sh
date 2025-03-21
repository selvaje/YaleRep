#!/bin/bash
#SBATCH --job-name=sc02_nhno.sh
#SBATCH --ntasks=1 --nodes=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_nhno.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_nhno.sh.%J.err
#SBATCH --array=1-1200

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/NHNO/sc02_nhno.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/NHNO/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHNO/sc02_nhno.sh

####  for VAR in NH4 NO3;  do for YEAR in {1961..2010} ; do for MES in {01..12} ; do echo $VAR ${YEAR} ${MES} ; done ; done ; done> /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/job_array_list.txt

####  for VAR in NH NO; do for BAND in {1..600}; do echo ${VAR} ${BAND}; done ; done | awk '{ print $2 }' > /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/band_array_list.txt

####  mkdir NH4 NO3

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO

LINE=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/job_array_list.txt   | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
#LINE=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/job_array_list.txt   | head -n 1 | tail -1 )

BAND=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/band_array_list.txt | head -n $SLURM_ARRAY_TASK_ID | tail -1  )
#BAND=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO/band_array_list.txt | head -n 1 | tail -1  )

VAR=$(echo $LINE | awk '{ print $1 }' )
YEAR=$(echo $LINE | awk '{ print $2 }' )
MES=$(echo $LINE | awk '{ print $3 }' )

gdal_translate -of GTiff -b $BAND -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 ${DIR}/FAOSTAT_ver1/${VAR}_input_ver1.nc4 ${DIR}/${VAR}/${VAR}_${YEAR}_${MES}.tif
