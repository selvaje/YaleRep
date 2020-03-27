


EQUI7=/project/fas/sbsc/ga254/dataproces/EQUI7

HGEOG=/gpfs/loomis/project/sbsc/ga254/dataproces/HydroBASINS/GEOG
HPROJ=/gpfs/loomis/project/sbsc/ga254/dataproces/HydroBASINS/PROJ

source ~/bin/gdal 

ogr2ogr -t_srs "$EQUI7/grids/EU/${CT}/PROJ/EQUI7_V13_EU_PROJ_ZONE.prj"   $HPROJ/hybas_eu_lev02_v1c.shp  $HGEOG/hybas_eu_lev02_v1c.shp 


exit 




for CT  in  AF  AN  AS  EU  NA  OC  SA ; do

if [ $CT  = 'AF' ] ; then CTL=af ; fi 
if [ $CT  = 'AN' ] ; then CTL= ; fi 
if [ $CT  = 'AS' ] ; then CTL= ; fi 
if [ $CT  = 'EU' ] ; then CTL= ; fi 
if [ $CT  = 'NA' ] ; then CTL= ; fi 

  AN  AS  EU  NA  OC  SA ; do



ogr2ogr   -t_srs "$EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj"   $HGEOG/hybas_??_lev02_v1c.shp ; do       $HGEOG/hybas_??_lev02_v1c.shp 

done 
