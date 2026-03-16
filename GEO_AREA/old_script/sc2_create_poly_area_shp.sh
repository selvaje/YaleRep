

rm GMTED2010_30arc-sec-IDcol-proj[1-9]*.*

for prj in 28 6842 6965 6974 ; do
    ogr2ogr   -t_srs  prj/$prj.prj    GMTED2010_30arc-sec-IDcol-proj$prj.shp      GMTED2010_30arc-sec-IDcol-proj.shp  
    ./addattr-area.py   GMTED2010_30arc-sec-IDcol-proj$prj.shp Area
    ogrinfo -al  GMTED2010_30arc-sec-IDcol-proj$prj.shp | grep Area | awk '{ if (NF==4) print $4 }'  > matrix_area_prj$prj.asc
done 
