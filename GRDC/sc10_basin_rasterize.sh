#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_basin_rasterize.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_basin_rasterize.sh.%A_%a.err
#SBATCH --job-name=sc10_basin_rasterize.sh
#SBATCH --array=1-116
#SBATCH --mem=40G

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRDC/sc10_basin_rasterize.sh

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

file=$(ls $SC/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
tile=$(basename $file .tif  | sed 's/lbasin_//g')

# gdal_rasterize -ot UInt16 -a "WMOBB"  -co COMPRESS=DEFLATE -co ZLEVEL=9  -te $( getCorners4Gwarp $file ) -tr 0.00083333333333333 0.00083333333333333 $PRJ/GRDC/WMO_shp/wmobb_basins.shp  $PRJ/GRDC/WMO_tif/wmobb_basins_$tile.tif

gdal_rasterize -ot UInt16 -a "MRBID" -co COMPRESS=DEFLATE -co ZLEVEL=9  -te $( getCorners4Gwarp $file ) -tr 0.00083333333333333 0.00083333333333333 $PRJ/GRDC/MRB_shp/mrb_basins.shp   $PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif

MAX=$(pkstat -max  -i $PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif  | awk '{ print int($2)  }' )
if [ $MAX -eq 0   ] ; then
rm $PRJ/GRDC/MRB_tif/mrb_basins_$tile.tif
fi 

exit 









grass78  -f -text --tmp-location  -c $SC/CompUnit_are_noenlarge/are_${ID}_msk.tif    <<'EOF'

r.external  input=$SC/CompUnit_are_noenlarge/are_${ID}_msk.tif        output=are        --overwrite 
r.external  input=$SC/lbasin_compUnit_large/bid${ID}_msk.tif          output=bid        --overwrite 
r.external  input=$SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif  output=flow       --overwrite 

r.stats  -a input=bid  output=$SC/lbasin_compUnit_large/bid${ID}_msk.area         --overwrite
r.stats  -a input=flow output=$SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.area --overwrite
r.univar -e map=flow   output=$SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.stat --overwrite
r.univar -e map=are    output=$SC/CompUnit_are_noenlarge/are_${ID}_msk.stat       --overwrite

EOF

gdalinfo -mm $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print $3 , $4 }' > $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.mm

exit

paste <(awk '{if(NR==1) print $2}' lbasin_compUnit_large/bid151_msk.area )  <(awk '{if(NR==1) print $2}' CompUnit_flow_pos_noenlarge/flow_151_msk.area) 
