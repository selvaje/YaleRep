#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_data_prep4arrow_plot.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_data_prep4arrow_plot.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc30_data_prep4arrow_plot.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc30_data_prep4arrow_plot.sh

export    FIN=/project/fas/sbsc/ga254/dataproces/GSHL/final_product_1k
export    BINCLUMP=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass 
export    BIN=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin
export    TAB=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table 
export    LST=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin
export    LST_MAX=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/LST_max/
export    RAM=/dev/shm/

# london bin7 id 1614 

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $BINCLUMP/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_clump.tif  -msknodata 0 -nodata 0  -i $BINCLUMP/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif -o $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif 

# pkstat -hist -i $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif  | grep -v " 0" | awk '{ if ($1!=0) {print $1}}'  > $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.txt 
# rm -f $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif 

#  gdallocationinfo -valonly   -geoloc   $BINCLUMP/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif  -0.120770  51.514611  london 

cat  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.txt | head 