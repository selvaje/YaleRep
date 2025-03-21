#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdoutord/sc44_compUnit_stream_channel.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderrord/sc44_compUnit_stream_channel.sh.%A_%a.err
#SBATCH --job-name=sc44_compUnit_stream_channel.sh
#SBATCH --mem=40G
#SBATCH --array=1-166

### 1-166
##### array 116 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc44_compUnit_stream_channel.sh

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=97  #####   ID 96 small area for testing 
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}_enlarg/bid*_msk.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("bid","") ; gsub("_msk","") ; print }'   )

echo $file 
echo coordinates $ulx $uly $lrx $lry

echo elv msk dir | xargs -n 1 -P 1 bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_cha.tif
' _ 

cp $SC/CompUnit_stream_uniq_reclas/stream_uniq_${ID}.tif  $RAM/stream_uniq_${ID}_cha.tif


grass78  -f -text --tmp-location  -c $RAM/elv_${ID}_msk_cha.tif  <<'EOF'

for var in elv msk dir ; do
r.external  input=$RAM/${var}_${ID}_msk_cha.tif     output=$var  --overwrite
done

r.external  input=$RAM/stream_uniq_${ID}_cha.tif   output=stream  --overwrite

r.mask raster=msk --o

################# r.stream.channel  https://grass.osgeo.org/grass78/manuals/addons/r.stream.channel.html
###  -d  Calculate parameters from outlet (downstream values)
###  -l  Calculate local values (for current cell)

#### Gradient 
## Upstream mean gradient between current cell and the init/join. Flag modifications:
# -d: downstream mean gradient between current cell and the join/outlet;
# -l: local gradient between current cell and next cell. Flag -d ignored
# -c: Ignored.

r.stream.channel.hack -d stream_rast=stream direction=dir elevation=elv gradient=grad_dw_seg memory=50000 --o; r.mapcalc "grad_dw_seg_m = grad_dw_seg  * 1000000" --o
r.stream.channel.hack    stream_rast=stream direction=dir elevation=elv gradient=grad_up_seg memory=50000 --o; r.mapcalc "grad_up_seg_m = grad_up_seg  * 1000000" --o
r.stream.channel.hack -l stream_rast=stream direction=dir elevation=elv gradient=grad_up_cel memory=50000 --o; r.mapcalc "grad_up_cel_m = grad_up_cel  * 1000000" --o

### 

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 nodata=-9999999 input=grad_dw_seg_m output=$SC/CompUnit_stream_channel/channel_grad_dw_seg/channel_grad_dw_seg_$ID.tif 

gdalinfo -mm $SC/CompUnit_stream_channel/channel_grad_dw_seg/channel_grad_dw_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," ", $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_grad_dw_seg/channel_grad_dw_seg_$ID.mm

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 nodata=-9999999 input=grad_up_seg_m output=$SC/CompUnit_stream_channel/channel_grad_up_seg/channel_grad_up_seg_$ID.tif 

gdalinfo -mm $SC/CompUnit_stream_channel/channel_grad_up_seg/channel_grad_up_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," ", $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_grad_up_seg/channel_grad_up_seg_$ID.mm

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 nodata=-9999999 input=grad_up_cel_m output=$SC/CompUnit_stream_channel/channel_grad_up_cel/channel_grad_up_cel_$ID.tif 

gdalinfo -mm $SC/CompUnit_stream_channel/channel_grad_up_cel/channel_grad_up_cel_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," ", $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_grad_up_cel/channel_grad_up_cel_$ID.mm

####  Curvature 
# Local stream course curvature of current cell. Calculated according formula: first_derivative/(1-second_derivative2)3/2 Flag modifications:
# -d: ignored;
# -l: Ignored.
# -c: Ignored.

r.stream.channel.hack -d stream_rast=stream direction=dir elevation=elv curvature=curvature memory=50000 --o 
r.mapcalc "curvature_mult = curvature * 1000000" --o
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999999 input=curvature_mult output=$SC/CompUnit_stream_channel/channel_curv_cel/channel_curv_cel_$ID.tif 
gdalinfo -mm $SC/CompUnit_stream_channel/channel_curv_cel/channel_curv_cel_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_curv_cel/channel_curv_cel_$ID.mm

