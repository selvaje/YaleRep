#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00   
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_rasterize_water.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_rasterize_water.sh.%A.%a.err
#SBATCH --job-name=sc02_rasterize_water.sh
#SBATCH --mem=20G
#SBATCH --array=1-12

######  1-21 array
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/OPENSTREETMAP/sc02_rasterize_water.sh

source ~/bin/gdal

export INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/OPENSTREEMAP/water

### SLURM_ARRAY_TASK_ID=1
file=$( ls /gpfs/gibbs/pi/hydro/hydro/dataproces/OPENSTREEMAP/water/*/*.shp  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 ) 
filename=$( basename $file .shp    ) 
DIR=$( dirname $file  )

gdal_rasterize --config GDAL_CACHEMAX 15000  -burn 1  -tr 0.000833333333333333333 0.000833333333333333333  -ot Byte   -a_srs EPSG:4326 -a_nodata 0   \
-te $(getCornersOgr4Gwarp  $file   | awk '{ printf("%3.1f %3.1f %3.1f %3.1f\n", $1 - 0  , $2  - 0 , $3  + 0 , $4  + 0  ) }' ) \
-co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co TILED=YES    $file  $INDIR/tif_90m/${filename}.tif 


