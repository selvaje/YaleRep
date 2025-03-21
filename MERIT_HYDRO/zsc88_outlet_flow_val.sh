#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc88_outlet_flow_val.sh.%A_%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc88_outlet_flow_val.sh.%A_%a.err
#SBATCH --job-name=sc88_outlet_flow_val.sh
#SBATCH --array=1-116
#SBATCH --mem=10G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc88_outlet_flow_val.sh 

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export ID=$SLURM_ARRAY_TASK_ID

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls $SC/outlet_tiles_final20d_1p/outlet_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file .tif | sed 's/outlet_//g' ) 


grass78  -f -text --tmp-location  -c $file  <<'EOF'

r.external   input=$file        output=outlet_r        --overwrite 
r.to.vect input=outlet_r  output=outlet_p type=point  --overwrite 
v.out.ogr  input=outlet_p  type=point output=$SC/outlet_polygonize_final20d/outletP_$tile.gpkg      format=GPKG --overwrite 
EOF

ogrinfo -al $SC/outlet_polygonize_final20d/outletP_$tile.gpkg  | grep POINT  | awk '{ gsub("[()POINT]","") ;  print $1,$2 }' > $SC/outlet_polygonize_final20d/outletP_$tile.xy

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate $file)  $MERIT/upa/all_tif_dis.vrt  $RAM/upa_$tile.tif

rm -rf $SC/flow_tiles_val/outlet_flow_$tile.csv  $SC/flow_tiles_val/outlet_upa_$tile.csv
pkextractogr -f CSV -srcnodata -9999    -buf 3 -r max -i $SC/flow_tiles/flow_${tile}_pos.tif -s $SC/outlet_polygonize_final20d/outletP_$tile.gpkg -o $SC/flow_tiles_val/outlet_flow_$tile.csv
pkextractogr -f CSV -srcnodata -9999999 -buf 3 -r max -i $RAM/upa_${tile}.tif                -s $SC/outlet_polygonize_final20d/outletP_$tile.gpkg -o $SC/flow_tiles_val/outlet_upa_$tile.csv

paste -d " " $SC/outlet_polygonize_final20d/outletP_$tile.xy  \
<(awk -F , '{ if(NR>1) print $NF  }'   $SC/flow_tiles_val/outlet_flow_$tile.csv) \
<(awk -F , '{ if(NR>1) print $NF  }'   $SC/flow_tiles_val/outlet_upa_$tile.csv ) \
> $SC/flow_tiles_val/outlet_flow_upa_${tile}.xyb

rm $SC/flow_tiles_val/outlet_upa_$tile.csv $SC/flow_tiles_val/outlet_flow_$tile.csv 

# at point location 
# paste -d " " $SC/outlet_polygonize_final20d/outletP_$tile.xy \
# <(gdallocationinfo -valonly -geoloc $SC/flow_tiles/flow_${tile}_pos.tif < $SC/outlet_polygonize_final20d/outletP_$tile.xy ) \
# <(gdallocationinfo -valonly -geoloc $RAM/upa_${tile}.tif                < $SC/outlet_polygonize_final20d/outletP_$tile.xy ) \
# > $SC/flow_tiles_val/outlet_flow_$tile.xy 

rm -f  $RAM/upa_$tile.tif
if [ $SLURM_ARRAY_TASK_ID = 116  ] ; then 
sleep 1000
cat $SC/flow_tiles_val/outlet_flow_*.xy  > $SC/flow_tiles_val/all_outlet_flow.xy 
cat $SC/flow_tiles_val/outlet_flow_upa_*.xyb  > $SC/flow_tiles_val/outlet_flow_upa3.xyb
fi 


