#!/bin/sh
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc08_rename_dataset.sh%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_rename_dataset.sh%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc08_rename_dataset.sh

# riname final dataset 

DIR=/project/fas/sbsc/ga254/dataproces/GSHL
OUTDIR=/project/fas/sbsc/ga254/dataproces/GSHL/final_product_1k

# for BIN in 1 2 3 4 5 6 7 8 9 ; do 
# cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin${BIN}_clump.tif 
# done 

# cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump.tif

# cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump.tif $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_peak_clump.tif 

# cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin.tif

# cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump.tif


# printf  "WATERSHED-ID\tBIN1-ID\tBIN2-ID\tBIN3-ID\tBIN4-ID\tBIN5-ID\tBIN6-ID\tBIN7-ID\tBIN8-ID\tBIN9-ID\n"  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin1-9_clump.txt >   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_bin1-9_clump.txt 
# cat   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin1-9_clump.txt >>   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_bin1-9_clump.txt 

# printf  "WATERSHED-ID\tPEAK-ID\tBIN-LEVEL\n"    >  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_peak_clump_bin.txt 
# cat  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_bin.txt  >> $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_peak_clump_bin.txt 







gdal_polygonize.py -f "ESRI Shapefile"    $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump.tif   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump.shp 

exit 

