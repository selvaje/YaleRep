
cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K


# -projwin ulx uly lrx lry 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   FLO1K.ts.1960.2015.qav_mean.tif  allahabad/FLO1K.ts.1960.2015.qav_mean_allahabad.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   FLO1K.ts.1960.2015.qav_mean.tif  indus/FLO1K.ts.1960.2015.qav_mean_indus.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 FLO1K.ts.1960.2015.qav_mean.tif  yangtze/FLO1K.ts.1960.2015.qav_mean_yangtze.tif   



paste  <(seq 1960 2015)    <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qmi_invertlatlong.nc 81.903280 25.398918 ) <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qav_invertlatlong.nc 81.903280 25.398918 ) <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qma_invertlatlong.nc 81.903280 25.398918 ) > allahabad/allahabad_min_mean_max.txt

paste  <(seq 1960 2015)    <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qmi_invertlatlong.nc 69.7300 28.4380 ) <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qav_invertlatlong.nc 69.7300 28.4380 ) <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qma_invertlatlong.nc 69.7300 28.4380 ) > indus/indus_min_mean_max.txt

paste  <(seq 1960 2015)    <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qmi_invertlatlong.nc 116.5372 29.9131 ) <(gdallocationinfo -geoloc -valonly  FLO1K.ts.1960.2015.qav_invertlatlong.nc 116.5372 29.9131    ) <(gdallocationinfo -geoloc -valonly    FLO1K.ts.1960.2015.qma_invertlatlong.nc 116.5372 29.9131  ) > yangtze/yangtze_min_mean_max.txt

exit 


gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  allahabad/stream_allahabad.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  indus/stream_indus.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  yangtze/stream_yangtze.tif


gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  allahabad/lbasin_allahabad.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  indus/lbasin_indus.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  yangtze/lbasin_yangtze.tif





