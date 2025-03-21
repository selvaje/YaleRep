#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc41_compUnit_stream_order.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc41_compUnit_stream_order.sh.%A_%a.err
#SBATCH --mem=50G

##### array 116 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

#### for name in strahler ; do sbatch -p day -t 24:00:00 --array=40 --export=name=$name  --job-name=sc41_compUnit_stream_order_$name.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order_test.sh ; done

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
echo $name

echo elv msk flow lstream stream dir  | xargs -n 1 -P 1 bash -c $'
var=$1
cp $SC/tmp/tmp/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_$name.tif 

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_msk_$name.tif 
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $RAM/${var}_${ID}_msk_$name.tif )  $RAM/${var}_${ID}_msk_$name.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${var}_${ID}_msk_$name.tif 
' _ 

cp  $SC/tmp/tmp/stream_uniq_${ID}.tif  $RAM/stream_uniq_${ID}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/stream_uniq_${ID}.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $RAM/stream_uniq_${ID}.tif )  $RAM/stream_uniq_${ID}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/stream_uniq_${ID}.tif

rm -rf $SC/tmp/tmp/location

grass78  -f -text -c $RAM/elv_${ID}_msk_$name.tif  $SC/tmp/tmp/location    <<'EOF'

r.external  input=$RAM/stream_uniq_${ID}.tif  output=stream_uniq --overwrite 

for var in  elv msk flow stream lstream  dir ; do
r.external  input=$RAM/${var}_${ID}_msk_$name.tif     output=$var       --overwrite  
done

g.list rast -p 

r.mask raster=msk --o 

type=Int16 

#### lstream 
r.stream.order.hack.orig  stream_rast=lstream direction=dir elevation=elv  accumulation=flow strahler=order1  memory=40000 --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type format=GTiff  nodata=0 input=order1  output=$SC/tmp/order_lstream_$ID.tif

##### stream orig
r.stream.order.hack.orig  stream_rast=stream direction=dir elevation=elv  accumulation=flow strahler=order2  memory=40000 --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type format=GTiff  nodata=0 input=order2  output=$SC/tmp/order_stream_$ID.tif

###### uniq 

r.stream.order.hack.orig  stream_rast=stream_uniq direction=dir elevation=elv  accumulation=flow strahler=order3  memory=40000 --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type format=GTiff  nodata=0 input=order3  output=$SC/tmp/order_stream_uniq_$ID.tif

g.list rast -p 

EOF

exit 

