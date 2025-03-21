#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00    # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_delete_255.sh.%A_%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_delete_255.sh.%A_%a.err
#SBATCH  --array=504
#SBATCH  --mem=5G
#SBATCH --job-name=c03_delete_255

# after the download 504 files in all the folder. 

ulimit -c 0

### for var in change transitions   extent  occurrence  recurrence  seasonality ; do   sbatch --export=var=$var  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc03_delete_255.sh  ; done 
#### grep slurm  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_delete_255.sh.*.err |  awk '{ gsub( /[_\.]/ , " " ) ; print $6 }'   | sort  | uniq

source /home/ga254/bin/gdal3
source /home/ga254/bin/pktools 

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input

file=$(ls $DIR/${var}_download/*.tif |  head  -n  $SLURM_ARRAY_TASK_ID  |  tail  -1 ) 
filename=$(basename $file .tif )

MIN=$(pkstat -min -i   $file  | awk '{ print $2 }')

if [ $MIN =  255  ] ; then 
mv  $file   $file.rm 
fi 

exit 

#####

files in all the folders. 

429 change  
504 transitions 
428 extent  
432 occurrence  
419 recurrence 
420 seasonality

change 0 200   100 no changes     253 land   254  ???    255 sea      >  100 

extent 0 1         0 land    255 sea  >  1
occurrence 0 100   0 land    255 sea  >  100
recurrence 0 100   0 land    255 sea  >  100 
seasonality 0 12   0 land    255 sea  >  12  
