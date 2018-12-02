#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_gdalwarp_mask_wgs84_merge.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_gdalwarp_mask_wgs84_merge.sh.%A.%a.err
#SBATCH --job-name=sc03_gdalwarp_mask_wgs84_merge.sh
#SBATCH --array=1-310

# 310 tiles 
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRWL/sc03_gdalwarp_mask_wgs84_merge.sh

# cd /project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01
# for file in *.tif ; do echo ${file:0:6} ; done  | sort | uniq > tile_list.txt 

tile=$( head  -n  $SLURM_ARRAY_TASK_ID  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84/tile_list.txt  | tail  -1 ) 

INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84_merge
RAM=/dev/shm

# in case of overlay bands with src nodata = 0 , gdaltranslate merge all the bands considering transparent the nodata . the option separate is not needed. It has been tested
gdalbuildvrt  -overwrite  -srcnodata 0 -vrtnodata 0      $RAM/${tile}.vrt  $INDIR/${tile}_???.tif
gdal_translate  -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${tile}.vrt  $OUTDIR/${tile}.tif 
rm    $RAM/${tile}.vrt 
exit

### this is another option it is safer in case pixel values overalp                                                 
 

gdalbuildvrt  -overwrite  -separate  $RAM/${tile}.vrt  $INDIR/${tile}_???.tif
BAND=$(pkinfo -nb -i    $RAM/${tile}.vrt    | awk '{ print $2 }' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${tile}.vrt  $OUTDIR/${tile}.tif ; rm -f $RAM/${tile}.vrt
else 
echo start statporfile
pkstatprofile -nodata -9999 -of GTiff  -f max -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -i  $RAM/${tile}.vrt -o   $RAM/${tile}.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${tile}.tif  $OUTDIR/${tile}.tif 
rm -f  $RAM/${tile}.tif   $RAM/${tile}.vrt 
fi 





