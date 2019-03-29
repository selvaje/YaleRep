geo_string="-10.69  55.43 -5.41 51.40"

CT=irland

echo $geo_string

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upa/all_tif.vrt  $CT/upa_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upg/all_tif.vrt  $CT/upg_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/all_tif.vrt  $CT/elv_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/all_tif.vrt  $CT/dep_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dir/all_tif.vrt  $CT/dir_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/slope/tiles/all_tif.vrt        $CT/slope_MERIT.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /project/fas/sbsc/ga254/dataproces/LCESA/1998/LC160_Y1998.tif $CT/LC160_Y1998.tif 
