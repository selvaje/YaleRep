#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 12 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_bin_LSTextract1.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_bin_LSTextract1.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc30_bin_LSTextract1.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc30_bin_LSTextract1.sh

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

cat  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.txt    | xargs -n 1 -P 12  bash -c $' 
BIN6ID=$1 

awk -v BIN6ID=$BIN6ID  \'{if($2==BIN6ID) print }\'  $TAB/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump.txt  > $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump$BIN6ID.txt

# select ws that belong to bin6
join -1 1  -2 1   -a 1    <( awk \'{ print $1 }\'      $TAB/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump.txt | sort  | uniq | sort  ) \
                          <( awk \'{ print $1 , $1 }\' $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump$BIN6ID.txt | sort ) \
                          |  awk \'{ if (NF==1) { print $1, 0} else { print $1, 1}}\' > $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.txt

# reclass all the ws to 0 expet the one that intersect the bin 6 
pkreclass -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -code $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.txt \
  -i  $FIN/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif  -o $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.tif

geo_string=$(oft-bb $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.tif 1 | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\')

# crop and set mask  bin ws ls 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string   $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.tif $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif

rm -f $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.tif $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec.txt 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $(getCorners4Gtranslate $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif) $LST_MAX/LST_MOYDmax_Day_value.tif  $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_crop.tif

pksetmask -m  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif  -msknodata 0 -nodata -9999    -i   $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_crop.tif  -o  $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_crop_msk.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $(getCorners4Gtranslate $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif) $BIN/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}_crop.tif

pksetmask -m $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif -msknodata 0 -nodata 255 -i  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}_crop.tif  -o  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop_msk.tif

#  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}_crop_msk.tif

rm -f $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_bin_mean.csv
# add one to avoid 0 used as no-data 
oft-calc $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop_msk.tif  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop_msk1.tif <<EOF
1
#1 1 +
EOF

# transfer the -9999 of the lst to the bin and label as 0; 
pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9   -m $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_crop_msk.tif  -msknodata -9999 -nodata 0 -i  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop_msk1.tif  -o  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}_crop_msk0.tif

oft-stat -i $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_crop_msk.tif -o $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_bin_mean.txt  -um $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}_crop_msk0.tif -mm 
rm -f  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop1.tif  

awk \'{ if ($1!=255) { print $1 -1 , $2 , int($3) , int($4) , $5 , $6 } }\'  $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_bin_mean.txt | sort -k 1,1 -g   > $LST/LST_plot_bin/LST_MOYDmax_Day_value_${BIN6ID}rec_bin_meanLST.txt 

rm -f $LST/LST_MOYDmax_Day_value_${BIN6ID}rec_bin_mean.txt  
rm -f  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}*
rm -f $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop.tif  $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump${BIN6ID}rec_crop1.tif
rm -f $LST/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_${BIN6ID}*  
rm -f $LST/LST_MOYDmax_Day_value_${BIN6ID}*

' _

