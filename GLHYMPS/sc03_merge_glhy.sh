#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2  -N 1
#SBATCH -t 12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_merge_glhy.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_merge_glhy.sh.%J.err
#SBATCH --job-name=sc03_merge_glhy.sh
#SBATCH --mem-per-cpu=40000M

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GLHYMPS/sc03_merge_glhy.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GLHYMPS

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLHYMPS/sc03_merge_glhy.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS

export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

echo porosity permeability | xargs -n 1 -P 2 bash -c $'

VAR=$1

gdalbuildvrt -overwrite  $DIR/temp/${VAR}_global.vrt $DIR/temp/${VAR}_*.tif

pksetmask -i $DIR/temp/${VAR}_global.vrt -m $MASKly  -co COMPRESS=DEFLATE -co ZLEVEL=9 -msknodata=-9999 -nodata=-9999 -o $DIR/out/${VAR}_global.tif

' _

rm $DIR/temp/*

exit
