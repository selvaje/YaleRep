#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc99_nodata_GRWL.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc99_nodata_GRWL.sh.%A_%a.err
#SBATCH --array=1-295
#SBATCH --mem=25G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc99_nodata_GRWL.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools 

file=$(ls /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GRWL/GRWL_*_acc/intb/GRWL_*_*_acc.tif | head -n $SLURM_ARRAY_TASK_ID | tail  -n 1  )
## pksetmask -m $file   -msknodata  -9999 -nodata -9999 -p '<'  -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file  -o $file.new 
mv $file.new  $file 
