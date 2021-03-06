cd /mnt/data2/scratch/GMTED2010/solar_radiation/

ls nsrdb/monthstats_txt/ | awk '{  gsub(".txt","") ; gsub("c","") ; print   }' | sort -k 1,1  > nsrdb/geo_file/nsrdb_stations.txt
join -1 1 -2 1  nsrdb/geo_file/nsrdb_stations.txt    <(awk -F ","  '{ if (NR>1) print $1 , $5 , $4  }' /mnt/data2/scratch/GMTED2010/solar_radiation/nrel/csv/TMY3_StationsMeta.csv  | sort -k 1,1)  > nsrdb/geo_file/nsrdb_stations_x_y.txt


echo '"X","Y","CODE"' > /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.csv
awk   '{ print $2","$3","$1 }'  nsrdb/geo_file/nsrdb_stations_x_y.txt >> /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.csv  

echo "<OGRVRTDataSource>" > /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "    <OGRVRTLayer name=\"point_nsrdb\">" >>  /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "        <SrcDataSource>/mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.csv</SrcDataSource>"  >> /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "	      <GeometryType>wkbPoint</GeometryType>"  >> /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "	      <GeometryField encoding=\"PointFromColumns\" x=\"X\" y=\"Y\" z=\"CODE\" /> "  >>  /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "    </OGRVRTLayer>"  >>  /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt
echo "</OGRVRTDataSource>"  >>  /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt

rm -f /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.shp
ogr2ogr /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.shp  /mnt/data2/scratch/GMTED2010/solar_radiation/shp/point_nsrdb.vrt

