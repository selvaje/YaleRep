


gdaltindex  /tmp/basin.gpkg  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d/basin.tif 

# Equidistant Cylindrical Projection (Equirectangular Projection)
# Description: In this projection, distances are preserved along meridians and parallels. The projection is created by mapping latitudes and longitudes onto a regular grid, and it's useful for mapping regions close to the equator. However, distortion increases as you move away from the equator.
# Common Uses: World maps, thematic maps.
# EPSG Code:
# WGS 84 Equidistant Cylindrical (Plate Carrée): EPSG: 32662 (for WGS 84 datum).

ogr2ogr -t_srs EPSG:32662   /tmp/basin_EPSG32662.gpkg   /tmp/basin.gpkg

ogr2ogr -t_srs EPSG:32662   /tmp/point_EPSG32662.gpkg   /tmp/point.gpkg


use the  /tmp/basin_EPSG32662.gpkg  to create the grass location

set 
