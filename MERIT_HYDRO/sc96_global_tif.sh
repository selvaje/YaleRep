#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout/sc96_global_tif.sh.%A_%a.out  
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr/sc96_global_tif.sh.%A_%a.err
#SBATCH --mem=100G
#SBATCH --job-name=sc96_global_tif.sh
#SBATCH --array=1

#### --array=1-42

ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc96_global_tif.sh

source ~/bin/gdal3

### r.watershed

HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO 
# file=$(ls    $HYDRO/hydrography90m_v.1.0/*/*/*.vrt   | head -$SLURM_ARRAY_TASK_ID | tail -1 )
# filename=$(basename $file .vrt)
# dirname=$(dirname $file )

GDAL_CACHEMAX=80000

# gdal_translate --config GDAL_NUM_THREADS 2 --config  GDAL_CACHEMAX 80000  \
# -co BLOCKXSIZE=512 -co BLOCKYSIZE=512  -co BIGTIFF=YES  -co TILED=YES  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
# $file $dirname/$filename.tif 

# cp $dirname/$filename.tif $dirname/${filename}_ovr.tif 
# gdaladdo --config GDAL_NUM_THREADS 2 --config COMPRESS_OVERVIEW DEFLATE --config  GDAL_CACHEMAX 80000 --config BIGTIFF_OVERVIEW IF_NEEDED -r nearest $dirname/${filename}_ovr.tif 8 16 32 64 

# gdal_translate -of COG  --config GDAL_NUM_THREADS 2 --config   GDAL_CACHEMAX 80000 --config    GDAL_TIFF_OVR_BLOCKSIZE 512  --config BIGTIFF_OVERVIEW IF_NEEDED    \
#    -co BIGTIFF=YES   -co COMPRESS=DEFLATE $dirname/${filename}_ovr.tif  $dirname/${filename}_cog.tif

# gdal_translate  --config GDAL_NUM_THREADS 2 --config   GDAL_CACHEMAX 80000 --config    GDAL_TIFF_OVR_BLOCKSIZE 512  --config BIGTIFF_OVERVIEW IF_NEEDED    \
#  -co "TILED=YES"    -co BIGTIFF=YES   -co COMPRESS=DEFLATE   -co ZLEVEL=9 -co BLOCKXSIZE=512 -co BLOCKYSIZE=512    $dirname/${filename}_cog.tif  $dirname/${filename}_cogT.tif

# rm $dirname/${filename}_tmp.tif  

# done manualy to allow to be load in the igb server 
gdal_translate  -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin -180 85 0 -60 $HYDRO/hydrography90m_v.1.0/flow.index/cti_tiles20d/cti_ovr.tif  $HYDRO/hydrography90m_v.1.0/flow.index/cti_tiles20d/cti_ovr_W.tif 
gdal_translate  -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 0 85 180 -60 $HYDRO/hydrography90m_v.1.0/flow.index/cti_tiles20d/cti_ovr.tif $HYDRO/hydrography90m_v.1.0/flow.index/cti_tiles20d/cti_ovr_E.tif 
