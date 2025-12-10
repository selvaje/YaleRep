###

SOIL=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2

for file in $SOIL/sand/sand_acc_sfd/intb/sand_0-200cm_EUA_*.tif ; do
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 32.8075 41.7666666667 38.4133333333 38.4208333333 $file $SOIL/sfd_assesment/tur_$(basename $file) 
done 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 32.8075 41.7666666667 38.4133333333 38.4208333333 /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif   accumulation_sfd.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 32.8075 41.7666666667 38.4133333333 38.4208333333 /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction.tif  direction.tif

ogr2ogr  -spat  32.8075 38.4208333333 38.4133333333 41.7666666667 order_vect_segment_tur.gpkg /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/all_gpkg_vect_segment_dis.vrt 

