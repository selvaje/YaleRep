#!/bin/bash
#SBATCH -p day
#SBATCH -J sc05_computationalUNIT_1k.sh
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_computationalUNIT_1k.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_computationalUNIT_1k.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc05_computationalUNIT_1k.sh  

export DIR=/project/fas/sbsc/ga254/dataproces/GSHL


# full process more than 4 our


echo 1 2 3 4 5 6 7 8 9  | xargs -n 1 -P 8  bash -c $'
BIN=$1
RAM=/dev/shm

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif -msknodata 0 -nodata 0    -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif  -o $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clumpBIN$BIN.tif  

oft-stat  -mm -noavg -nostd -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif -o  $RAM/compunit_bin${BIN}_tmp.txt    -um  $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clumpBIN$BIN.tif 

# ci sono casi in cui in un segment ci sono piu bin 

awk \'{ print $1 , $2 , int($3) , int($4) }\'  $RAM/compunit_bin${BIN}_tmp.txt |  sort -k 3,3  > $RAM/compunit_bin${BIN}_tmp_smin.txt
pkstat --hist -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif | grep -v " 0" | sort -k 1,1   > $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt 

join -1 3 -2 1 $RAM/compunit_bin${BIN}_tmp_smin.txt $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt | sort -k 4,4   > $RAM/compunit_bin${BIN}_tmp_sminSize.txt
join -1 4 -2 1 $RAM/compunit_bin${BIN}_tmp_sminSize.txt $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt | awk \'{  print $3, $4, $2 , $1 ,$5 , $6 }\'  > $RAM/compunit_bin${BIN}_tmp_sminSize_smaxSize.txt

awk \'{ if ($3==$4)  { print $1 , $3 } else { if ($5>$6 ) { print $1 , $3 } else { print $1, $4  } }   }\'  $RAM/compunit_bin${BIN}_tmp_sminSize_smaxSize.txt | sort -k 1,1  >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin${BIN}.txt  

' _ 

pkstat --hist -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif  | sort -k 1,1 | awk '{  if($1!=0) { print $1 } }'   >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/ws_clump_msk_clump.txt


join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/ws_clump_msk_clump.txt   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin1.txt | awk '{ if (NF==1) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin1_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin1_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin2.txt  | awk '{ if (NF==2) { print $0  , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin2_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin2_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin3.txt  | awk '{ if (NF==3) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin3_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin3_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin4.txt  | awk '{ if (NF==4) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin4_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin4_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin5.txt  | awk '{ if (NF==5) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin5_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin5_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin6.txt  | awk '{ if (NF==6) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin6_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin6_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin7.txt  | awk '{ if (NF==7) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin7_ws.txt
join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin7_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin8.txt  | awk '{ if (NF==8) { print $0 , 0 } else { print } }' >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin8_ws.txt

join -1 1 -2 1 -a 1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin8_ws.txt     $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin9.txt  | awk '{ if (NF==9) { print $0 , 0 } else { print } }'  | sort -k 1,1 -g > $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_compunit.txt

exit 






echo start merge the single file 

paste -d " "  <( awk '{  print $1, $2 }' $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin1.txt )   <( awk '{  print $2 }' $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin2.txt ) <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin3.txt )   <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin4.txt ) <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin5.txt )   <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin6.txt )  <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin7.txt ) <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin8.txt ) <( awk '{  print $2 }'  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin9.txt )  >  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_compunit.txt 


# rm -f $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_compunit/compunit_bin?.txt






