#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 07:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc05_hlakes_mergeVol.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc05_hlakes_mergeVol.sh.%J.err
#SBATCH --job-name=sc05_hlakes_mergeVol.sh
#SBATCH --mem-per-cpu=40000M

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/HydroLAKES/sc05_hlakes_mergeVol.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc05_hlakes_mergeVol.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

gdalbuildvrt -overwrite  $DIR/out/HydroLakes.vrt   $DIR/tif/final_*.tif

## mask the final output to keep continental areas
pksetmask -i $DIR/out/HydroLakes.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/out/HydroLAKES_Volume.tif -co COMPRESS=DEFLATE -co ZLEVEL=9
