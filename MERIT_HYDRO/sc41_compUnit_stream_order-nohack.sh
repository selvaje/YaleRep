#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc41_compUnit_stream_order.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc41_compUnit_stream_order.sh.%A_%a.err
#SBATCH --mem=50G
#SBATCH --array=83

##### array 116 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

### stream order that can     be compute in grace with 24hour strahler shreve_flow shreve_length 
### stream order that can NOT be compute in grace with 24hour top horton_length horton_flow  vect_length  vect_flow hack  hack 

#### for name in strahler topo  hack  shreve_flow shreve_length horton_length horton_flow vect_length vect_flow ; do sbatch --export=name=$name  --job-name=sc41_compUnit_stream_order_$name.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order-nohack.sh  ; done

###  shreve_flow 

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

echo elv msk flow stream dir  | xargs -n 1 -P 1 bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_$name.tif 
' _ 

###  grass76 -f -text -c $RAM/${tile}_elv.tif   $SC/grassdb/loc_$tile   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/elv_${ID}_msk_$name.tif  <<'EOF'

for var in  elv msk flow stream dir ; do
r.external  input=$RAM/${var}_${ID}_msk_$name.tif     output=$var       --overwrite  
done

r.mask raster=msk --o 

####### r.stream.order  https://grass.osgeo.org/grass78/manuals/addons/r.stream.order.html
GRASS_VERBOSE=1

if [ $name = strahler ] || [ $name = topo ] || [ $name = horton_length ] || [ $name = shreve_length ] || [ $name = hack ] ; then  

if [ $name = strahler        ] ; then type=Int16   ; order=strahler   ; fi   # some area have negative value: Taiwan ...                
if [ $name = topo            ] ; then type=Int32   ; order=topo       ; fi
if [ $name = horton_length   ] ; then type=Int32   ; order=horton     ; fi
if [ $name = shreve_length   ] ; then type=Int32   ; order=shreve     ; fi
if [ $name = hack            ] ; then type=Int32   ; order=hack       ; fi

r.stream.order  stream_rast=stream direction=dir elevation=elv  accumulation=flow $order=order  memory=40000 --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type   format=GTiff  nodata=0   input=order  output=$SC/CompUnit_stream_order/order_${name}_${ID}_nohack.tif
fi 

if [ $name = horton_flow ] || [ $name = shreve_flow ]  ; then  

   if [ $name = horton_flow   ] ; then type=Int32     ; order=horton     ; fi
   if [ $name = shreve_flow   ] ; then type=Int32     ; order=shreve     ; fi

   r.stream.order -a stream_rast=stream direction=dir elevation=elv  accumulation=flow  $order=order   memory=40000 --o --quiet
   r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type format=GTiff nodata=0     input=order  output=$SC/CompUnit_stream_order/order_${name}_$ID.tif
fi

if [ $name = vect_length ] ; then 
   r.stream.order.hack  stream_rast=stream direction=dir elevation=elv  accumulation=flow stream_vect=vect  memory=40000 --o --quiet
   v.out.ogr  --overwrite format=GPKG  input=vect output=$SC/CompUnit_stream_order/order_${name}_$ID.gpkg
fi 

if [ $name = vect_flow ] ; then 
   r.stream.order.hack -a  stream_rast=stream direction=dir elevation=elv  accumulation=flow stream_vect=vect  memory=40000 --o --quiet
   v.out.ogr  --overwrite format=GPKG  input=vect output=$SC/CompUnit_stream_order/order_${name}_$ID.gpkg
fi 

sleep 200
                                                                                                                          
EOF

echo elv msk flow stream dir | xargs -n 1 -P 1 bash -c $'
var=$1
rm -f $RAM/${var}_${ID}_msk_$name.tif  
' _ 

exit 

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then 
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc41_compUnit_stream_order  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc45_compUnit_stream_order_tile20d.sh
fi 

