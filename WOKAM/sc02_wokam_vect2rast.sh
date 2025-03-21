#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 5 -N 1
#SBATCH -t 15:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_wokam_vect2rast.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_wokam_vect2rast.sh.%A.%a.err
#SBATCH --job-name=sc02_wokam_vect2rast.sh
#SBATCH --mem-per-cpu=30000M


## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/WOKAM/sc02_wokam_vect2rast.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/WOKAM

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/WOKAM/sc02_wokam_vect2rast.sh


module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/WOKAM
export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt
export RAM=/dev/shm

# Unique values:
#
# 3,Continuous evaporite rocks
# 1,Continuous carbonate rocks
# 2,Discontinuous carbonate rocks
# 4,Mixed carbonate and evaporite rocks
# 5,Discontinuous evaporite rocks

echo 1 2 3 4 5 | xargs -n 1 -P 5 bash -c $'

CLASS=$1

ogr2ogr -sql "SELECT * FROM whymap_karst__v1_poly WHERE rock_type=$CLASS"  $RAM/wokam_${CLASS}.shp $DIR/shp/whymap_karst__v1_poly.shp

gdal_rasterize  -a_nodata 0 -tr 0.000833333333333 -0.000833333333333 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -a rock_type -l wokam_${CLASS} $RAM/wokam_${CLASS}.shp $RAM/wokam_${CLASS}.tif

## extend to the same as MERIT_HYDRO with zeros...
gdalwarp -te -180 -60 180 85 $RAM/wokam_${CLASS}.tif  -of VRT $RAM/wokam_${CLASS}_ext.vrt

pksetmask -i $RAM/wokam_${CLASS}_ext.vrt -m $MASKly -msknodata=-9999 -nodata=255 -co COMPRESS=DEFLATE -co ZLEVEL=9 -o $DIR/out/wokam_${CLASS}.tif

rm $RAM/wokam_${CLASS}.*

' _


exit

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH  jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/WOKAM/out/wokam_5.tif /home/jaime/data/WOKAM
# ##### testing
#
# CLASS=5
#
# ogr2ogr -sql "SELECT * FROM whymap_karst__v1_poly WHERE rock_type=$CLASS"  $DIR/temp/wokam_${CLASS}.shp $DIR/shp/whymap_karst__v1_poly.shp
#
# RES=0.0833333333333
# #-te 20.8 56.1 21.15 56.6
# gdal_rasterize -a_nodata 0 -tr $RES -$RES -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -a rock_type -l wokam_${CLASS}  $DIR/temp/wokam_${CLASS}.shp $DIR/temp/wokam_${CLASS}.tif
#
# gdalwarp -te -180 -60 180 85 $DIR/temp/wokam_${CLASS}.tif  $DIR/temp/wokam_${CLASS}_ext.tif
#
# #-te 20.8 56.1 21.15 56.6
# gdalwarp -tr $RES -$RES -co COMPRESS=DEFLATE -co ZLEVEL=9 $MASKly $DIR/temp/mask.tif
#
# pksetmask -i $DIR/temp/wokam_${CLASS}.tif -m $DIR/temp/mask.tif -msknodata=-9999 -nodata=255 -o $DIR/out/wokam_${CLASS}.tif -co COMPRESS=DEFLATE -co ZLEVEL=9
