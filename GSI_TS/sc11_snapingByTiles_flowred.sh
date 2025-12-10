#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_snapingByTiles.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_snapingByTiles.sh.%A_%a.err
#SBATCH --job-name=sc11_snapingByTiles.sh
#SBATCH --mem=16G
#SBATCH --array=1-116

### testing 58    h18v02    1-116
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc11_snapingByTiles_flowred.sh

####  wc -l   quantiles/x_y_ID.txt  40813  # this are uniq pare of lat lon 
####  wc -l   quantiles/x_y.txt   orig_txt/x_y_ID_*.txt  41234 29 punti   lost because they are in antartica 
####  wc -l   snapFlow_txt_red/x_y_snapFlowYesSnap_*.txt   snapFlow_txt_red/x_y_snapFlowNoSnap_*.txt 41234 
####  wc -l   snapFlow_txt_red/x_y_snapFlowFinal_stream_flow_*.txt   41213 

ulimit -c 0

source ~/bin/gdal3     2>/dev/null
source ~/bin/pktools   2>/dev/null

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export QNT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export INP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_red
export Q=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
# SLURM_ARRAY_TASK_ID=58

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=112  ##### array  112    ID 96  small area for testing 

export file=$(ls $MH/CompUnit_stream_uniq_tiles20d/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )      ## select the tile file 
export filename=$(basename $file .tif  )
export TILE=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

~/bin/echoerr $file 
echo          $file 
########################         
# select all the points that fall inside the tile
#### old    paste -d " " $QNT/x_y_ID.txt <( gdallocationinfo -geoloc -valonly $file  <  <(awk '{print $1, $2 }' $QNT/x_y_ID.txt) ) | awk '{if (NF==4) print $1, $2,$3 }'  > $RAM/x_y_ID_$TILE.txt

#### old    awk '{ print $1, $2 }'  $RAM/x_y_ID_$TILE.txt >  $RAM/x_y_$TILE.txt

##### quantiles/station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt 41264 

paste -d " " <( awk '{if(NR>1) print $1,$4,$5}'  $Q/station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt )  <( gdallocationinfo -geoloc -valonly $file  <  <( awk '{if(NR>1) print $4,$5}'   $Q/station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt  ) ) | awk '{if (NF==4) print $1, $2,$3,$4 }'  > $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt 

if [ -s $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt   ] ; then

awk '{ print $2, $3 , $1 }'  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt   > $RAM/x_y_ID_$TILE.txt     

cp  $RAM/x_y_ID_$TILE.txt                       $INP
cp  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt  $INP

# pkascii2ogr -f "GPKG" -n "GSI_TM_no" -ot "Integer"    -i $IN/orig_txt/x_y_ID_$TILE.txt  -o $IN/orig_shp/x_y_orig_ID_$TILE.gpkg   # crate a shapefile 

export GDAL_CACHEMAX=15000 

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment.vrt  $RAM/stream_${TILE}_msk.tif # create  file tile  that is larger  
  
gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif    $RAM/flow_${TILE}_msk.tif    # create  file tile  that is larger  

module load GRASS/8.2.0-foss-2022b   2>/dev/null
## for installatioin
## grass --text ~/grassdb/nc_spm_08_grass7/PERMANENT/
##  g.extension extension=r.stream.segment     url=/home/ga254/grass_addons/src/raster/r.stream.segment 
grass  -f --text --tmp-location  $RAM/stream_${TILE}_msk.tif  <<'EOF'

for var in flow stream ; do 
r.external  input=$RAM/${var}_${TILE}_msk.tif     output=$var       --overwrite     # import the files  (mask) 
done
rm -f $IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt $IN/snapFlow_txt_red/x_y_snapFlowYesSnap_$TILE.txt

for n in $(seq 1 21 ) ; do 
echo "loop $n" wc $N2befor
if [ $n -eq 1  ] ; then INPOINT=$RAM/x_y_ID_$TILE.txt  ; fi 
if [ $n -gt 1  ] ; then INPOINT=$IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt   ; fi 

v.in.ascii in=$INPOINT   out=x_y_orig  separator=space columns="Long double precision, Lat double precision, Station integer" x=1 y=2 skip=0 --overwrite  # import txt 

# Vector file containing outlets or inits after snapping. On layer 1, the original categories are preserved, on layer 2 there are four categories which mean:
# 1 skipped (not in use yet)
# 2 unresolved (points remain unsnapped due to lack of streams in search radius)
# 3 snapped (points snapped to streamlines)
# 4 correct (points which remain on their original position, which were originally corrected)
# 0 correct (points which remain on their original position, which were originally corrected). The 0 code happen when use the accumulation=flow 
# 1413563215 1702127980 -145245235 there are few points that report a strange code number 
# in case of adding the flow the snapping code 0 need to be read as 4

r.stream.snap accumulation=flow threshold=$(echo "5 - (0.25 * ($n - 1))" | bc)  input=x_y_orig output=x_y_snap stream_rast=stream radius=30 --overwrite memory=10000   # snapping 

paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
             <(v.db.select -c map=x_y_orig columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100 || $1 < 0) {print 2} else {print $1}}') | awk '{if ($4==2)   print $1, $2, $3}' > $IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt   # file with x y + snaped_code  = 2 

paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
             <(v.db.select -c map=x_y_orig columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100 || $1 < 0) {print 2} else {print $1}}') | awk '{if ($4>2)   print $1, $2, $3,$4}' >> $IN/snapFlow_txt_red/x_y_snapFlowYesSnap_$TILE.txt   # file with x y + snaped_code = 3 , 4 

