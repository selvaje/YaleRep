#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc43_compUnit_stream_slope.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc43_compUnit_stream_slope.sh.%A_%a.err
#SBATCH --job-name=sc43_compUnit_stream_slope.sh
#SBATCH --mem=20G  
#SBATCH --array=1-166

##### array 166 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

#####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc43_compUnit_stream_slope.sh

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

### SLURM_ARRAY_TASK_ID=97  #####   ID 96 small area for testing 
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}_enlarg/bid*_msk.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("bid","") ; gsub("_msk","") ; print }'   )

echo $file 
echo coordinates $ulx $uly $lrx $lry

echo elv msk dir  | xargs -n 1 -P 1 bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_slo.tif
' _ 

cp $SC/CompUnit_stream_uniq_reclas/stream_uniq_${ID}.tif  $RAM/stream_uniq_${ID}_slo.tif


grass78  -f -text --tmp-location  -c $RAM/elv_${ID}_msk_slo.tif  <<'EOF'

for var in  elv msk dir ; do 
r.external  input=$RAM/${var}_${ID}_msk_slo.tif output=$var --overwrite  
done

r.external input=$RAM/stream_uniq_${ID}_slo.tif  output=stream  --overwrite  

r.mask raster=msk --o # usefull to mask the flow accumulation 

########## r.stream.slope    https://grass.osgeo.org/grass78/manuals/addons/r.stream.slope.html
r.mask raster=msk  --o
r.stream.slope direction=dir elevation=elv  gradient=gradient maxcurv=maxcurv mincurv=mincurv  difference=difference   --o  --quiet 
r.grow radius=5 input=difference   output=difference_fill  --o 
r.grow radius=5 input=gradient     output=gradient_fill    --o 

r.mapcalc "gradient_mult = gradient_fill * 1000000"
r.mapcalc "maxcurv_mult = maxcurv * 1000000"
r.mapcalc "mincurv_mult = mincurv * 1000000"

r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int32 format=GTiff nodata=-9999999  input=maxcurv_mult  output=$RAM/curvature_max_$ID.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${ID}_msk_slo.tif -msknodata -9999 -nodata -9999999 -i $RAM/curvature_max_$ID.tif  -o $SC/CompUnit_stream_slope/slope_curv_max_dw_cel/slope_curv_max_dw_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_slope/slope_curv_max_dw_cel/slope_curv_max_dw_cel_$ID.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_stream_slope/slope_curv_max_dw_cel/slope_curv_max_dw_cel_$ID.mm
rm $RAM/curvature_max_$ID.tif

r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int32 format=GTiff nodata=-9999999  input=mincurv_mult  output=$RAM/curvature_min_$ID.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $RAM/elv_${ID}_msk_slo.tif -msknodata -9999 -nodata -9999999 -i $RAM/curvature_min_$ID.tif  -o $SC/CompUnit_stream_slope/slope_curv_min_dw_cel/slope_curv_min_dw_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_slope/slope_curv_min_dw_cel/slope_curv_min_dw_cel_$ID.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_stream_slope/slope_curv_min_dw_cel/slope_curv_min_dw_cel_$ID.mm
rm $RAM/curvature_min_$ID.tif

r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int32 format=GTiff nodata=-9999999  input=gradient_mult  output=$RAM/gradient_$ID.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $RAM/elv_${ID}_msk_slo.tif -msknodata -9999 -nodata -9999999 -i $RAM/gradient_$ID.tif -o $SC/CompUnit_stream_slope/slope_grad_dw_cel/slope_grad_dw_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_slope/slope_grad_dw_cel/slope_grad_dw_cel_$ID.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_stream_slope/slope_grad_dw_cel/slope_grad_dw_cel_$ID.mm
rm $RAM/gradient_$ID.tif

r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16  format=GTiff nodata=-9999  input=difference_fill  output=$RAM/difference_$ID.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $RAM/elv_${ID}_msk_slo.tif -msknodata -9999 -nodata -9999 -i $RAM/difference_$ID.tif  -o $SC/CompUnit_stream_slope/slope_elv_dw_cel/slope_elv_dw_cel_$ID.tif
gdalinfo -mm $SC/CompUnit_stream_slope/slope_elv_dw_cel/slope_elv_dw_cel_$ID.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_stream_slope/slope_elv_dw_cel/slope_elv_dw_cel_$ID.mm
rm $RAM/difference_$ID.tif

EOF

echo elv msk dir  | xargs -n 1 -P 1 bash -c $'
var=$1
rm -f $RAM/${var}_${ID}_msk_slo.tif
' _ 

rm $RAM/stream_uniq_${ID}_slo.tif
exit 

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then 
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc43_compUnit_stream_slope.sh   | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc47_compUnit_stream_slope_tile20d.sh
fi 



