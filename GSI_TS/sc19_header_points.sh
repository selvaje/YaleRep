
source ~/bin/gdal3
source ~/bin/pktools 

export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS

ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d/order_vect_point_h??v??.gpkg | xargs -n 1 -P 4 bash -c $'
file=$1
echo $file  
ogrinfo -al -sql "SELECT fid, prev_str01, geom FROM merged WHERE prev_str01 = 0" $file | grep POINT | awk \'{ gsub("\\\(","") ; gsub("\\\)","") ;  print $2, $3  }\'   >  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d/$(basename $file .gpkg)_header.txt
' _ 

###IDstation  40813
###IDstation 900000+ for header points 

### IDstation lat lon IDraster 
### header station are already in uniq IDraster                           ### from 5000 to 2000 re-run for having 2000
cat /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d/order_vect_point_h??v??_header.txt | shuf -n 2000 | awk '{print NR+900000,$1,$2,NR+900000}' >  $IN/headerFlow_txt/IDstation_lon_lat_IDraster.txt 
awk '{print $2,$3,$1}'   $IN/headerFlow_txt/IDstation_lon_lat_IDraster.txt  > $IN/headerFlow_txt/lon_lat_IDstation.txt
awk '{print $1,$2,$3}'   $IN/headerFlow_txt/IDstation_lon_lat_IDraster.txt  > $IN/headerFlow_txt/IDstation_lon_lat.txt

rm -f $IN/headerFlow_shp/IDstation_lon_lat.gpkg
pkascii2ogr -f "GPKG" -x 0 -y 1 -n "IDstation"  -ot "Integer" -i $IN/headerFlow_txt/lon_lat_IDstation.txt -o $IN/headerFlow_shp/IDstation_lon_lat.gpkg

# Equidistant Cylindrical Projection (Equirectangular Projection)
# Description: In this projection, distances are preserved alon meridians and parallels. The projection is created by mapping latitudes and lonitudes onto a regular grid, and it s useful for mapping regions close to the equator. However, distortion increases as you move away from the equator.
# Common Uses: World maps, thematic maps.
# EPSG Code:
# WGS 84 Equidistant Cylindrical (Plate Carrée): EPSG: 32662 (for WGS 84 datum).

rm -f $IN/headerFlow_shp/IDstation_lon_lat_eqdist.gpkg 
ogr2ogr -t_srs EPSG:32662 $IN/headerFlow_shp/IDstation_lon_lat_eqdist.gpkg $IN/headerFlow_shp/IDstation_lon_lat.gpkg 

echo "IDstation Xcoord Ycoord" > $IN/headerFlow_txt/IDstation_Xcoord_Ycoord.txt
paste -d " "  <(ogrinfo -al $IN/headerFlow_shp/IDstation_lon_lat_eqdist.gpkg | grep "IDstation (Integer)")  <(ogrinfo -al $IN/headerFlow_shp/IDstation_lon_lat_eqdist.gpkg | grep POINT )  | sed  's/)/ /g' | sed  's/(/ /g'  |  awk '{ print $4,$6,$7 }'  >> $IN/headerFlow_txt/IDstation_Xcoord_Ycoord.txt

echo "IDstation lon lat IDraster Xcoord Ycoord" > $IN/headerFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt
join -1 1 -2 1  <(sort  -k 1,1 $IN/headerFlow_txt/IDstation_lon_lat.txt  ) <( sort  -k 1,1 $IN/headerFlow_txt/IDstation_Xcoord_Ycoord.txt )  |  awk '{ print $1,$2,$3,$1,$4,$5}'   >> $IN/headerFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt
