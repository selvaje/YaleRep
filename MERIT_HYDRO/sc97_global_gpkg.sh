#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc97_global_gpkg.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc97_global_gpkg.sh.%A_%a.err
#SBATCH --mem=100G
#SBATCH --job-name=sc97_global_gpkg.sh
#SBATCH --array=1-3

ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc97_global_gpkg.sh

source ~/bin/gdal3

RAM=/dev/shm
HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO 

#  $HYDRO/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d/sub_catchment.tif  too big
#  $HYDRO/hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d/order_vect.vrt     too big

file=$(ls $HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d/basin.tif   \
          $HYDRO/hydrography90m_v.1.0/r.watershed/outlet_tiles20d/outlet.tif \
          $HYDRO/hydrography90m_v.1.0/r.watershed/depression_tiles20d/depression.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 )
filename=$(basename $file .tif)
dirname=$(dirname $file )

GDAL_CACHEMAX=80000


if [ $filename = basin  ] || [ $filename = sub_catchment   ] || [ $filename = outlet  ] || [ $filename = depression ]  ; then
echo $filename merge
rm -f  $dirname/$filename.gpkg 
cp $dirname/$filename.tif $RAM 
gdal_polygonize.py -8 $RAM/$filename.tif $dirname/$filename.gpkg  $filename   "ID"  
fi

exit

if [ $filename = order_vect.vrt  ] ; then
echo $filename merge
rm -f $dirname/order_vect.gpkg
ogr2ogr  -clipdstlayer merged  -t_srs EPSG:4326 -s_srs EPSG:4326  $dirname/order_vect.gpkg  $dirname/order_vect.vrt
fi

