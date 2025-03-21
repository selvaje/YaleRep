#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc99_rclone_MERIT_HYDRO.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc99_rclone_MERIT_HYDRO.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc99_rclone_MERIT_HYDRO.sh
ulimit -c 0

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
rclone copy hydrography90m_v.1.0   remote:dataproces/MERIT_HYDRO/hydrography90m_v.1.0 






