#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_soilresp.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_soilresp.sh.%J.err
#SBATCH --job-name=sc02_soilresp.sh
#SBATCH --mem-per-cpu=10000M
#SBATCH --array=685-1344    ### start from 685, that is, from january 1958 (see file dates.txt below)

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/SOILRESP/sc02_soilresp.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILRESP

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILRESP/sc02_soilresp.sh

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILRESP


##  Original file is .nc format with 1344 bands, each band representing the mean soil respiration value for each month since 1901-01-01

##  Bands extraction will start from 1958 to resemble TERRACLIMATE data

##### Initial step is to create a file with the years and months to read through the array
# for i in $( seq 112); do seq -w 12 >> $DIR/meses.txt; done
# for j in $( seq 1901 1 2012);do
#     for i in $( seq 12); do echo $j >> $DIR/anos.txt; done
#   done
# paste $DIR/anos.txt $DIR/meses.txt > $DIR/dates.txt
# rm $DIR/anos.txt $DIR/meses.txt

#######---------------------------------------------------------

####  The original file, although in WGS84, is not center between -180 and 180 degres longitud BUT between 0 and 360!

## One solution given here: tested and worked!
# https://trac.osgeo.org/gdal/wiki/UserDocs/RasterProcTutorial   'virtual file'

## Second solution applied below: it also works.

BAND=$SLURM_ARRAY_TASK_ID
YEAR=$(cat $DIR/dates.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | awk '{ print $1 }' )
MM=$(cat $DIR/dates.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | awk '{ print $2 }' )

gdal_translate -b $BAND -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -of VRT  NETCDF:$DIR/RS_mon_Hashimoto2015.nc:co2 $DIR/temp/temp_${YEAR}_${MM}.vrt

gdal_translate  -a_srs WGS84  $DIR/temp/temp_${YEAR}_${MM}.vrt  $DIR/temp/temp_${YEAR}_${MM}.tif

gdalwarp -t_srs WGS84 $DIR/temp/temp_${YEAR}_${MM}.tif $DIR/out/soilResp_${YEAR}_${MM}.tif --config CENTER_LONG 0 -wo SOURCE_EXTRA=100 -overwrite

gdal_edit.py -a_ullr -180 90 180 -90 $DIR/out/soilResp_${YEAR}_${MM}.tif

rm $DIR/temp/temp_${YEAR}_${MM}.vrt $DIR/temp/temp_${YEAR}_${MM}.tif
