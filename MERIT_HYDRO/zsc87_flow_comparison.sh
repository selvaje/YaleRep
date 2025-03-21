#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc87_flow_comparison.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc87_flow_comparison.sh.%A_%a.err
#SBATCH --job-name=sc87_flow_comparison.sh
#SBATCH --array=116
#SBATCH --mem=10G

# sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc87_flow_comparison.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls $SC/outlet_tiles_final20d_1p/outlet_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file .tif | sed 's/outlet_//g' ) 

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate $file)  $MERIT/upa/all_tif_dis.vrt  $RAM/upa_$tile.tif 
pkfilter -nodata -9999     -co COMPRESS=DEFLATE -co ZLEVEL=9  -dx 10 -dy 10 -d 10 -f max -i $RAM/upa_$tile.tif   -o $RAM/upa_${tile}_10p.tif 
rm $RAM/upa_$tile.tif  

pkfilter -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9  -dx 10 -dy 10 -d 10 -f max -i $SC/flow_tiles/flow_${tile}_pos.tif -o $RAM/flow_${tile}_pos_10p.tif


grass78  -f -text --tmp-location  -c $RAM/flow_${tile}_pos_10p.tif   <<'EOF'
r.external   input=$RAM/flow_${tile}_pos_10p.tif        output=flow      --overwrite 
r.external   input=$RAM/upa_${tile}_10p.tif             output=upa       --overwrite 
r.mapcalc "index  = ( (flow - upa) / (flow + upa) ) * 1000000"  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32   format=GTiff nodata=-9999999 input=index   output=$SC/flow_tiles_val/index_$tile.tif 
EOF



if [ $SLURM_ARRAY_TASK_ID = 116   ] ; then 
sleep 1000
gdalbuildvrt  -srcnodata -9999999 -vrtnodata -9999999  -overwrite  $SC/flow_tiles_val/all_index.vrt  $SC/flow_tiles_val/index_*.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles_val/all_index.vrt   $SC/flow_tiles_val/all_index.tif 

fi 


exit 

gdal_translate  -projwin  -40  40 40 -40    all_index.tif       all_index.asc
gdal_translate  -projwin  -40  40 40 -40    slope_1KMmedian_MERIT_E7.tif  slope_1KMmedian_MERIT_E7.asc 

awk '{ if (NR>6) { for (col=1; col<=NF; col++) printf "%s\n", $col  } }' slope_1KMmedian_MERIT_E7.asc   > slope_1KMmedian_MERIT_E7.txt
awk '{ if (NR>6) { for (col=1; col<=NF; col++) printf "%s\n", $col  } }' all_index.asc  > all_index.txt 


paste  -d " " slope_1KMmedian_MERIT_E7.txt  all_index.txt  | grep  -v \\-9999 > slope_flowindex.txt 
