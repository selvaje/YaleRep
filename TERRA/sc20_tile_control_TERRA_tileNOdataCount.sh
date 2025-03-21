#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_tile_control_TERRA_tileNOdataCount.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_tile_control_TERRA_tileNOdataCount.sh.%A_%a.err
#SBATCH --array=1-1380
#SBATCH --mem=5G
#SBATCH --job-name=sc20_tile_control_TERRA_tileNOdataCount.sh
ulimit -c 0


#### 1380 = 115 * 12 
####  for year in $(seq 1958 2018 ) ; do sbatch --export=dir=ppt,year=$year  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc20_tile_control_TERRA_tileNOdataCount.sh ; done 

source ~/bin/gdal3
source ~/bin/pktools

# dir=ppt
# year=1964

# nodata count inserito nel sc11   fare correre solo in caso di re-count of nodata. 

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc

echo min max $year $dir 

file=$(ls  $DIR/$year/tiles20d/${dir}_${year}_*_acc.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 )
filename=$(basename $file .tif )
echo $filename  $( pkstat -hist   -src_min -9999999.1 -src_max -9999998.9 -i $file  | awk '{ print $2 }' ) >  /dev/shm/${filename}.nd
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${filename}.nd > $DIR/$year/tiles20d/${filename}.nd

rm -f   /dev/shm/${filename}.nd




