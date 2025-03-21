#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc36_compUnit_base_variable.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc36_compUnit_base_variable.sh.%A_%a.err
#SBATCH --job-name=sc36_compUnit_base_variable.sh
#SBATCH --mem=50G
#SBATCH --array=1-166

##### 1-166
##### array 166 ### 45 array for patagoinia bid35 
# ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc36_compUnit_base_variable.sh
### for n in $(seq 1 166) ; do ls /gpfs/scratch60/fas/sbsc/ga254/stderr/sc36_compUnit_base_variable.sh.*_$n.err ; done  
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m 

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

# find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=97  #####   ID 96 small area for testing 
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### SLURM_ARRAY_TASK_ID=43
export file_en=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}_enlarg/bid*_msk.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file_en .tif  )
export ID=$( echo $filename | awk '{ gsub("bid","") ; gsub("_msk","") ; print }'   )

export file_bs=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}/bid${ID}_msk.tif 2>  /dev/null  )

echo $file 
export GDAL_CACHEMAX=70000
####  stream is the classic one from r.stream.extract 

echo lbasin lstream outlet basin stream dir | xargs -n 1 -P 2 bash -c $'
var=$1                    
echo gdal_transalte $var
if [ $var = "lbasin" ] || [ $var = "lstream" ] || [ $var = "outlet"  ] || [ $var = "basin"  ] || [ $var = "stream"  ]  ; then ND=0 ; fi  
if [ $var = "dir" ]                                                    ; then ND="-10" ; fi  
gdal_translate  -a_nodata $ND -a_srs EPSG:4326  -a_ullr $(getCorners4Gtranslate $file_en)  -projwin $(getCorners4Gtranslate $file_en)  -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/${var}_tiles_final20d_1p/all_${var}_dis.vrt $RAM/${var}_${ID}_crop.tif
echo pksetmask $var
gdalinfo $RAM/${var}_${ID}_crop.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif 
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_en)  $RAM/${var}_${ID}_crop.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif

gdalinfo $RAM/${var}_${ID}_crop.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file_en  -msknodata 0 -nodata $ND -i $RAM/${var}_${ID}_crop.tif -o  $SC/CompUnit_$var/${var}_${ID}_msk.tif 
gdal_edit.py  -a_nodata $ND $SC/CompUnit_$var/${var}_${ID}_msk.tif 
rm $RAM/${var}_${ID}_crop.tif 

if [ $var = "lbasin" ] ; then
gdalinfo -mm $SC/CompUnit_$var/${var}_${ID}_msk.tif | grep Computed | awk \'{gsub(/[=,]/," ",$0); print int($3),int($4)}\' > $SC/CompUnit_lbasin/lbasin_${ID}_msk.mm
pkstat -hist -i $SC/CompUnit_$var/${var}_${ID}_msk.tif | grep -v " 0"  > $SC/CompUnit_lbasin/lbasin_${ID}_msk.hist
fi 

' _ 

export GDAL_CACHEMAX=12000
gdal_translate  -a_srs EPSG:4326 -a_nodata -9999999  -a_ullr $(getCorners4Gtranslate $file_en)   -projwin $(getCorners4Gtranslate $file_en) -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles/all_tif_dis.vrt $RAM/flow_${ID}_crop.tif
pksetmask of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $file_en  -msknodata 0 -nodata -9999999  -i $RAM/flow_${ID}_crop.tif -o  $SC/CompUnit_flow/flow_${ID}_msk.tif 
gdal_edit.py  -a_nodata -9999999  $SC/CompUnit_flow/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow/flow_${ID}_msk.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_en)  $SC/CompUnit_flow/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow/flow_${ID}_msk.tif

rm -f $RAM/flow_${ID}_crop.tif

export GDAL_CACHEMAX=8000 
echo elv are msk dep | xargs -n 1 -P 2 bash -c $'
var=$1
if [ $var = "elv" ] || [ $var = "are" ] ; then  ND="-9999" ; fi
if [ $var = "msk" ] || [ $var = "dep" ] ; then  ND="0" ; fi
gdal_translate  -co BIGTIFF=YES  -a_nodata $ND  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $file_en) -projwin $(getCorners4Gtranslate $file_en) $MERIT/${var}/all_tif_dis.vrt $RAM/${var}_${ID}_crop.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif 
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_en)  $RAM/${var}_${ID}_crop.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif 

pksetmask   -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file_en -msknodata 0 -nodata $ND  -i $RAM/${var}_${ID}_crop.tif -o $SC/CompUnit_$var/${var}_${ID}_msk.tif 
gdal_edit.py  -a_nodata $ND $SC/CompUnit_$var/${var}_${ID}_msk.tif
rm -f $RAM/${var}_${ID}_crop.tif
' _ 

#######################################################################
### use the no_enlarge compunit 


export GDAL_CACHEMAX=12000
gdal_translate  -a_srs EPSG:4326 -a_nodata -9999999  -a_ullr $(getCorners4Gtranslate $file_bs)   -projwin $(getCorners4Gtranslate $file_bs) -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles/all_tif_dis.vrt $RAM/flow_${ID}_crop.tif
pksetmask of GeoTIFF -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file_bs -msknodata 0 -nodata -9999999 -i $RAM/flow_${ID}_crop.tif -o $SC/CompUnit_flow_noenlarge/flow_${ID}_msk.tif 
gdal_edit.py  -a_nodata -9999999  $SC/CompUnit_flow_noenlarge/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow_noenlarge/flow_${ID}_msk.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_bs)  $SC/CompUnit_flow_noenlarge/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow_noenlarge/flow_${ID}_msk.tif

