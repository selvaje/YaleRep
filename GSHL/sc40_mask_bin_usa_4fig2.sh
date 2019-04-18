

DIR=/project/fas/sbsc/ga254/dataproces/GSHL/shp

# gdal_rasterize -co COMPRESS=DEFLATE -co ZLEVEL=9 -te $( getCornersOgr4Gwarp *.shp | awk '{ print int($1) -1, int($2), int($3),  int($4) + 1}' ) -a_nodata 0 -ot Byte -burn 1 -tr 0.00833333333333  0.00833333333333 $DIR/USA_adm_contermin.shp $DIR/USA_adm_contermin.tif


gdal_translate -projwin  $(getCorners4Gtranslate  $DIR/USA_adm_contermin.tif )   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct_USA.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/USA_adm_contermin.tif  -msknodata 0   -nodata 255  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct_USA.tif -o  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct_USA_msk.tif 




gdal_translate -projwin  $(getCorners4Gtranslate  $DIR/USA_adm_contermin.tif )  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_USA.tif   

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/USA_adm_contermin.tif  -msknodata 0   -nodata 255  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_USA.tif     -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_USA_msk.tif   

