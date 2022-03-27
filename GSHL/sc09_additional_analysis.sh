#!/bin/sh
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_additional_analysis.sh%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_additional_analysis.sh%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc09_additional_analysis.sh

# riname final dataset 
# bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc09_additional_analysis.sh

GSHL=/project/fas/sbsc/ga254/dataproces/GSHL

# pkfilter -ot Byte  -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 10 -dy 10 -d 10 -f countid -i  $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump.tif -o $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_count.tif
# pkfilter -ot Byte   -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 10 -dy 10 -d 10 -f countid -i  $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin.tif  -o $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_count.tif -msknodata 0 -nodata 0 -i $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count.tif -o $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count_0.tif
mv $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count_0.tif  $GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count.tif

exit 

