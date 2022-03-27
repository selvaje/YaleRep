#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc22_compunitbufferLSTaggregation.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc22_compunitbufferLSTaggregation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/ssc22_compunitbufferLSTaggregation.sh.%J.err
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc22_compunitbufferLSTaggregation.sh


DIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst
RAM=/dev/shm

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7min.tif -msknodata -9999 -nodata -9999  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7min.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7min_mskbuf.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7max.tif -msknodata -9999 -nodata -9999  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7max.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7max_mskbuf.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7mean.tif -msknodata -9999 -nodata -9999  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7mean.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7mean_mskbuf.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7stdev.tif -msknodata -9999 -nodata -9999  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7stdev.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin_LST_MOYDmax_Day_spline_month7stdev_mskbuf.tif 



