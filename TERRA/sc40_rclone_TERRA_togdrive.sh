#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc40_rclone_TERRA.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc40_rclone_TERRA.sh.%J.err
#SBATCH --mem=5G
#SBATCH --job-name=sc40_rclone_TERRA.sh
ulimit -c 0

module load Rclone/1.53.0 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
rclone copy ppt_acc   remote:dataproces/TERRA_G/ppt_acc