rm -f $RAM/flow_${ID}_crop.tif


export GDAL_CACHEMAX=12000
gdal_translate  -a_srs EPSG:4326 -a_nodata -9999999  -a_ullr $(getCorners4Gtranslate $file_bs)   -projwin $(getCorners4Gtranslate $file_bs) -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles/all_tif_pos_dis.vrt $RAM/flow_${ID}_crop.tif
pksetmask of GeoTIFF -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file_bs -msknodata 0 -nodata -9999999 -i $RAM/flow_${ID}_crop.tif -o $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif 
gdal_edit.py  -a_nodata -9999999  $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_bs)  $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SC/CompUnit_flow_pos_noenlarge/flow_${ID}_msk.tif

rm -f $RAM/flow_${ID}_crop.tif




export GDAL_CACHEMAX=8000 
echo are | xargs -n 1 -P 2 bash -c $'
var=$1
if [ $var = "elv" ] || [ $var = "are" ] ; then  ND="-9999" ; fi
if [ $var = "msk" ] || [ $var = "dep" ] ; then  ND="0" ; fi
gdal_translate  -co BIGTIFF=YES  -a_nodata $ND  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $file_bs) -projwin $(getCorners4Gtranslate $file_bs) $MERIT/${var}/all_tif_dis.vrt $RAM/${var}_${ID}_crop.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif 
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file_bs)  $RAM/${var}_${ID}_crop.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_crop.tif 

pksetmask   -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file_bs -msknodata 0 -nodata $ND  -i $RAM/${var}_${ID}_crop.tif -o $SC/CompUnit_${var}_noenlarge/${var}_${ID}_msk.tif 
gdal_edit.py  -a_nodata $ND $SC/CompUnit_${var}_noenlarge/${var}_${ID}_msk.tif
rm -f $RAM/${var}_${ID}_crop.tif
' _ 

exit 




exit 

### done for controll 

#### recompute basin  with r.stream.extract   


cp $SC/CompUnit_stream/stream_${ID}_msk.tif  $RAM/
cp $SC/CompUnit_dir/dir_${ID}_msk.tif        $RAM/
cp $SC/CompUnit_msk/msk_${ID}_msk.tif        $RAM/

grass78  -f -text --tmp-location  -c $RAM/stream_${ID}_msk.tif   <<EOF

r.external  input=$RAM/msk_${ID}_msk.tif  output=msk      --overwrite # create the folder structure
r.external  input=$RAM/stream_${ID}_msk.tif    output=stream   --overwrite  
r.external  input=$RAM/dir_${ID}_msk.tif       output=dir      --overwrite  

r.mask raster=msk --o #

r.stream.basins -l  stream_rast=stream direction=dir   basins=lbasin  memory=70000 --o --verbose  
r.stream.basins     stream_rast=stream direction=dir   basins=basin   memory=70000 --o --verbose  

r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE"    type=UInt32 format=GTiff nodata=0   input=lbasin  output=$SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.tif 
r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE"    type=UInt32 format=GTiff nodata=0   input=basin   output=$SC/CompUnit_basin_extract/basin_extract_${ID}.tif 

EOF

gdalinfo -mm $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.mm 
gdalinfo -mm $SC/CompUnit_basin_extract/basin_extract_${ID}.tif   | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SC/CompUnit_basin_extract/basin_extract_${ID}.mm 

minl=$(awk '{print $1  }' $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.mm )
maxl=$(awk '{print $2  }' $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.mm )

min=$(awk '{print $1  }' $SC/CompUnit_basin_extract/basin_extract_${ID}.mm )
max=$(awk '{print $2  }' $SC/CompUnit_basin_extract/basin_extract_${ID}.mm )

pkstat -src_min $minl  -src_max $maxl  --hist -i $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.tif | grep -v " 0" > $SC/CompUnit_lbasin_extract/lbasin_extract_${ID}.hist 
pkstat -src_min $min   -src_max $max   --hist -i $SC/CompUnit_basin_extract/basin_extract_${ID}.tif   | grep -v " 0" > $SC/CompUnit_basin_extract/basin_extract_${ID}.hist 

### CompUnit_basin_extract   717 568 275 
### CompUnit_lbasin_extract    1 560 501    lbasin 1 560 493
#### paste -d " " <(wc -l CompUnit_lbasin_extract/*.hist)  <(wc -l     CompUnit_lbasin/lbasin_*_msk.hist | awk '{print $1 -1 }' ) | awk '{ print $1-$3, $2 , $4  }' | sort -g 
####   


exit 

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then

sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc36_compUnit_base_variable.sh  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc37_lbasin_basin_uniq_CompUnit.sh

sleep 60

for name in strahler topo shreve horton_length hack_length vect_length horton_flow hack_flow vect_flow ; do 
sbatch --export=name=$name   --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc36_compUnit_base_variable.sh  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )    --job-name=sc41_compUnit_stream_order_$name.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order.sh 
done

sleep 60
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc36_compUnit_base_variable.sh  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/s\cripts/MERIT_HYDRO/sc42_compUnit_stream_distance.sh 

sleep 60
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc36_compUnit_base_variable.sh  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/s\cripts/MERIT_HYDRO/sc43_compUnit_stream_slope.sh 

fi
