#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc86_basinarea_calc_rec.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc86_basinarea_calc_rec.sh.%A_%a.err
#SBATCH --job-name=sc86_basinarea_calc_rec.sh
#SBATCH --array=1-82
#SBATCH --mem=50G
### --array=1-82

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc86_basinarea_calc_rec.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export PRJ=/gpfs/gibbs/pi/hydro/hydro/dataproces
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls    $PRJ/GRDC/MRB_tif/mrb_basins_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file .tif  | sed 's/mrb_basins_//g')

pkreclass -ot UInt32 -code $SC/lbasin_tiles_final20d_1p/lbasin_area0.rec -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $SC/lbasin_tiles_final20d_1p/lbasin_${tile}.tif -o $SC/lbasin_tiles_final20d_1p/lbasin_${tile}_arearec.tif

