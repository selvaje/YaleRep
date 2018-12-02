#!/bin/bash
#SBATCH -p day
#SBATCH -J sc06_loockup_table_1k.sh
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_loockup_table_1k.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_loockup_table_1k.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc06_loockup_table_1k.sh

export    DIR=/project/fas/sbsc/ga254/dataproces/GSHL
export OUTDIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table

echo -180 15  -90 80 a >  $DIR/tile.txt
echo  -90 15    0 80 b >> $DIR/tile.txt
echo    0 15   90 80 c >> $DIR/tile.txt
echo   90 15  180 80 d >> $DIR/tile.txt

echo -180 -60  -90 15 e >> $DIR/tile.txt
echo  -90 -60    0 15 f >> $DIR/tile.txt
echo    0 -60   90 15 g >> $DIR/tile.txt
echo   90 -60  180 15 h >> $DIR/tile.txt


# create a table with core clump (coming from the bin-clump) and watershed clump and bin level. 

cat $DIR/tile.txt   | xargs -n 5  -P 8 bash -c $' 

# washed masked solo per il peak
gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_core.tif $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_core_$5.txt

# core clumped con il valore del bin-clump 
gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump.tif    $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump_$5.txt

# core con il valore del bin 
gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_bin_ct.tif  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_bin_ct_$5.txt

paste <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_core_$5.txt )  \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump_$5.txt  )  \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_bin_ct_$5.txt )  \
               | uniq | sort | uniq >  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_bin_$5.txt 

rm $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_core_$5.txt  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump_$5.txt $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_bin_ct_$5.txt  

rm $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_core_$5.tif   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump_$5.tif  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_bin_ct_$5.tif  

' _

cat $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_bin_?.txt  | sort -g  | uniq | awk '{ if ($1 != 0 ) { print } }'   > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_bin.txt
rm $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_bin_?.txt 


exit


rm -f $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_core_clump_?.txt

# create a table with all bin clump and watershed clump 

cat $DIR/tile.txt | xargs -n 5  -P 8 bash -c $' 

for BIN in 1 2 3 4 5 6 7 8 9 ; do 
gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_$5.txt
done 

paste <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin1_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin2_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin3_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin4_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin5_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin7_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin8_clump_$5.txt) \
      <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_clump_$5.txt) \
| uniq | sort | uniq >  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_binALL_clump_$5.txt 

rm -f $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_$5.txt $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin?_clump_$5.txt

' _

cat $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_binALL_clump_?.txt | awk '{ if ($1!=0) {  if ($2!=0)  print }  }'  | sort -g | uniq > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin1-9_clump.txt

rm -f $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_binALL_clump_?.txt 


# table peak bin 
# table ws-clump bin-level-clump

# cat $DIR/tile.txt   | xargs -n 5  -P 8 bash -c $' 

# gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_$5.txt

# gdal_translate -of XYZ -projwin  $1 $4 $3 $2 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_$5.txt

# paste <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_$5.txt) <(cut -d " " -f 3 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_$5.txt) | uniq | sort | uniq >  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump_$5.txt 

# rm $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_$5.txt

# ' _

# cat $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump_?.txt | awk '{if ($2!=0) {if($1!=0) print }}'  | sort -g -k 1,1  -k 2,2 | uniq > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump.txt

# rm -f $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_bin_clump_?.txt
