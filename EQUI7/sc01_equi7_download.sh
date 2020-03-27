Files downloaded form 
https://github.com/TUW-GEO/Equi7Grid/tree/master/equi7grid/grids

# create proj4

for DIR in $( ls )  ; do gdalsrsinfo  -o proj4   /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/$DIR/GEOG/EQUI7_V13_${DIR}_GEOG_TILE_T6.prj > /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/${DIR}/GEOG/EQUI7_V13_${DIR}_GEOG_TILE_T6.proj4 ; done

for DIR in $( ls )  ; do gdalsrsinfo  -o proj4   /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/$DIR/PROJ/EQUI7_V13_${DIR}_PROJ_TILE_T6.prj > /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/${DIR}/PROJ/EQUI7_V13_${DIR}_PROJ_TILE_T6.proj4 ; done 




for file in *inEQUI7.tif ; do   gdal_edit.py -a_srs   '+proj=aeqd +lat_0=53 +lon_0=24 +x_0=5837287.81977 +y_0=2121415.69617 +datum=WGS84 +units=m +no_defs '     $file ; done 

