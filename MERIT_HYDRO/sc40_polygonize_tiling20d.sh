#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc40_polygonize_tiling20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc40_polygonize_tiling20d.sh.%A_%a.err
#SBATCH --job-name=sc40_polygonize_tiling20d.sh
#SBATCH --array=63,75
#SBATCH --mem=40G

####  1-116   

#### run basin as week
#### for var in  outlet lbasin basin  ; do  sbatch -p day  -t 24:00:00   --export=var=$var /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc40_polygonize_tiling20d.sh ; done
#### for var in  basin ; do  sbatch -p week  -t 7-00:00:00   --export=var=$var /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc40_polygonize_tiling20d.sh ; done

ulimit -c 0

source ~/bin/gdal3

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

###   SLURM_ARRAY_TASK_ID=111

export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export var=$var

if [ $var = outlet   ] ; then  
cp $SCMH/outlet_tiles_final20d_1p/outlet_${tile}.tif $RAM
rm -f $SCMH/outlet_polygonize_final20d/outlet_${tile}.gpkg 
gdal_polygonize.py -8  $RAM/outlet_${tile}.tif $RAM/outlet_${tile}.gpkg  outlet "ID"  
rm  $RAM/outlet_${tile}.tif
mv  $RAM/outlet_${tile}.gpkg    $SCMH/outlet_polygonize_final20d
fi 

if [ $var = lbasin  ]  ; then 
cp $SCMH/lbasin_tiles_final20d_1p/lbasin_${tile}.tif    $RAM
rm -f $SCMH/lbasin_polygonize_final20d/basin_${tile}.gpkg
gdal_polygonize.py -8 $RAM/lbasin_${tile}.tif           $RAM/basin_${tile}.gpkg   basin  "ID"  
rm  $RAM/lbasin_${tile}.tif 
mv  $RAM/basin_${tile}.gpkg  $SCMH/lbasin_polygonize_final20d
fi 

if [ $var = basin ]    ; then 
cp $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif $RAM
rm -f $SCMH/basin_polygonize_final20d/sub_catchment_${tile}.gpkg
gdal_polygonize.py -8 $RAM/basin_${tile}.tif            $RAM/sub_catchment_${tile}.gpkg  sub_catchment "ID" 
rm $RAM/basin_${tile}.tif 
mv $RAM/sub_catchment_${tile}.gpkg  $SCMH/basin_polygonize_final20d/  
fi



