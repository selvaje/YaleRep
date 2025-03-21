#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_rasterize_vector.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_rasterize_vector.sh.%A.%a.err
#SBATCH --job-name=sc01_rasterize_vector.sh
#SBATCH --array=1-829

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRWL/sc01_rasterize_vector.sh

# data from https://zenodo.org/record/1297434#.W4_713XBjNP

INDIR=/gpfs/gibbs/pi/hydro/ga254/dataproces/GRWL/GRWL_vector_V01.01
OUTDIR=/gpfs/gibbs/pi/hydro/ga254/dataproces/GRWL/GRWL_vector_to_rast

# file=/gpfs/gibbs/pi/hydro/ga254/dataproces/MERIT/equi7/dem/EU/EU_048_000.tif

file=$(ls $INDIR/*.shp  | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
filename=$(basename $file .shp )


rm -f $OUTDIR/tmp_$filename.tif   $OUTDIR/$filename.tif 
gdal_rasterize   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES      -te $( getCornersOgr4Gwarp $file | awk '{ print int($1-1), int($2-1), int($3+1), int($4+1) }' ) -init -9999 -a_nodata -9999  -tr 0.00027777777777 0.00027777777777 -ot Int32 -a "width_m" -l $filename  $file  $OUTDIR/tmp_$filename.tif 
gdal_translate  -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9  $OUTDIR/tmp_$filename.tif   $OUTDIR/$filename.tif 
rm -f $OUTDIR/tmp_$filename.tif 
