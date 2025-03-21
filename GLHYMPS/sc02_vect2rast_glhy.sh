#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_vect2rast_glhy.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_vect2rast_glhy.sh.%J.err
#SBATCH --job-name=sc02_vect2rast_glhy.sh
#SBATCH --mem-per-cpu=30000M
#SBATCH --array=1-162  ### there are 162 teils

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GLHYMPS/sc02_vect2rast_glhy.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GLHYMPS

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLHYMPS/sc02_vect2rast_glhy.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS
RAM=$DIR/temp

LINE=$( cat $DIR/tiles20D.txt  | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
#LINE=$( cat $DIR/tiles20D.txt  | head -n 92 | tail -1 )


XMIN=$(echo $LINE | awk '{ print $1 }' )
YMIN=$(echo $LINE | awk '{ print $2 }' )
XMAX=$(echo $LINE | awk '{ print $3 }' )
YMAX=$(echo $LINE | awk '{ print $4 }' )
LABE=$(echo $LINE | awk '{ print $5 }' )


###  Porosity
gdal_rasterize  -tr 0.000833333333333 -0.000833333333333 -a_nodata -9999 -te $XMIN $YMIN $XMAX $YMAX -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -a Porosity -l Final_GLHYMPS_Polygon $DIR/glhymps_ll.gpkg $RAM/porosity_${LABE}.tif

MAXPO=$(pkstat -max  -i    $RAM/porosity_${LABE}.tif     | awk '{ printf "%.2f\n", $2 }')
if [ $(echo "  $MAXPO  >  0  "  | bc ) -eq 0 ]; then rm -f $RAM/porosity_${LABE}.tif ; exit; fi

### Permeability
gdal_rasterize  -tr 0.000833333333333 -0.000833333333333 -te $XMIN $YMIN $XMAX $YMAX -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -a Permeability_permafrost -l Final_GLHYMPS_Polygon $DIR/glhymps_ll.gpkg $RAM/permeability_${LABE}.tif
