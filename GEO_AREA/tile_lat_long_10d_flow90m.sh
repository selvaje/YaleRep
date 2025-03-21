cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files

awk '{ if ($7>=-60) print $1 , $4 , $5 , $6 , $7 }' tile_lat_long_10d.txt  | awk '{ if ($3==90) {print $1 , $2,  85 , $4 , $5 } else {print} }' > tile_lat_long_10d_flow90m_dis.txt


echo "h36v10 180 85 191 80" >> tile_lat_long_10d_flow90m_dis.txt
echo "h36v11 180 80 191 75" >> tile_lat_long_10d_flow90m_dis.txt
echo "h36v12 180 75 191 70" >> tile_lat_long_10d_flow90m_dis.txt
echo "h36v13 180 70 191 65" >> tile_lat_long_10d_flow90m_dis.txt


cat /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_10d_flow90m_dis_noheader.txt  | xargs  -n 5 -P 10 bash -c $'
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $2 $3 $4 $5 /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk/all_tif_dis.vrt  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$1.tif

VAR=$(gdalinfo -mm  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$1.tif  2>&1   | grep ERROR | awk \'{print $1}\')

if [ -n "$VAR" ] ; then 
    rm /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$1.tif
else
    echo no rm /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$1.tif
fi 
' _



for file in $(ls  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/*.tif ) ; do basename $file .tif ; done   |  sed 's/msk_//g' | sort > /tmp/tile.txt

join -1 1 -2 1 <(sort  tile_lat_long_10d_flow90m_dis_noheader.txt   ) /tmp/tile.txt   | sort -g > tile_lat_long_10d_flow90m_land_dis_noheader.txt 

echo "Tile ULX ULY LRX LRY" > tile_lat_long_10d_flow90m_land_dis.txt
cat tile_lat_long_10d_flow90m_land_dis_noheader.txt >> tile_lat_long_10d_flow90m_land_dis.txt



