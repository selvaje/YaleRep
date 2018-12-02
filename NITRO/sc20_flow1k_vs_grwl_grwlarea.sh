#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_flow1k_vs_grwl_grwlarea.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_flow1k_vs_grwl_grwlarea.sh.%A.%a.err
#SBATCH --job-name=sc20_flow1k_vs_grwl_grwlarea.sh
#SBATCH --array=1-310

# 310 GRWL tils 
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc20_flow1k_vs_grwl_grwlarea.sh

file=$( ls /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84_merge/*.tif |  head  -n  $SLURM_ARRAY_TASK_ID     | tail  -1 ) 
tile=$(basename $file )

# tile=h10v03.tif

NITRO=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO
 AREA=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/area 
AREAK=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/area_1km
 ARC1=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/1arc-sec-Area_prj6965
 GRWL=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_mask_V01.01_wgs84_merge

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $GRWL/$tile -msknodata 0 -msknodata 0 -i $ARC1/$tile  -o   $AREA/$tile 
pkfilter  -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 20 -dy 30 -d 30 -f sum                -i $AREA/$tile  -o  $AREAK/$tile  


# done later on by end 
# gdalbuildvrt  -srcnodata 0 -vrtnodata 0  gwrl_area1km.vrt *.tif 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  gwrl_area1km.vrt gwrl_area1km.tif