####  Difference 
# Upstream elevation difference between current cell to the init/join. It we need to calculate parameters different than elevation. 
# If we need to calculate different parameters than elevation along streams (for example precipitation or so) use necessary map as elevation. Flag modifications:
# -d: downstream difference of current cell to the join/outlet;
# -l: local difference between current cell and next cell. With flag calculates difference between previous cell and current cell
# -c: Ignored.

r.stream.channel.hack -d stream_rast=stream direction=dir elevation=elv difference=diff_dw_seg  memory=50000 --o 
r.stream.channel.hack    stream_rast=stream direction=dir elevation=elv difference=diff_up_seg  memory=50000 --o 

r.stream.channel.hack -d -l stream_rast=stream direction=dir elevation=elv difference=diff_dw_cel  memory=50000 --o 
r.stream.channel.hack    -l stream_rast=stream direction=dir elevation=elv difference=diff_up_cel  memory=50000 --o 

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999999 input=diff_dw_seg output=$SC/CompUnit_stream_channel/channel_elv_dw_seg/channel_elv_dw_seg_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_elv_dw_seg/channel_elv_dw_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_elv_dw_seg/channel_elv_dw_seg_$ID.mm 
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999999 input=diff_up_seg output=$SC/CompUnit_stream_channel/channel_elv_up_seg/channel_elv_up_seg_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_elv_up_seg/channel_elv_up_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_elv_up_seg/channel_elv_up_seg_$ID.mm

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  nodata=-9999999 input=diff_dw_cel output=$SC/CompUnit_stream_channel/channel_elv_dw_cel/channel_elv_dw_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_elv_dw_cel/channel_elv_dw_cel_$ID.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_elv_dw_cel/channel_elv_dw_cel_$ID.mm
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  nodata=-9999999 input=diff_up_cel output=$SC/CompUnit_stream_channel/channel_elv_up_cel/channel_elv_up_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_elv_up_cel/channel_elv_up_cel_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_elv_up_cel/channel_elv_up_cel_$ID.mm

##### distance

# Upstream distance of current cell to the init/join. Flag modifications:
# -d: downstream distance of current cell to the join/outlet;
# -l: local distance between current cell and next cell. In most cases cell resolution and sqrt2 of cell resolution. 
#     Useful when projection is LL or NS and WE resolutions differs. Flag -d i# gnored
# -c: distance in cells. Map is written as double. Use r.mapcalc to convert to integer. Flags -l and -d ignored.

r.stream.channel.hack -d stream_rast=stream direction=dir elevation=elv distance=dist_dw_seg  memory=50000 --o 
r.stream.channel.hack    stream_rast=stream direction=dir elevation=elv distance=dist_up_seg  memory=50000 --o 

r.stream.channel.hack -l stream_rast=stream direction=dir elevation=elv distance=dist_up_cel  memory=50000 --o 

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  nodata=-9999999 input=dist_dw_seg output=$SC/CompUnit_stream_channel/channel_dist_dw_seg/channel_dist_dw_seg_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_dist_dw_seg/channel_dist_dw_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_dist_dw_seg/channel_dist_dw_seg_$ID.mm

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  nodata=-9999999 input=dist_up_seg output=$SC/CompUnit_stream_channel/channel_dist_up_seg/channel_dist_up_seg_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_dist_up_seg/channel_dist_up_seg_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_dist_up_seg/channel_dist_up_seg_$ID.mm
                                                             #### can be done Int16 or even Byte
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 nodata=-9999999 input=dist_up_cel output=$SC/CompUnit_stream_channel/channel_dist_up_cel/channel_dist_up_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_dist_up_cel/channel_dist_up_cel_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $SC/CompUnit_stream_channel/channel_dist_up_cel/channel_dist_up_cel_$ID.mm

#### identifier 

r.stream.channel.hack stream_rast=stream direction=dir elevation=elv identifier=identifier memory=50000 --o 
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32  nodata=0  input=identifier output=$SC/CompUnit_stream_channel/channel_ident/channel_ident_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_channel/channel_ident/channel_ident_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SC/CompUnit_stream_channel/channel_ident/channel_ident_$ID.mm

EOF

echo elv msk stream dir | xargs -n 1 -P 1 bash -c $'
var=$1
rm -f $RAM/${var}_${ID}_msk_cha.tif
' _

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then
sbatch --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc44_compUnit_stream_channel.sh | awk '{print $1}' | uniq) /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc48_compUnit_stream_channel_tile20d.sh

fi

