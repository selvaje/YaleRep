
INDIR=/lustre0/scratch/ga254/dem_bj/WDPA/rasterize_all
# pkmosaic -i $INDIR/WDPA_point_Jan2014EPSG4326Buf.tif -i $INDIR/WDPA_point_Jan2014.tif -i  $INDIR/WDPA_point_Jan2014.tif  -cr max  -o $INDIR/WDPA_all.tif  


# extract the area for each cell 

rm -f /lustre0/scratch/ga254/dem_bj/WDPA/shp_out/360x114global_area_all.*

pkextract  -m  $INDIR/WDPA_all.tif   -msknodata 0  -i  /lustre0/scratch/ga254/dem_bj/GEO_AREA/area_tif/30arc-sec-Area_prj6974.tif \
-l  -r sum  -bn AREA_all   -lt String  -s /lustre0/scratch/ga254/dem_bj/WDPA/shp_grid/360x114global/360x114global.shp \
-o /lustre0/scratch/ga254/dem_bj/WDPA/shp_out/360x114global_area_all.shp





