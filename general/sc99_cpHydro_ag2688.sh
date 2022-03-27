#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc99_cpHydro.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc99_cpHydro.sh.%J.err
#SBATCH --mem=10G
#SBATCH --job-name=sc99_cpHydro.sh


# sbatch sc99_cpHydro.sh 

ulimit -c 0


rsync --recursive /project/fas/sbsc/ag2688    /gpfs/gibbs/pi/hydro/ 

  






