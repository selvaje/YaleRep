#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc40_rclone_SOILGRIDS_tograce.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc40_rclone_SOILGRIDS_tograce.sh.%J.err
#SBATCH --mem=5G
#SBATCH --job-name=sc40_rclone_SOILGRIDS_tograce.sh 
ulimit -c 0

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc40_rclone_SOILGRIDS_tograce.sh 

rclone copy   remote:dataproces/SOILGRIDS /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
