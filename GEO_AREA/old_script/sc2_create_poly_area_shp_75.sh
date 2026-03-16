

rm shp/GMTED2010_75arc-sec-IDcol-proj[1-9]*.*

for prj in 28 6842 6965 6974 ; do
    # ogr2ogr   -t_srs  prj/$prj.prj    shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp      shp/GMTED2010_75arc-sec-IDcol-proj.shp  
    # scripts/addattr-area.py   shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp Area
    ogrinfo -al  shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp | grep Area | awk '{ if (NF==4) print $4 }'  > asc/matrix_area_prj$prj.asc
done 

