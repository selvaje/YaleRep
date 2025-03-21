#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc98_cp2newSpace.sh.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc98_cp2newSpace.sh.sh.%J.err
#SBATCH --job-name sc98_cp2newSpace.sh
#SBATCH --mem=1G

ulimit -c 0


cp -r /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/ppt_acc   /gpfs/gibbs/pi/hydro/dataproces/TERRA/
cp -r /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/ppt       /gpfs/gibbs/pi/hydro/dataproces/TERRA/
cp -r /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc  /gpfs/gibbs/pi/hydro/dataproces/TERRA/
cp -r /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil      /gpfs/gibbs/pi/hydro/dataproces/TERRA/
