#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc99_crop.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc99_crop.sh.%J.err
#SBATCH --mem-per-cpu=10000

# intensity exposition range variance elongation azimuth extend width 

# for TOPO in dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness easthness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence geom ; do for RESN in  0.25 ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc99_crop.sh ; done ; done 

P=$SLURM_CPUS_PER_TASK
export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm
export TOPO=$TOPO

gdal_translate -projwin 0 80 160 10 --config GDAL_CACHEMAX 8000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif $SCRATCH/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif
