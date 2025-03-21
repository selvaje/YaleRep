#!/bin/bash                       
#SBATCH -p day 
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7_forEqui7.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7_forEqui7.sh.%J.err 
#SBATCH --mem-per-cpu=5000   


#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7_forEqui7.sh 


source ~/bin/gdal
source ~/bin/grass
source ~/bin/pktools

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
RAM=/dev/shm

grass76 -f $INDIR/test/grassdb/loc_equi7/PERMANENT --exec  v.out.ogr  --overwrite format=ESRI_Shapefile  input=stream_v  type=line      output=$INDIR/test/stream_inEqui7.shp
