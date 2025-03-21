#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc86_basinarea_calc.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc86_basinarea_calc.sh.%A_%a.err
#SBATCH --job-name=sc86_basinarea_calc.sh
#SBATCH --array=1-82
#SBATCH --mem=20G
### --array=1-82

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc86_basinarea_calc.sh

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

export file=$(ls    $PRJ/GRDC/MRB_tif/mrb_basins_??????_rec.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file _rec.tif  | sed 's/mrb_basins_//g')

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate $file) $PRJ/MERIT_HYDRO/are/all_tif_dis.vrt  $RAM/are_$tile.tif 

grass78  -f -text --tmp-location  -c $SC/lbasin_tiles_final20d_1p/lbasin_${tile}.tif    <<'EOF'

r.external  input=$SC/lbasin_tiles_final20d_1p/lbasin_${tile}.tif   output=basin        --overwrite 
r.external  input=$RAM/are_$tile.tif                                output=are        --overwrite 

r.univar -e -t map=are zones=basin separator=space  output=$SC/lbasin_tiles_final20d_1p/lbasin_${tile}.stat  --overwrite

EOF
rm $RAM/are_$tile.tif 

if [ $SLURM_ARRAY_TASK_ID = 82  ]  ; then 
## sleep 1000
for file in $SC/lbasin_tiles_final20d_1p/lbasin_??????.stat  ; do awk '{ if (NR>1) print $1 , $13 }' $file ; done    | sort -g -k 1  > $SC/lbasin_tiles_final20d_1p/lbasin_area.stat 
~/scripts/general/sum.sh $SC/lbasin_tiles_final20d_1p/lbasin_area.stat   $SC/lbasin_tiles_final20d_1p/lbasin_area.rec   <<EOF
n
1
0
EOF

awk 'BEGIN{print 0 , 0 } {if (NF==1) {print $1 , 0 } else {   print $1, $2} }'  $SC/lbasin_tiles_final20d_1p/lbasin_area.rec  > $SC/lbasin_tiles_final20d_1p/lbasin_area0.rec

fi 
