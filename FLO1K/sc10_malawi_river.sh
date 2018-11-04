
DIR=/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/FLO1K


# -projwin ulx uly lrx lry 


# Historical (1960-2015) yearly minimum, mean, maximum river discharge trends
# Plotted trends in graph; and data tables in CSV format for 2 coordinates:
# Kaweche: Lat -11.343991°; Long 33.851594°
# Thulwe: Lat  -11.019212°; Long 33.784922°


# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   FLO1K.ts.1960.2015.qav_mean.tif  allahabad/FLO1K.ts.1960.2015.qav_mean_allahabad.tif   
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   FLO1K.ts.1960.2015.qav_mean.tif  indus/FLO1K.ts.1960.2015.qav_mean_indus.tif   
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 FLO1K.ts.1960.2015.qav_mean.tif  yangtze/FLO1K.ts.1960.2015.qav_mean_yangtze.tif   


# Kaweche: Lat -11.343991°; Long 33.851594° 
paste  <(seq 1960 2015)    <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 33.851594 -11.343991  ) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc  33.851594 -11.343991 ) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc  33.851594 -11.343991 ) > $DIR/malawi/kaweche/kaweche_min_mean_max.txt

# Thulwe: Lat  -11.019212°; Long 33.784922°     33.784922  -11.019212
paste  <(seq 1960 2015)    <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc   33.784922  -11.019212  ) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc    33.784922  -11.019212 ) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc    33.784922  -11.019212  ) > $DIR/malawi/thulwe/thulwe_min_mean_max.txt


exit 


gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  allahabad/stream_allahabad.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  indus/stream_indus.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final20d/all_tif.vrt  yangtze/stream_yangtze.tif


gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  allahabad/lbasin_allahabad.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  69  29    70   28   /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  indus/lbasin_indus.tif   
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 116  30.5 117   29.5 /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/all_tif.vrt  yangtze/lbasin_yangtze.tif





