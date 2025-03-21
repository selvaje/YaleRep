#!/bin/bash
#SBATCH -n 1 -c 3 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdoutord/sc41_compUnit_stream_order.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderrord/sc41_compUnit_stream_order.sh.%A_%a.err

##### array 116 ### 45 array for patagoinia bid35 , 53 array for patagoinia bid42
ulimit -c 0

##### raster that run under 24 hours 
##### for name in strahler  topo shreve hack horton vect ; do sbatch -p scavenge  -t 24:00:00 --array=1-166 --mem=150G  --export=name=$name  --job-name=sc41_compUnit_stream_order_$name.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order.sh ; done
##### raster thatdo not run under 24 hours 

### for name in vect; do sbatch -p day   -t 24:00:00 --array=1,28,38,42,45,53,115,116,121,125,126,131,134,136,138,139,142,144,145,147,153,158,163,83,96  --mem=150G --export=name=$name --job-name=sc41_compUnit_stream_order_$name.sh /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order.sh; done

# missing 92,87,80,34,35,26

### join -v 1 -1 2 -2 1 <(   ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}_enlarg/bid*_msk.tif   | awk '{ gsub ("bid", " ") ; gsub("_" , " " ) ; print  NR ,  $6  }' | sort -k 2,2  ) <(   ls   /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/vect/*.gpkg   | awk '{ gsub ("\\.", " ") ; gsub("_" , " " ) ; print   $6  }' | sort )  | awk '{ printf ("%i,", $2) }' | sed  's/,$//'  > /tmp/array.list    ### $2=array

### for name in vect; do sbatch -p day -t 24:00:00 --array=$(cat /tmp/array.list)  --mem=200G --export=name=$name --job-name=sc41_compUnit_stream_order_$name.sh /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc41_compUnit_stream_order.sh; done


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

echo elv msk flow dir  | xargs -n 1 -P 1 bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_${name}_ord.tif 
' _ 

cp $SC/CompUnit_stream_uniq_reclas/stream_uniq_${ID}.tif  $RAM/stream_uniq_${ID}_ord.tif

grass78  -f -text --tmp-location  -c $RAM/elv_${ID}_msk_${name}_ord.tif  <<'EOF'

r.external  input=$RAM/stream_uniq_${ID}_ord.tif   output=stream    --overwrite  

for var in  elv msk flow dir ; do
r.external  input=$RAM/${var}_${ID}_msk_${name}_ord.tif     output=$var       --overwrite  
done

r.mask raster=msk --o 

####### r.stream.order  https://grass.osgeo.org/grass78/manuals/addons/r.stream.order.html
GRASS_VERBOSE=1

## if -a is specified than r.stream.order uses accumulation raster map instead of cumulated stream length to determine main branch at bifurcation. 
## Works well only with stream network produced with SFD algorithm. 
## so flow not used anymore 

if [ $name = strahler ] || [ $name = topo ] || [ $name = horton ] || [ $name = shreve ] || [ $name = hack ] ; then  

if [ $name = strahler        ] ; then type=Byte   ;  fi   
if [ $name = topo            ] ; then type=Int32   ;  fi # contrallare il data type alla fine 
if [ $name = horton          ] ; then type=Int32   ;  fi
if [ $name = shreve          ] ; then type=Int32   ;  fi
if [ $name = hack            ] ; then type=Byte    ;  fi

r.stream.order.hack.orig  stream_rast=stream direction=dir elevation=elv  accumulation=flow $name=order  --o --quiet
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=$type format=GTiff  nodata=0 input=order  output=$SC/CompUnit_stream_order/${name}/order_${name}_$ID.tif
gdalinfo -mm  $SC/CompUnit_stream_order/${name}/order_${name}_$ID.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3) , int($4) }'  > $SC/CompUnit_stream_order/${name}/order_${name}_$ID.mm
touch $SC/CompUnit_stream_order/${name}/order_${name}_$ID.tif.done
fi 

if [ $name = vect ] ; then 
   r.stream.order.hack.orig  stream_rast=stream direction=dir elevation=elv  accumulation=flow stream_vect=vect  --o --quiet
   v.info -c map=vect
   echo start v.out.ogr
   v.out.ogr  --overwrite format=GPKG type=point  input=vect output=$SC/CompUnit_stream_order/${name}/order_${name}_point_$ID.gpkg   &
   v.out.ogr  --overwrite format=GPKG type=line   input=vect output=$SC/CompUnit_stream_order/${name}/order_${name}_segment_$ID.gpkg &
   v.out.ogr  --overwrite format=GPKG  input=vect output=$SC/CompUnit_stream_order/${name}/order_${name}_$ID.gpkg
   ogrinfo -al -so  $SC/CompUnit_stream_order/${name}/order_${name}_$ID.gpkg > $SC/CompUnit_stream_order/${name}/order_${name}_$ID.info
   touch $SC/CompUnit_stream_order/${name}/order_${name}_$ID.gpkg.done
fi 

sleep 200
                                                                                                                          
EOF

echo elv msk flow stream dir | xargs -n 1 -P 1 bash -c $'
var=$1
rm -f $RAM/${var}_${ID}_msk_${name}_ord.tif  
' _ 
rm -f $RAM/stream_uniq_${ID}_ord.tif

exit 

if [  $SLURM_ARRAY_TASK_ID -eq 166  ] ; then 
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc41_compUnit_stream_order  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc45_compUnit_stream_order_tile20d.sh
fi 

