#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 2:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_gdalwarp_mask_wgs84.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_gdalwarp_mask_wgs84.sh.%a.err
#SBATCH --job-name=sc02_gdalwarp_mask_wgs84.sh
#SBATCH --array=1-1148

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRWL/sc02_gdalwarp_mask_wgs84.sh

# data from https://zenodo.org/record/1297434#.W4_713XBjNP

file=$(ls /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84/*.tif  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 ) 
filename=$(basename $file .tif )

INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84

  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/30arc-sec-Area_prj28.tif


gdalwarp -ot Byte -wm 2000  -srcnodata 0 -dstnodata 0 -te  $( getCorners4Gwarp $file) -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326 -tr 0.00027777777777 0.00027777777777 -r near   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01/all_tif.vrt  $OUTDIR/$filename.tif 

MAX=$(pkstat -max -i   $OUTDIR/$filename.tif  | awk '{ print $2 }' )
if [ $MAX -eq  0 ] ; then 
rm -f  $OUTDIR/$filename.tif 
fi



