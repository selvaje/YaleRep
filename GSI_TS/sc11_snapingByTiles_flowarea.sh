#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_snapingByTiles.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_snapingByTiles.sh.%A_%a.err
#SBATCH --job-name=sc11_snapingByTiles.sh
#SBATCH --mem=20G
#SBATCH --array=1-116

### testing 58    h18v02
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc11_snapingByTiles_flowarea.sh

####  wc -l   quantiles/x_y_ID.txt  40813  # this are uniq pare of lat lon 
####  wc -l   quantiles/x_y.txt   orig_txt/x_y_ID_*.txt  41234 29 punti   lost because they are in antartica 
####  wc -l   snapFlow_txt/x_y_snapFlowYesSnap_*.txt   snapFlow_txt/x_y_snapFlowNoSnap_*.txt 41234 
####  wc -l   snapFlow_txt/x_y_snapFlowFinal_stream_flow_*.txt   41213 

ulimit -c 0

source ~/bin/gdal3   2> /dev/null
# source ~/bin/pktools

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export QNT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export INP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_area

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=112  ##### array  112    ID 96  small area for testing 
## SLURM_ARRAY_TASK_ID=20

export file=$(ls $MH/CompUnit_stream_uniq_tiles20d/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )      ## select the tile file 
export filename=$(basename $file .tif  )
export TILE=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

~/bin/echoerr $file 
echo          $file 
########################         
###  select all the points that fall inside the tile from 

### points that need snapping    38408   with areaT       16825  #### snapping useing area-10%  as treshold for each point 
### $INP/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10_warea.txt


paste -d " " <(cut -d " " -f 1,3,4,5  $INP/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10_warea.txt)  <( gdallocationinfo -geoloc -valonly $file  <  <( cut -d " " -f 3,4  $INP/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10_warea.txt  ) ) | awk '{if (NF==5) print $1, $2,$3,$4 }'  > $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt 

awk '{ print $2, $3 }'  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt   > $RAM/x_y_NOarea10_warea_$TILE.txt 

if [ -s  $RAM/x_y_NOarea10_warea_$TILE.txt    ] ; then 

cp  $RAM/x_y_NOarea10_warea_$TILE.txt           $INP/
cp  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt  $INP/


# pkascii2ogr -f "GPKG" -n "GSI_TM_no" -ot "Integer"    -i $IN/orig_txt/x_y_ID_$TILE.txt  -o $IN/orig_shp/x_y_orig_ID_$TILE.gpkg   # crate a shapefile 

export GDAL_CACHEMAX=15000

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment.vrt  $RAM/stream_${TILE}_msk.tif # create  file tile  that is larger  
  
gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif  $RAM/flow_${TILE}_msk.tif    # create  file tile  that is larger  

module load GRASS/8.2.0-foss-2022b  2> /dev/null 


# rm -fr $RAM/location
# grass  -f --text $RAM/location  -c  $RAM/stream_${TILE}_msk.tif  <<'EOF'

grass  -f --text --tmp-location  $RAM/stream_${TILE}_msk.tif  <<'EOF'
for var in flow stream ; do 
r.external  input=$RAM/${var}_${TILE}_msk.tif     output=$var   --overwrite  # import the files  (mask) 
done

for n in $(seq 1 $(wc -l  $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt   | cut -d ' ' -f 1)) ; do 
###for n in $(seq 1 4 ) ; do

head -n $n $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt | tail -1   > $RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n$n.txt 
read IDs x y area <<< $( cat $RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n$n.txt )

# echo region n=$(echo  $y + 0.1 | bc  )  s=$(echo $y - 0.1 | bc )  e=$(echo $x + 0.1 | bc )  w=$(echo $x - 0.1 | bc )
g.region n=$(echo  $y + 0.1 | bc  )  s=$(echo $y - 0.1 | bc )  e=$(echo $x + 0.1 | bc )  w=$(echo $x - 0.1 | bc )  --overwrite --quiet  
v.in.ascii in=$RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n$n.txt out=x_y_orig$n  separator=space columns="Station integer, Lon double precision, Lat double precision, Area double precision" x=2 y=3 skip=0 --overwrite  --quiet 

# Vector file containing outlets or inits after snapping. On layer 1, the original categories are preserved, on layer 2 there are four categories which mean:
# 1 skipped (not in use yet)
# 2 unresolved (points remain unsnapped due to lack of streams in search radius) Unable to snap point with cat 1, in a given radius. Increase 
# 3 snapped (points snapped to streamlines)
# 4 correct (points which remain on their original position, which were originally corrected)
# 0 correct (points which remain on their original position, which were originally corrected). The 0 code happen when use the accumulation=flow 
# 1413563215 1702127980 -145245235 there are few points that report a strange code number 
# in case of adding the flow the snapping code 0 need to be read as 4

r.stream.snap accumulation=flow threshold=$(echo "$area  - ($area * 0.1 )" | bc) input=x_y_orig$n output=x_y_snap$n stream_rast=stream radius=30 --overwrite memory=1000  --quiet     # snapping

########### 1235 point return code 2; with the if below   point return code 2
qc=$(v.category input=x_y_snap$n layer=2 type=point option=print)
if [ $qc -eq 2 ] ; then
# increase the radius 
r.stream.snap accumulation=flow threshold=$(echo "$area - ($area * 0.1)" | bc) input=x_y_orig$n output=x_y_snap$n stream_rast=stream radius=50 --overwrite memory=1000  --quiet     # snapping
# increase the radius and also reduce the flow accumulation treshold 
qc=$(v.category input=x_y_snap$n layer=2 type=point option=print)
if [ $qc -eq 2 ] ; then
r.stream.snap accumulation=flow threshold=$(echo "$area - ($area * 0.2)" | bc) input=x_y_orig$n output=x_y_snap$n stream_rast=stream radius=50 --overwrite memory=1000  --quiet     # snapping
fi
fi

paste -d " " <(v.report map=x_y_orig$n option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3,$4,$5 }')  \
             <(v.report map=x_y_snap$n option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }') \
   <(r.what separator=" " map=flow coordinates=$(v.report map=x_y_snap$n option=coor layer=1 | awk -F "|" '{if(NR>1) print $2","$3}') | awk '{print $3}' ) \
             <(v.category input=x_y_snap$n layer=2 type=point option=print)

g.remove -f  type=vector name=x_y_snap${n},x_y_orig${n}
rm -f $RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n$n.txt

done >  $INP/IDs_x_y_area_NOarea10_xsnap_ysnap_areasfd_CodeSnap_$TILE.txt 
 
EOF

else 
exit 
fi

rm -rf $RAM/x_y_NOarea10_warea_$TILE.txt $RAM/IDs_x_y_area_NOarea10_warea_$TILE.txt  $RAM/stream_${TILE}_msk.tif $RAM/flow_${TILE}_msk.tif $RAM/IDs_x_y_area_NOarea10_warea_${TILE}_n*.txt

exit

 
