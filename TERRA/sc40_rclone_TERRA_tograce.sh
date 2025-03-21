#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 07-0:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc40_rclone_TERRA_tograce.sh.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc40_rclone_TERRA_tograce.sh.sh.%J.err
#SBATCH --mem=5G
#SBATCH --job-name=sc40_rclone_TERRA_tograce.sh
ulimit -c 0

rclone copy   remote:dataproces/TERRA_G/tmin_acc /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/tmin_acc
rclone copy   remote:dataproces/TERRA_G/tmax_acc /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/tmax_acc
rclone copy   remote:dataproces/TERRA_G/soil_acc /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc

#### tmin_1976_03_h22v08_acc.nd 




