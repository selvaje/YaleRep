#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc16_IDraster_aggregation.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc16_IDraster_aggregation.sh.%J.err
#SBATCH --job-name=sc16_IDraster_aggregation.sh
#SBATCH --mem=5G

####   sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc16_IDraster_aggregation.sh

ulimit -c 0

source ~/bin/gdal3          2>/dev/null
source ~/bin/pktools        2>/dev/null

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export QNT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

#### aggregate uniq tile IDraster  at uniq global IDraster 
rm -f $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDrt_IDru_all.txt
counter=0
for file in $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDr_h??v??.txt ; do
sort -k 5,5 $file > /tmp/$(basename $file)
awk -v counter=$counter  '{
    # If column 5 changes, increment the counter
    if ($5 != prev_value) {
        counter++
        prev_value = $5
    }
    # Print the original line with the new counter as the second column
    print $1,$2,$3,$4,$5,counter
}' /tmp/$(basename $file)  >> $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDrt_IDru_all.txt
rm -f  /tmp/$(basename $file)
counter=$( awk 'END { print $6 }' $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDrt_IDru_all.txt)
done 

### xsnap ysnap IDsegment IDrastertile IDrasterunique
### IDs_xsnap_ysnap_IDseg_IDrt_IDru_all.txt
### 

join -1 1 -2 1 <( sort -k 1,1 $IN/snapFlow_area/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_h??v??.txt  ) <( awk '{print $1 , $2 , $3 , $6 }' $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDrt_IDru_all.txt  |  sort -k 1,1 )  | sort -k 1,1 -g | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$14  }'    > $IN/snapFlow_txt/IDs_ximpr_yimpr_areaDB_xsnap_ysnap_areaSFD_dist_IDr_all.txt   

###  wc -l $IN/snapFlow_txt/IDs_ximpr_yimpr_areaDB_xsnap_ysnap_areaSFD_dist_IDr_all.txt   33929 
                                
awk '{print $4,$5,$1}'       $IN/snapFlow_txt/IDs_ximpr_yimpr_areaDB_xsnap_ysnap_areaSFD_dist_IDr_all.txt  > $IN/snapFlow_txt/ximpr_yimpr_IDs_all.txt
awk '{print $7,$8,$1,$11}'   $IN/snapFlow_txt/IDs_ximpr_yimpr_areaDB_xsnap_ysnap_areaSFD_dist_IDr_all.txt  > $IN/snapFlow_txt/xsnap_ysnap_IDs_IDr_all.txt

rm -f $IN/snapFlow_gpkg/ximpr_yimpr_IDs_all.gpkg
pkascii2ogr -a_srs epsg:4326 -f "GPKG" -x 0 -y 1 -n "IDstation"  -ot "Integer"   -i $IN/snapFlow_txt/ximpr_yimpr_IDs_all.txt   -o $IN/snapFlow_gpkg/ximpr_yimpr_IDs_all.gpkg
rm -f $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all.gpkg 
pkascii2ogr -a_srs epsg:4326   -f "GPKG" -x 0 -y 1 -n "IDstation" -ot "Integer" -n "IDraster" -ot "Integer" -i $IN/snapFlow_txt/xsnap_ysnap_IDs_IDr_all.txt  -o $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all.gpkg

# Equidistant Cylindrical Projection (Equirectangular Projection)
# Description: In this projection, distances are preserved along meridians and parallels. The projection is created by mapping latitudes and longitudes onto a regular grid, and it's useful for mapping regions close to the equator. However, distortion increases as you move away from the equator.
# Common Uses: World maps, thematic maps.
# EPSG Code:
# WGS 84 Equidistant Cylindrical (Plate Carrée): EPSG: 32662 (for WGS 84 datum).

### ????   after snapping, same station have been snap to the same raster pixel

rm -f $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all_eqdist.gpkg
ogr2ogr -t_srs EPSG:32662 $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all_eqdist.gpkg  $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all.gpkg  

### from this point on IDs = IDstation ; IDr = global uniq ID raster 

echo "IDs IDr Xcoord Ycoord" > $IN/snapFlow_txt/IDs_IDr_xcoord_ycoord.txt
paste -d " "  <(ogrinfo -al $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all_eqdist.gpkg   | grep "IDstation (Integer)")  \
              <(ogrinfo -al $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all_eqdist.gpkg   | grep "IDraster (Integer)")  \
              <(ogrinfo -al $IN/snapFlow_gpkg/xsnap_ysnap_IDs_IDr_all_eqdist.gpkg   | grep POINT ) \
    | sed  's/)/ /g' | sed  's/(/ /g' | awk '{ print $4,$8,$10,$11 }'  >> $IN/snapFlow_txt/IDs_IDr_xcoord_ycoord.txt

echo "IDs Xsnap Ysnap IDr Xcoord Ycoord" > $IN/snapFlow_txt/IDs_xsnap_ysnap_IDr_xcoord_ycoord.txt
join -1 3 -2 1  <(sort -k 3,3 $IN/snapFlow_txt/xsnap_ysnap_IDs_IDr_all.txt   ) <(awk '{if (NR>1) print }' $IN/snapFlow_txt/IDs_IDr_xcoord_ycoord.txt  | sort -k 1,1)  |  awk '{ print $1,$2,$3,$4,$6,$7}'   >> $IN/snapFlow_txt/IDs_xsnap_ysnap_IDr_xcoord_ycoord.txt

### IDstation IDraster Xcoord Ycoord (lon lat Equidistance)
### $IN/snapFlow_txt/IDs_xsnap_ysnap_IDr_xcoord_ycoord.txt

