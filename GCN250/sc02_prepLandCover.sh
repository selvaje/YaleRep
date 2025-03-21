#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 7 -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_prepLandCover.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_prepLandCover.sh.%A.%a.err
#SBATCH --job-name=sc02_prepLandCover.sh
#SBATCH --mem-per-cpu=30000M

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GCN250/sc02_prepLandCover.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GCN250

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GCN250/sc02_prepLandCover.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

###  Land Cover is taken from ESA. The data here is read from the already processed images in scripts  /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC

#--- 1 STEP
#--- land cover data comes with a different resolution and extent.
#--- fix extent and resolution based on the soil layer (based on: pkinfo -i HYSOGs250m.tif -bb -dx -dy)

#--- 2 STEP
#--- fix the LC categories with no CN values to 0
#--- classes 210 water and 220 snow do not have curve numbers therefore will be assign a value of zero and nodata 255 for further calculation

export INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
export OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GCN250/LC


echo $(seq 2012 2018) | xargs -n 1 -P 7 bash -c $'
YEAR=$1

gdalwarp -of Gtiff -co COMPRESS=LZW -co ZLEVEL=9 -co TILED=YES -ot Byte -te -180.0 -56.0 180.0 84.0 -tr 0.002083333333333 -0.002083333333333 -t_srs EPSG:4326 $INDIR/ESALC_${YEAR}.tif $OUTDIR/temp_ESALC_${YEAR}.tif

pkreclass -i $OUTDIR/temp_ESALC_${YEAR}.tif -o $OUTDIR/ESALC_${YEAR}.tif -c 210 -r 0 -c 220 -r 0 -nodata 255 -ot Byte -co COMPRESS=LZW -co ZLEVEL=9

' _

rm $OUTDIR/temp_*.tif
