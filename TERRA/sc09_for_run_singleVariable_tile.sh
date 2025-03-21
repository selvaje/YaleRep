#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc09_for_run_singleVariable.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc09_for_run_singleVariable.sh.%J.err
#SBATCH --mem=200M
#SBATCH --job-name=sc09_for_run_singleVariable.sh
ulimit -c 0

### sbatch --export=var=swe,yyyy=1958  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc09_for_run_singleVariable_tile.sh

for month in 01 02 03 04 05 06 07 08 09 10 11 12 ; do 
for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${var}/${var}_${yyyy}_${month}.tif ; do 
for ID  in 37 38 39 40 41   ; do 
MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print int($4)   }' ) 
sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_TERRA_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_forloop_tile.sh 
done 
done
 # sleep 1200
done
