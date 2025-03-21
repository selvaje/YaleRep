#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 7-00:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc40_rclone_ESALC_tograce.sh.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc40_rclone_ESALC_tograce.sh.sh.%J.err
#SBATCH --mem=5G
#SBATCH --job-name=sc40_rclone_ESALC_tograce.sh
ulimit -c 0

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc40_rclone_ESALC_tograce.sh

rclone copy   remote:dataproces/ESALC  /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC







