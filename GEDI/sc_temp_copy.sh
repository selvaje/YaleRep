#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 10:30:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc_temp_copy.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc_temp_copy.sh.%A_%a.err
#SBATCH --job-name=sc_temp_copy.sh
#SBATCH --mem=5G
#SBATCH --array=10-12

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc_temp_copy.sh

## SLURM_ARRAY_TASK_ID=107

cp -R  2019.${SLURM_ARRAY_TASK_ID}.??_h5_list /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI2/

