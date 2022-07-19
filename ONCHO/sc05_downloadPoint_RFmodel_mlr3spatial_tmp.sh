#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%A_%a.err
#SBATCH --job-name=sc05_downloadPoint_RFmodel_mlr3spatial.sh
#SBATCH --mem=100G
#SBATCH --array=1
## 143 

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc05_downloadPoint_RFmodel_mlr3spatial_tmp.sh

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO
cd $ONCHO/vector

SLURM_ARRAY_TASK_ID=1

geo_string=$(head  -n  $SLURM_ARRAY_TASK_ID $ONCHO/vector/tile_list.txt   | tail  -1 )
export xmin=$( echo $geo_string | awk '{  print $1 }' ) 
export xmax=$( echo $geo_string | awk '{  print $2 }' ) 
export ymin=$( echo $geo_string | awk '{  print $3 }' ) 
export ymax=$( echo $geo_string | awk '{  print $4 }' ) 

echo geo_string  > /tmp/geo_string_${xmin}_${ymin}.txt 

module load R/4.1.0-foss-2020b

echo geo_string  =  $xmin  $xmax $ymin $ymax

export xmin=$xmin

Rscript --vanilla  -e   '

Sys.getenv("PATH")

# geo_string = read.table("/tmp/geo_string_${xmin}_${ymin}.txt")
Sys.unsetenv("xmin")
xmin <- Sys.getenv("xmin")
xmax <- as.numeric(Sys.getenv("xmax"))
ymin <- as.numeric(Sys.getenv("ymin"))
ymax <- as.numeric(Sys.getenv("ymax"))

# xmin=geo_string[1]
# xmax=geo_string[2]
# ymin=geo_string[3]
# ymax=geo_string[4]

paste0 ("print xmin = " , xmin )
paste0 ("print xmin = " , xmax )

xmin 
xmax

'
