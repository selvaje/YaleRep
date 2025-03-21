#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc13_basin_area_rec.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc13_basin_area_rec.sh.%A_%a.err
#SBATCH --job-name=sc13_basin_area_rec.sh
#SBATCH --array=1-82
#SBATCH --mem=50G
### --array=1-82

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRDC/sc13_basin_area_rec.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export PRJ=/gpfs/gibbs/pi/hydro/hydro/dataproces
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export ID=$SLURM_ARRAY_TASK_ID

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls    $PRJ/GRDC/MRB_tif/mrb_basins_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file .tif  | sed 's/mrb_basins_//g')

pkreclass -ot UInt32 -code $PRJ/GRDC/MRB_tif/all_mrb_basins0.rec -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif -o $PRJ/GRDC/MRB_tif/mrb_basins_${tile}_rec.tif 

