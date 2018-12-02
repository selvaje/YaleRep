#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_LCesa_clumping.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_LCesa_clumping.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc31_LCesa_clumping.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc31_LCesa_clumping.sh 

export    FIN=/project/fas/sbsc/ga254/dataproces/GSHL/final_product_1k
export    BINCLUMP=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass 
export    BIN=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin
export    TAB=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_bin_table 

export    LCESA=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/LCESA
export    LST=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin
export    LST_MAX=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/LST_max
export    RAM=/dev/shm

# Upper Left  (-180.0000000,  80.0000000) (180d 0' 0.00"W, 80d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  80.0000000) (180d 0' 0.00"E, 80d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# echo -180 10  -90 80 a >  $RAM/tile.txt
# echo  -90 10    0 80 b >> $RAM/tile.txt
# echo    0 10   90 80 c >> $RAM/tile.txt
# echo   90 10  180 80 d >> $RAM/tile.txt

# echo -180 -60  -90 10 e >> $RAM/tile.txt
# echo  -90 -60    0 10 f >> $RAM/tile.txt
# echo    0 -60   90 10 g >> $RAM/tile.txt
# echo   90 -60  180 10 h >> $RAM/tile.txt

# cat   $RAM/tile.txt | xargs -n 5  -P 8 bash -c $' 

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $1 $4 $3 $2  $LCESA/LC190_Y2014.tif  $RAM/LC190_Y2014_$5.tif  
# pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 3 -dy 3 -d 3 -f mode -i   $RAM/LC190_Y2014_$5.tif -o $RAM/LC190_Y2014_${5}_1km.tif  

# ' _ 
# rm $RAM/tile.txt
# gdalbuildvrt    -overwrite  $RAM/LC190_Y2014.vrt   $RAM/LC190_Y2014_?_1km.tif  
# gdal_translate  -a_nodata 0    -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/LC190_Y2014.vrt  $LCESA/LC190_Y2014_1km.tif

# rm  $RAM/LC190_Y2014.vrt   $RAM/LC190_Y2014_?_1km.tif  

rm -r /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/cost1k_clump 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/ cost1k_clump  $LCESA/LC190_Y2014_1km.tif r.in.gdal 

r.clump -d  --overwrite  input=LC190_Y2014_1km    output=LC190_Y2014_1km_clump
r.out.gdal  --overwrite  nodata=0 -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff input=LC190_Y2014_1km_clump output=$LCESA/LC190_Y2014_1km_clump.tif 

exit 

