#!/bin/bash
#SBATCH -p day
#SBATCH -J start_bsub.sh 
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 00:01:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/start_bsub.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/start_bsub.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

sleep 2
