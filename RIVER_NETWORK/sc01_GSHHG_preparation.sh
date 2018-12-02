#  bsub -W 14:00  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_GSHHG_preparation.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_GSHHG_preparation.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc01_GSHHG_preparation.sh

DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG
RAM=/dev/shm/
# # enlarge of 4 pixels the rasterize cost line and use it to mask out the ocean in the dem 

# cleanram 

# scp  ga254@omega.hpc.yale.edu:/lustre/scratch/client/fas/sbsc/ga254/dataproces/GSHHG/GSHHS_tif_250m_merge/GSHHS_land_mask250m.tif  $DIR 
# scp  ga254@omega.hpc.yale.edu:/lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/be75_grd_tif/be75_grd.tif  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem

gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin -180 +84 +180 -60 $DIR/GSHHS_land_mask250m.tif  $DIR/GSHHS_land_mask250m_crop.tif 
pkcreatect -min 0 -max 1 > /dev/shm/color.txt 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct  /dev/shm/color.txt   -i $DIR/GSHHS_land_mask250m_crop.tif -o $DIR/GSHHS_land_mask250m_crop_ct.tif

rm -fr  $DIR/../grassdb/loc_Cost
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2.sh $DIR/../grassdb  loc_Cost $DIR/GSHHS_land_mask250m_crop.tif 

# echo grow  # change to 8.01 to be sure that there is always water orroudn the islands. 
r.grow  input=GSHHS_land_mask250m_crop   output=GSHHS_land_mask250m_enlarge  old=1 new=1   radius=16.01  --overwrite
r.mapcalc "GSHHS_land_mask250m_enlarge01  = if ( isnull(GSHHS_land_mask250m_enlarge), 0 , 1 )"   --overwrite
# # echo clump
r.clump -d  --overwrite    input=GSHHS_land_mask250m_enlarge01      output=GSHHS_land_mask250m_enlarge_clump

r.out.gdal nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=Byte    input=GSHHS_land_mask250m_enlarge       output=$DIR/GSHHS_land_mask250m_enlarge.tif
r.out.gdal nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=GSHHS_land_mask250m_enlarge_clump output=$DIR/GSHHS_land_mask250m_enlarge_clump.tif 

pkcreatect -min 0 -max 2 > /dev/shm/color.txt 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i $DIR/GSHHS_land_mask250m_enlarge.tif -o $DIR/GSHHS_land_mask250m_enlarge_ct.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
              -m  $DIR/GSHHS_land_mask250m_crop.tif  -msknodata 0  -nodata -9999 \
              -m  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd.tif  -msknodata -32768   -nodata -9999  \
              -i  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd.tif  -o  $DIR/../dem/be75_grd_Land.tif

SEA=$( pkstat --hist -i   $DIR/GSHHS_land_mask250m_enlarge_clump.tif   | sort -g -k 2,2 | tail -1 | awk '{  print $1  }'   )   # 30586 pixel value for the sea 

# usefull to mask the sea in the dem and also r.watershed 
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $( echo $SEA - 0.5 | bc ) -max $( echo $SEA  + 0.5 | bc ) -data 0 -nodata 1 -ct  /dev/shm/color.txt   -i   $DIR/GSHHS_land_mask250m_enlarge_clump.tif  -o  $DIR/GSHHS_land_mask250m_enlarge_clumpMSK.tif 
gdal_edit.py -a_nodata 0  $DIR/GSHHS_land_mask250m_enlarge_clumpMSK.tif    

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
          -m  $DIR/GSHHS_land_mask250m_enlarge_clump.tif  -msknodata $SEA -nodata -9999 \
          -m  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd.tif     -msknodata -32768  -nodata -9999 \
          -i  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd.tif     -o  $DIR/../dem/be75_grd_LandEnlarge.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m  $DIR/GSHHS_land_mask250m_enlarge_clumpMSK.tif    -nodata 100  -msknodata 0 \
                    -i /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence_250m.tif \
                    -o /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence_250m_bordermskclumpMSK_ct.tif
gdal_edit.py -a_nodata -1  /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence_250m_bordermskclumpMSK_ct.tif

# questo parte in automatico ma poi controllare a mano gli ID  delle isole per  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc03_compunit.sh  
bsub -W 8:00  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_compunit.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_compunit.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc02_compunit.sh



