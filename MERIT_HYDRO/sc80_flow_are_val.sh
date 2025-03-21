#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc89_flow_are_val.sh.%A_%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc89_flow_are_val.sh.%A_%a.err
#SBATCH --job-name=sc89_flow_are_val.sh
#SBATCH --array=1-116,151-200
#SBATCH --mem=40G

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export ID=$SLURM_ARRAY_TASK_ID

# find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  


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

paste <( for n in $(seq 151 200) ; do awk '{if(NR==1) print int($2/1000000)}' lbasin_compUnit_large/bid${n}_msk.area ; done   ) \
      <( for n in $(seq 151 200) ; do awk '{ print $2}'  CompUnit_flow_pos_noenlarge/flow_${n}_msk.mm  ; done   ) | awk '{  print $1 / $2  }'


paste <( for n in $(seq 151 200) ; do grep sum  CompUnit_are_noenlarge/are_${n}_msk.stat | awk '{ print $2  }'    ; done   ) \
      <( for n in $(seq 151 200) ; do awk '{ print $2}'  CompUnit_flow_pos_noenlarge/flow_${n}_msk.mm  ; done   ) > test.txt 


awk '{ print NR+150 , $1 , $2 , $1/$2 }' test.txt  | sort -k 2,2 -g 
