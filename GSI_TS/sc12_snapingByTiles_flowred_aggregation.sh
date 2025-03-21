#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc12_snapingByTiles_flowred_aggregation.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc12_snapingByTiles_flowred_aggregation.sh.%J.err
#SBATCH --job-name=sc12_snapingByTiles_flowred_aggregation.sh  
#SBATCH --mem=5G

####   sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc12_snapingByTiles_flowred_aggregation.sh  

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export QNT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

#### aggregate uniq tile IDraster  at uniq global IDraster 
rm -f $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDru_flow_all.txt 
counter=0
for file in $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDr_flow_h??v??.txt ; do
sort -k 5,5 $file > /tmp/$(basename $file)
awk -v counter=$counter  '{
    # If column 1 changes, increment the counter
    if ($5 != prev_value) {
        counter++
        prev_value = $5
    }
    # Print the original line with the new counter as the second column
    print $1,$2,$3,$4,counter,$6
}' /tmp/$(basename $file)  >> $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDru_flow_all.txt 
rm -f  /tmp/$(basename $file)
counter=$( awk 'END { print $5 }' $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDru_flow_all.txt)
done 
### lat lon IDstation IDstream IDraster flow 
### x_y_snapFlowFinal_stream_IDru_flow_all.txt
### 40813 after snapping, same station have been snap to the same raster pixel conting 40165 uniq pixel 

rm -f $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all.gpkg
pkascii2ogr -f "GPKG" -x 0 -y 1 -n "IDstation"  -ot "Integer"  -n "IDstream" -ot "Integer" -n "IDraster" -ot "Integer" -n "Flow" -ot "Real" -i $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDru_flow_all.txt -o $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all.gpkg

# Equidistant Cylindrical Projection (Equirectangular Projection)
# Description: In this projection, distances are preserved along meridians and parallels. The projection is created by mapping latitudes and longitudes onto a regular grid, and it's useful for mapping regions close to the equator. However, distortion increases as you move away from the equator.
# Common Uses: World maps, thematic maps.
# EPSG Code:
# WGS 84 Equidistant Cylindrical (Plate Carrée): EPSG: 32662 (for WGS 84 datum).

### 40813  after snapping, same station have been snap to the same raster pixel

rm -f $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all_eqdist.gpkg 
ogr2ogr -t_srs EPSG:32662 $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all_eqdist.gpkg $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all.gpkg

echo "IDstation IDraster Xcoord Ycoord" > $IN/snapFlow_txt/x_y_snapFlowFinal_station_IDru_flow_all_eqdist.txt
paste -d " "  <(ogrinfo -al $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all_eqdist.gpkg | grep "IDstation (Integer)")  \
              <(ogrinfo -al $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all_eqdist.gpkg | grep "IDraster (Integer)")  \
              <(ogrinfo -al $IN/snapFlow_shp/x_y_snapFlowFinal_stream_IDru_flow_all_eqdist.gpkg | grep POINT ) \
      | sed  's/)/ /g' | sed  's/(/ /g' | awk '{ print $4,$8,$10,$11 }'  >> $IN/snapFlow_txt/x_y_snapFlowFinal_station_IDru_flow_all_eqdist.txt


echo "IDstation lon lat IDraster Xcoord Ycoord IDstream flow" > $IN/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_IDstream_flow.txt
join -1 3 -2 1  <(sort -g -k 3,3   $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDru_flow_all.txt) <(awk '{if (NR>1) print }' $IN/snapFlow_txt/x_y_snapFlowFinal_station_IDru_flow_all_eqdist.txt | sort -g -k 1,1)  |  awk '{ print $1,$2,$3,$7,$8,$9,$4,$6}'   >> $IN/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_IDstream_flow.txt

awk '{print $1,$2,$3,$4,$5,$6}'  $IN/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_IDstream_flow.txt  >  $IN/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt 

exit

### IDstation IDraster Xcoord Ycoord (lon lat Equidistance)
### x_y_snapFlowFinal_station_IDru_flow_all_eqdist.txt
### 40813 after snapping, same station have been snap to the same raster pixel counting 40165 uniq pixel 

