#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_tile_control_TERRA_forFinalCheck.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_tile_control_TERRA_forFinalCheck.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc12_tile_control_TERRA_forFinalCheck.sh
ulimit -c 0


#### for year in $(seq 1958 2019 ) ; do sbatch --export=dir=ppt,year=$year /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc12_tile_control_TERRA_forFinalCheck.sh ; done 

### dir=ppt
### year=1964

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc

echo ls 
for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do 
ls $DIR/$year/tiles20d/${dir}_${year}_${MM}_*_acc.tif | wc -l ; 
done > $DIR/$year/checking_ls.txt  

