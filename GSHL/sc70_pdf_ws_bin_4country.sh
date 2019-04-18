#!/bin/bash
#SBATCH -p day
#SBATCH -J sc70_pdf_ws_bin_4country.sh 
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc70_pdf_ws_bin_4country.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc70_pdf_ws_bin_4country.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc70_pdf_ws_bin_4country.sh 

# ulimit

# remove file from yesterday
# find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr 


export  GSHL=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL
export  SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country
export  COUNT=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_tif
export  AREA=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif
export RAM=/dev/shm

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump.tif) $AREA/30arc-sec-Area_prj6974.tif $SCRATCH/30arc-sec-Area_prj6974.tif
# oft-stat-sum -i $SCRATCH/30arc-sec-Area_prj6974.tif -o $SCRATCH/ws_area.txt -um $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump.tif -nostd 
# awk '{  printf ( "%i %.2f\n" ,   $1,    $3/1000000 )   }'  $SCRATCH/ws_area.txt | sort -g -k 1,1  >   $SCRATCH/ws_areaKM2.txt 


awk  '{ print $1   }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_tif/gadm36_ID_GID_NAME.txt  | xargs -n 1 -P 8 bash -c $' 
CT=$1
geo_string=$( oft-bb $COUNT/gadm36_ID_0.tif $CT   | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\')
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string $COUNT/gadm36_ID_0.tif  $RAM/gadm36_ID_0_CT$CT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $RAM/gadm36_ID_0_CT$CT.tif )  $AREA/30arc-sec-Area_prj6974.tif $RAM/30arc-sec-Area_prj6974_CT$CT.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $RAM/gadm36_ID_0_CT$CT.tif )  $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump.tif $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_CT$CT.tif 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $RAM/gadm36_ID_0_CT$CT.tif )  $GSHL/final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump.tif    $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_CT$CT.tif 

pksetmask -m $RAM/gadm36_ID_0_CT$CT.tif  -msknodata $CT -p ! -nodata 0 -i $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_CT$CT.tif -o  $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_CT${CT}_msk.tif
pksetmask -m $RAM/gadm36_ID_0_CT$CT.tif  -msknodata $CT -p ! -nodata 0 -i $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_CT$CT.tif $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_CT${CT}_msk.tif

oft-stat-sum -i $RAM/30arc-sec-Area_prj6974_CT$CT.tif  -o $RAM/ws_area_CT$CT.txt -um $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_CT${CT}_msk.tif   -nostd
oft-stat-sum -i $RAM/30arc-sec-Area_prj6974_CT$CT.tif  -o $RAM/bin_area_CT$CT.txt -um $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_CT${CT}_msk.tif   -nostd

awk \'{  printf ( "%i %.2f\\n" ,   $1,    $3/1000000 )   }\'  $RAM/ws_area_CT$CT.txt  | sort -g -k 1,1  >   $SCRATCH/ws_areaKM2_CT$CT.txt
awk \'{  printf ( "%i %.2f\\n" ,   $1,    $3/1000000 )   }\'  $RAM/bin_area_CT$CT.txt | sort -g -k 1,1  >   $SCRATCH/bin_areaKM2_CT$CT.txt

rm $RAM/30arc-sec-Area_prj6974_CT$CT.tif $RAM/gadm36_ID_0_CT$CT.tif 
rm $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_CT${CT}_msk.tif      $RAM/ws_area_CT$CT.txt
rm $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_CT${CT}_msk.tif  $RAM/bin_area_CT$CT.txt

' _ 







exit 



plot the boxplot R 

CHN  = read.table("ws_areaKM2_CT49.txt") 
CAN = read.table("ws_areaKM2_CT42.txt")
NLD = read.table("ws_areaKM2_CT158.txt")
IND  = read.table("ws_areaKM2_CT105.txt") 
ITA = read.table("ws_areaKM2_CT112.txt")
GBR = read.table("ws_areaKM2_CT242.txt")
USA = read.table("ws_areaKM2_CT243.txt")

boxplot (log(ITA$V2) , log(GBR$V2)  , log(USA$V2)  , log(NLD$V2)  , log(CAN$V2) , log(CHN$V2) , log(IND$V2) ,xaxt = 'n'  , xlab="Country"  , ylab="log(AREA) in km2" )
axis(1, at=1:7, labels=c("ITA" , "GBR" , "USA"  , "NLD" , "CAN" ,"CHN" ,"IND" )  )




