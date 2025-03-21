#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_basin_area.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_basin_area.sh.%A_%a.err
#SBATCH --job-name=sc12_basin_area.sh
#SBATCH --array=1-82
#SBATCH --mem=20G
### --array=1-82

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRDC/sc12_basin_area.sh 

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

export file=$(ls    $PRJ/GRDC/MRB_tif/mrb_basins_*.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file .tif  | sed 's/mrb_basins_//g')

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate $file) $PRJ/MERIT_HYDRO/are/all_tif_dis.vrt  $RAM/are_$tile.tif 

grass78  -f -text --tmp-location  -c    $PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif    <<'EOF'

r.external  input=$PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif       output=basin        --overwrite 
r.external  input=$RAM/are_$tile.tif                           output=are        --overwrite 

r.univar -e -t  map=are zones=basin separator=space  output=$PRJ/GRDC/MRB_tif/mrb_basins_$tile.stat   --overwrite

EOF
rm $RAM/are_$tile.tif 

if [ $SLURM_ARRAY_TASK_ID = 82  ]  ; then 
## sleep 1000
for file in  $PRJ/GRDC/MRB_tif/mrb_basins_*.stat  ; do awk '{ if (NR>1) print $1 , $13 }' $file ; done    | sort -g -k 1  > $PRJ/GRDC/MRB_tif/all_mrb_basins.stat 
~/scripts/general/sum.sh $PRJ/GRDC/MRB_tif/all_mrb_basins.stat  $PRJ/GRDC/MRB_tif/all_mrb_basins.rec  <<EOF
n
1
0
EOF

awk '{ if ($1==0) {print 0 , 0 } else {print $1, $2} }'  $PRJ/GRDC/MRB_tif/all_mrb_basins.rec > $PRJ/GRDC/MRB_tif/all_mrb_basins0.rec

fi 
x



