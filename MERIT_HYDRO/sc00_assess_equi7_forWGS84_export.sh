#!/bin/bash                       
#SBATCH -p day 
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7_forWGS84_export.sh.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7_forWGS84_export.sh.sh.%J.err 
#SBATCH --mem-per-cpu=5000   
#SBATCH --job-name=sc00_assess_equi7_forWGS84_export.sh


#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7_forWGS84_export.sh


source ~/bin/gdal
source ~/bin/grass
source ~/bin/pktools

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
RAM=/dev/shm

grass76 -f $INDIR/test/grassdb/loc_wgs84/PERMANENT --exec  v.out.ogr  --overwrite format=ESRI_Shapefile  input=stream_v  type=line      output=$INDIR/test/stream_inWGS84.shp
