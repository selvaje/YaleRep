#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc19_hader_path.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc19_hader_path.sh.%A_%a.err
#SBATCH --job-name=sc19_hader_path.sh
#SBATCH --mem=160G
#SBATCH --array=90-110

### testing 58    h18v02
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116

ulimit -c 0
# SLURM_ARRAY_TASK_ID=96
export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export file=$(ls $MH/dir_tiles_final20d_1p/dir_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )  
export tile=$(basename  $file .tif | sed "s/dir_//g")

~/bin/echoerr $file 
echo          $file 

module load GRASS/8.2.0-foss-2022b

grass  -f --text --tmp-location  $file  <<'EOF' 

r.external  input=$file     output=direction       --overwrite  
v.external input=$MH/CompUnit_stream_order_tiles20d/order_vect_tiles20d/order_vect_point_$tile.gpkg  output=header

echo 1 = 5 >   /tmp/rules_$tile.txt
echo 2 = 6 >>  /tmp/rules_$tile.txt
echo 3 = 7 >>  /tmp/rules_$tile.txt
echo 4 = 8 >>  /tmp/rules_$tile.txt
echo 5 = 1 >>  /tmp/rules_$tile.txt
echo 6 = 2 >>  /tmp/rules_$tile.txt
echo 7 = 3 >>  /tmp/rules_$tile.txt
echo 8 = 4 >>  /tmp/rules_$tile.txt

r.reclass input=direction  output=direction_inv rules=/tmp/rules_$tile.txt  --overwrite 

r.mapcalc "direction_inv_deg = if(direction_inv  != 0, 45. * abs(direction_inv), null())"

r.path input=direction_inv_deg raster_path=drain_path start_points=header
r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16 format=GTiff nodata=-9999  input=drain_path   output=$MH/CompUnit_stream_order_tiles20d/header_top_tiles20d/drain_path_$tile.tif 

EOF