### below if you have points with code=2 

N2befor=$( wc -l   $IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt | awk '{ print $1 }'  )  

if [ $N2befor -gt 0 ]    ; then  
echo "loop continue for  $N2befor points using flow $(echo "5 - (0.25 * ($n ))" | bc) "   ### descrbe the successive loop

nb=$(expr $n - 1 )  # number before 
### add random values to the cordinates that have  not be snaped (code=2 , or very high number , or very low-negative). Random number smaller then the pixel resolution

awk -v min=-0.0008333333 -v max=+0.0008333333 '{ srand(); print $1+( min+rand()*(max-min)), $2+( min+rand()*(max-min)), $3 }'  $IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt  >  $IN/snapFlow_txt_red/x_y_snapFlowNoSnapT_$TILE.txt 

mv  $IN/snapFlow_txt_red/x_y_snapFlowNoSnapT_$TILE.txt   $IN/snapFlow_txt_red/x_y_snapFlowNoSnap_$TILE.txt 

else
break
fi

done 
EOF

if [ ! -s  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt    ] ; then rm -f  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt   ; fi

rm -rf $RAM/x_y_NOarea10_warea_$TILE.txt $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt $RAM/stream_${TILE}_msk.tif $RAM/flow_${TILE}_msk.tif $RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n*.txt

exit
# run manualy at the end 
# perfor point distance only for snapped points      $IN/snapFlow_txt_red/x_y_snapFlowNoSnapT_$TILE.txt  

wc -l $Q/station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt  ### 41264

join -1 1 -2 1 <(awk '{print $1,$4,$5}' $Q/station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt | sort -k 1,1) <(awk '{ if ($4 != 2)  print $3,$1,$2}' $INP/../snapFlow_txt_red/x_y_snapFlowYesSnap_*.txt | sort -k 1,1)  > $INP/IDs_x_y_xsnap_ysnap.txt ### 41231 
awk '{print $3,$2,$5,$4}' $INP/IDs_x_y_xsnap_ysnap.txt  >  /tmp/cord.txt

awk -f /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/haversine_distance.awk /tmp/cord.txt > /tmp/distance.txt
paste -d " " $INP/IDs_x_y_xsnap_ysnap.txt  /tmp/distance.txt > $INP/IDs_x_y_xsnap_ysnap_dist.txt 
wc -l  $INP/IDs_x_y_xsnap_ysnap_dist.txt #### 41231  



exit


### the following stations fall out side the tile check later

join -1 1 -2 1 -v 2 <( sort -k 1,1 snapFlow_red/IDs_x_y_xsnap_ysnap_dist.txt) <(sort -k 1,1  */station_catalogueUPD_IDs_noori_db_lon_lat_area_alt.txt ) 

1 2901100 GRDC -179.250000 66.410000 207.00 42.00
36301 CHY 109.983333 37.650000 -9999.000000 -9999 0.00
37653 212270 BOM 74.767131 -85.527474 -9999 -9999
37654 212271.2 BOM 74.767131 -85.527474 -9999 -9999
37744 215240 BOM 74.767041 -85.527471 -9999 -9999
37745 215241.2 BOM 74.767041 -85.527471 -9999 -9999
39741 421903 BOM 74.767294 -85.527471 -9999 -9999
41025 ACELBR031RCM BOM 26.767244 -85.527192 -9999 -9999
41026 ACELBR032RCM BOM 26.767243 -85.527192 -9999 -9999
41027 ACELBR033RCM BOM 26.767242 -85.527192 -9999 -9999
41028 ACELBR034RCM BOM 26.767240 -85.527192 -9999 -9999
41029 ACELBR035RCM BOM 26.767240 -85.527192 -9999 -9999
41030 ACELBR036RCM BOM 26.767240 -85.527192 -9999 -9999
41031 ANOBMRC001RCM BOM 26.767240 -85.527192 -9999 -9999
41032 ANOBMRC002RCM BOM 26.767240 -85.527192 -9999 -9999
41033 ANOBMRC003RCM BOM 26.767240 -85.527192 -9999 -9999
41034 ANOBMRC006RCM BOM 26.767240 -85.527192 -9999 -9999
41035 ANOBMRC007RCM BOM 26.767240 -85.527192 -9999 -9999
41036 ANOBMRC008RCM BOM 26.767240 -85.527192 -9999 -9999
41037 ARTPDMYSWS01_1 BOM 26.767240 -85.527192 -9999 -9999
41038 ARTPDMYSWS02_1 BOM 26.767240 -85.527192 -9999 -9999
41039 ARTPMRASWS07_1 BOM 26.767240 -85.527192 -9999 -9999
41040 ARTPNYASWS03_1 BOM 26.767240 -85.527192 -9999 -9999
41041 ARTPPRJSWS01_1 BOM 26.767240 -85.527192 -9999 -9999
41042 ARTPWAGSWS15_1 BOM 26.767240 -85.527192 -9999 -9999
41043 ARTPWAGSWS16_1 BOM 26.767240 -85.527192 -9999 -9999
41044 ARTPWGNSWS01_1 BOM 26.767240 -85.527192 -9999 -9999
41045 ARTPWOOSWS03_1 BOM 26.767240 -85.527192 -9999 -9999
41046 ASCBAND001RCM BOM 26.767240 -85.527192 -9999 -9999
41047 ASCBAND002RCM BOM 26.767240 -85.527192 -9999 -9999
41254 W4260002.1 BOM 14.771119 -85.526133 -9999 -9999
7115 5148250 GRDC 124.483333 1.483333 421.40 -9999
no no_ori database longitude latitude area altitude
