#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 5 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_gpgtd_preprocess.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_gpgtd_preprocess.sh.%J.err
#SBATCH --job-name=sc02_gpgtd_preprocess.sh
#SBATCH --array=1-12
#SBATCH --mem=40000

#ulimit -c 0    #### .core file remove

####  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GPGTD/sc02_gpgtd_preprocess.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GPGTD/

####  sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GPGTD/sc02_gpgtd_preprocess.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GPGDT
#export RAM=/gpfs/gibbs/pi/hydro/hydro/dataproces/GPGDT/temp
export RAM=/dev/shm
export OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GPGDT/out

export MM=$SLURM_ARRAY_TASK_ID
#export MM=1

##  METADATA FROM THE NC FILES
## -ot Int16
## NoData Value=-32767  (but by checking when unscaled the nodata value should be -5.68434e-14)
## add_offset=-499.9923704890517
## scale_factor=0.01525902189669642


ls $DIR/*_WTD_monthlymeans.nc | xargs -n 1 -P 5    bash -c $'

file=$1
filename=$(basename  $file .nc  )

export GDAL_CACHEMAX=5000

gdal_translate -unscale -a_nodata -5.68434e-14 -a_srs EPSG:4326 -ot Float32 -b $MM -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -of GTiff  NETCDF:$file:WTD $RAM/${filename}_${MM}.tif

corners=$(getCorners4Gtranslate $RAM/${filename}_${MM}.tif )
rnd_ul_x=$(LC_NUMERIC="en_US.UTF-8" printf "%.f" $(echo $corners | cut -d \' \' -f 1))
rnd_ul_y=$(LC_NUMERIC="en_US.UTF-8" printf "%.f" $(echo $corners | cut -d \' \' -f 2))
rnd_lr_x=$(LC_NUMERIC="en_US.UTF-8" printf "%.f" $(echo $corners | cut -d \' \' -f 3))
rnd_lr_y=$(LC_NUMERIC="en_US.UTF-8" printf "%.f" $(echo $corners | cut -d \' \' -f 4))

### clip the raster with rounded coords. and put it into a new GTiff   ###

gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcnodata -5.68434e-14 -dstnodata -9999 -te rnd_ul_x rnd_lr_y rnd_lr_x rnd_ul_y $RAM/${filename}_${MM}.tif $RAM/${filename}_${MM}_F.tif

' _

export GDAL_CACHEMAX=20000

gdalbuildvrt  -a_srs EPSG:4326 -srcnodata -9999 -vrtnodata -9999   $RAM/ALL_WTD_monthlymeans_${MM}.vrt    $RAM/*_WTD_monthlymeans_${MM}_F.tif

gdal_translate -a_srs EPSG:4326  -a_nodata -9999    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -of GTiff $RAM/ALL_WTD_monthlymeans_${MM}.vrt $OUT/ALL_WTD_monthlymeans_${MM}.tif

gdal_edit.py -a_ullr -180 84 180 -56 $OUT/ALL_WTD_monthlymeans_${MM}.tif

###  remove temporal files
rm -f  $RAM/*_WTD_monthlymeans_${MM}.tif $RAM/*_WTD_monthlymeans_${MM}_F.tif $RAM/ALL_WTD_monthlymeans_${MM}.vrt

exit
