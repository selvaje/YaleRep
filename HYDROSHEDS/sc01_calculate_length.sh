


# files in /gpfs/loomis/project/fas/sbsc/ga254/dataproces/HYDROSHEDS/shp30ses
# on my machine 
# 

for file in *.shp ;  ogr2ogr -t_srs 6965.prj   reprj_$file $file ; done
for file in *.shp ; do  ogr2ogr -t_srs 6965.prj   reprj_$file $file ; done 
for file in reprj_*.shp ; do n=$(basename $file .shp ) ; ogr2ogr  -dialect SQLite -sql "SELECT *, ST_Length(Geometry)  AS  LENGTH  FROM $n "  len_$file $file ; done
for file in len_reprj_*.shp ; do n=$(basename $file .shp ) ; ogr2ogr -t_srs EPSG:4326   wgs84_$file $file ; done

# recopy  on /gpfs/loomis/project/fas/sbsc/ga254/dataproces/HYDROSHEDS/shp30ses_lengt


# calculate the averall length 
for file in  wgs84_len_reprj_??_riv_30s.shp ; do  ogrinfo -al -geom=NO  $file  | grep LENGTH  | awk '{  sum=sum+$4/1000 } END { printf ("%i\n" ,   sum )  }' ; done  | awk '{  sum=sum+$1 } END { printf ("%i\n" ,   sum )  }'
#   23 890 627.9162 

#   
