#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc42_compUnit_stream_distance.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc42_compUnit_stream_distance.sh.%A_%a.err
#SBATCH --job-name=sc42_compUnit_stream_distance.sh
#SBATCH --mem=65G
#SBATCH --array=1-166

### 1-166
##### array 116 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc42_compUnit_stream_distance.sh

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

### SLURM_ARRAY_TASK_ID=126
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}_enlarg/bid*_msk.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("bid","") ; gsub("_msk","") ; print }'   )

echo $file 
echo coordinates $ulx $uly $lrx $lry

echo elv msk dir outlet | xargs -n 1 -P 1  bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_dis.tif
' _ 

cp $SC/CompUnit_stream_uniq_reclas/stream_uniq_${ID}.tif  $RAM/stream_uniq_${ID}_dis.tif

###  grass76 -f -text -c $RAM/${tile}_elv.tif   $SC/grassdb/loc_$tile   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/elv_${ID}_msk_dis.tif  <<'EOF'

for var in  elv msk dir outlet ; do 
r.external  input=$RAM/${var}_${ID}_msk_dis.tif     output=$var   --overwrite  
done

r.external  input=$RAM/stream_uniq_${ID}_dis.tif    output=stream --overwrite  

r.mask raster=msk --o 

####### r.stream.distance https://grass.osgeo.org/grass78/manuals/addons/r.stream.distance.html
# r.mask raster=basin --o

#################  stream distance   upstream  
## near  -n 
r.stream.distance -n method=upstream stream_rast=stream direction=dir elevation=elv distance=distance_stream_upstream  difference=difference_stream_upstream  memory=50000 --o  --quiet
r.grow radius=5 input=distance_stream_upstream   output=distance_stream_upstream_fill  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999 input=distance_stream_upstream_fill output=$SC/CompUnit_stream_dist/stream_dist_up_near/stream_dist_up_near_$ID.tif 

r.grow radius=5  input=difference_stream_upstream   output=difference_stream_upstream_fill  --o 
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16 format=GTiff nodata=-9999  input=difference_stream_upstream_fill output=$SC/CompUnit_stream_dist/stream_diff_up_near/stream_diff_up_near_$ID.tif  


## farth  no -n flag
r.stream.distance   method=upstream stream_rast=stream direction=dir elevation=elv distance=distance_stream_upstream  difference=difference_stream_upstream  memory=50000 --o  --quiet
r.grow radius=5 input=distance_stream_upstream   output=distance_stream_upstream_fill  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999 input=distance_stream_upstream_fill output=$SC/CompUnit_stream_dist/stream_dist_up_farth/stream_dist_up_farth_$ID.tif 

r.grow radius=5  input=difference_stream_upstream   output=difference_stream_upstream_fill  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16 format=GTiff nodata=-9999  input=difference_stream_upstream_fill output=$SC/CompUnit_stream_dist/stream_diff_up_farth/stream_diff_up_farth_$ID.tif

#################  stream distance   downstream      -n is not allow in downstream 

## farth  no -n flag
r.stream.distance   method=downstream stream_rast=stream direction=dir elevation=elv distance=distance_stream_downstream  difference=difference_stream_downstream  memory=50000 --o  --quiet
r.grow radius=5 input=distance_stream_downstream   output=distance_stream_downstream_fill  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999 input=distance_stream_downstream_fill output=$SC/CompUnit_stream_dist/stream_dist_dw_near/stream_dist_dw_near_$ID.tif 

r.grow radius=5  input=difference_stream_downstream   output=difference_stream_downstream_fill  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16 format=GTiff nodata=-9999  input=difference_stream_downstream_fill output=$SC/CompUnit_stream_dist/stream_diff_dw_near/stream_diff_dw_near_$ID.tif


################  outlet distacne downstream    -o Calculate parameters for outlets (outlet mode) instead of (default) streams
r.stream.distance -o method=downstream  stream_rast=outlet direction=dir elevation=elv distance=distance_outlet  difference=difference_outlet  memory=50000 --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int32 format=GTiff nodata=-9999  input=distance_outlet    output=$SC/CompUnit_stream_dist/outlet_dist_dw_basin/outlet_dist_dw_basin_$ID.tif
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16 format=GTiff nodata=-9999  input=difference_outlet  output=$SC/CompUnit_stream_dist/outlet_diff_dw_basin/outlet_diff_dw_basin_$ID.tif

################  -s  Calculate parameters for subbasins (ignored in stream mode)
r.stream.distance -o -s method=downstream stream_rast=stream direction=dir elevation=elv distance=distance_outlet  difference=difference_outlet  memory=50000 --o  --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int32 format=GTiff nodata=-9999  input=distance_outlet    output=$SC/CompUnit_stream_dist/outlet_dist_dw_scatch/outlet_dist_dw_scatch_$ID.tif
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16 format=GTiff nodata=-9999  input=difference_outlet  output=$SC/CompUnit_stream_dist/outlet_diff_dw_scatch/outlet_diff_dw_scatch_$ID.tif

############## stream euclidian distance 

r.mask raster=distance_outlet  --o
r.grow.distance -m  metric=geodesic input=stream distance=dist_from_streams  --o  --q
r.mapcalc " dist_from_streams_msk = dist_from_streams "  --o  --q   
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=-9999 input=dist_from_streams_msk output=$SC/CompUnit_stream_dist/stream_dist_proximity/stream_dist_proximity_$ID.tif

EOF

echo elv msk dir  | xargs -n 1 -P 1 bash -c $'
var=$1
rm -f $RAM/${var}_${ID}_msk_dis.tif
' _
rm $RAM/stream_uniq_${ID}_dis.tif

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc42_compUnit_stream_distance.sh |  awk '{ print $1 }' | uniq  )    /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc46_compUnit_stream_distance_tile20d.sh
fi

