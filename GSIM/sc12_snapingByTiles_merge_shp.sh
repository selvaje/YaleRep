#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 1 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_snapingByTiles_merge_shp.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_snapingByTiles_merge_shp.sh.%J.err
#SBATCH --job-name=sc12_snapingByTiles_merge_shp.sh
#SBATCH --mem=5G

####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc12_snapingByTiles_merge_shp.sh

ulimit -c 0
source ~/bin/gdal3

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping


cd $SNAP/snapFlow_shp

rm -f ./consolidated.*
consolidated_file="./consolidated.shp"
for i in $(find . -name 'x_y_snapFlowFinal_*.shp'); do
    if [ ! -f "$consolidated_file" ]; then
        # first file - create the consolidated output file
        ogr2ogr -f "ESRI Shapefile" $consolidated_file $i
    else
        # update the output file with new file content
        ogr2ogr -f "ESRI Shapefile" -update -append $consolidated_file $i
    fi
done

rm -f x_y_snapFlowFinal.*
ogr2ogr  x_y_snapFlowFinal.shp   consolidated.shp 

rm -f consolidated.*

awk '{  if ($4!=2) print $3 , $1 , $2 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/snapFlow/x_y_snapFlowFinal_*.txt | sort -k 1,1 >   /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/snapFlow/ID_x_y_snapFlowFinal.txt
