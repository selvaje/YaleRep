#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_fromGeohub2Pangaea.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_fromGeohub2Pangaea.sh.%J.err
#SBATCH --mem-per-cpu=10000

# for TOPO in geom dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness eastness dx dxx dxy dy dyy pcurv tcurv roughness tpi tri vrm cti spi slope convergence ; do sbatch --export=TOPO=$TOPO   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc11_fromGeohub2Pangaea.sh ; done 


DIR=/project/fas/sbsc/ga254/dataproces/MERIT

# remove overview 


gdal_translate --config GDAL_CACHEMAX 8000  -a_ullr  -180  87.370833333333333 180  -62 -co COPY_SRC_OVERVIEWS=YES   -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $DIR/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif $DIR/pangaea250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif

# gdaladdo -clean  $DIR/pangaea250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif
# gdaladdo --config GDAL_CACHEMAX 8000  -r nearest $DIR/pangaea250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif  2 4 8 16 32 64 128





