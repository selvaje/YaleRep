#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 1 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_snapingByTiles.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_snapingByTiles.sh.%A_%a.err
#SBATCH --job-name=sc11_snapingByTiles.sh
#SBATCH --mem=16G
#SBATCH --array=15

###  15,31,14,24,25,30,19,20 # usa array
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/CAMELS/sc11_snapingByTiles.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/CAMELS/input
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

##   SLURM_ARRAY_TASK_ID=25 #### usa tile 



export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

echo $file 
#### 

### fatto a mano la prima volta
## awk -F '\t' '{if (NR>1) print $5, $4}'          $SNAP/gauge_information.txt  >  $SNAP/gauge_x_y.txt 
## awk -F '\t' '{if (NR>1) print $2, $5, $4, $6}'  $SNAP/gauge_information.txt  >  $SNAP/gaugeID_x_y_area.txt 

##################       671 stations or points 
paste -d " " $SNAP/txt/gaugeID_x_y_area.txt <(gdallocationinfo -geoloc -valonly $SC/flow_tiles/flow_$ID.tif < $SNAP/txt/gauge_x_y.txt) <(gdallocationinfo -geoloc -valonly $file < $SNAP/txt/gauge_x_y.txt) > $RAM/x_y_$ID.txt

awk '{ if (NF>4)  {print $0 } }' $RAM/x_y_$ID.txt  > $RAM/x_y_${ID}_intile.txt  
awk '{ if (NF>4) {  if ($6==0) { print $2, $3 , $1  }  else if ( $4/$5 > 1.1 || $4/$5 < 0.9 ) {print $2, $3 , $1 }  } }' $RAM/x_y_$ID.txt  > $RAM/x_y_${ID}_forsnaping.txt  
join -v 1 -1 1 -2 3 $RAM/x_y_${ID}_intile.txt   $RAM/x_y_${ID}_forsnaping.txt  > $RAM/x_y_${ID}_nosnaped.txt


if [ -s $RAM/x_y_$ID.txt ] ; then 

# cp  $RAM/x_y_$ID.txt $SNAP/camels_no/x_y_camels_$ID.txt
# pkascii2ogr -n "CAMELS_ID" -ot "String"    -i $SNAP/camels_no/x_y_camels_$ID.txt      -o $SNAP/camels_shp/x_y_orig_$ID.shp
 
export GDAL_CACHEMAX=15000 
### increase the extend for some points close to the boderd 
gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/stream_tiles_final20d_ovr/all_stream_dis.vrt  $RAM/stream_${ID}_msk.tif

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles/all_tif_dis.vrt $RAM/flow_${ID}_msk.tif 

###  rm -fr $SC/grassdb/loc_$tile 
### grass78 -f -text -c  $RAM/stream_${ID}_msk.tif    $SNAP/loc_$ID   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/stream_${ID}_msk.tif  <<'EOF'

for var in flow stream ; do 
r.external  input=$RAM/${var}_${ID}_msk.tif     output=$var       --overwrite  
done

v.in.ascii in=$RAM/x_y_${ID}_forsnaping.txt out=x_y_orig  separator=space columns="Long double precision, Lat double precision, Station varchar(18)" x=1 y=2 skip=0 --overwrite

# Vector file containing outlets or inits after snapping. On layer 1, the original categories are preserved, on layer 2 there are four categories which mean:
# 1 skipped (not in use yet)
# 2 unresolved (points remain unsnapped due to lack of streams in search radius
# 3 snapped (points snapped to streamlines)
# 4 correct (points which remain on their original position, which were originally corrected)
# 0 correct (points which remain on their original position, which were originally corrected). The 0 code happen when use the accumulation=flow 
# 1413563215 1702127980 there are few points that report a strange code number 

r.stream.snap accumulation=flow threshold=0.4 input=x_y_orig output=x_y_snap stream_rast=stream radius=30 --overwrite memory=10000

# in case of adding the flow the snapping code 0 need to be read as 4
paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
             <(v.db.select -c map=x_y_orig columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100) {print 2} else {print $1}}') | awk '{print $1, $2, $3,$4}' > $SNAP/snapFlow/x_y_snapFlow_$ID.txt

rm -f  $SNAP/snapFlow_shp/x_y_snapFlow0_$ID.*
pkascii2ogr -n "Station"    -ot "String"   -n "Snap"    -ot "Integer"   -i $SNAP/snapFlow/x_y_snapFlow_$ID.txt -o $SNAP/snapFlow_shp/x_y_snapFlow1_$ID.shp
cp $SNAP/snapFlow/x_y_snapFlow_$ID.txt  $SNAP/snapFlow/x_y_snapFlow1_$ID.txt

for n in $(seq 2 12 ) ; do 

### add random values to the cordinates that have  not be snaped (code=2 , or very high number . Random number smaller then the pixel resolution

awk -v min=-0.0008333333 -v max=+0.0008333333 '{if ($4==2 || $4 > 5 ) {srand(); print $1+( min+rand()*(max-min)), $2+( min+rand()*(max-min)), $3} else { print $1,$2,$3}}'  $SNAP/snapFlow/x_y_snapFlow_$ID.txt  >  $SNAP/snapFlow/x_y_adjust_$ID.txt 

v.in.ascii in=$SNAP/snapFlow/x_y_adjust_$ID.txt  out=x_y_orig  separator=space columns="Long double precision, Lat double precision, Station varchar(18)" x=1 y=2 skip=0 --overwrite
r.stream.snap accumulation=flow threshold=0.4 input=x_y_orig output=x_y_snap stream_rast=stream radius=30 --overwrite memory=10000 
paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{ if (NR>1) print $2, $3 }' ) \
             <(v.db.select -c map=x_y_orig columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1>100) {print 2} else {print $1}}') | awk '{print $1, $2, $3,$4}' >  $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt

N2befor=$(awk '{ print $4 }' $SNAP/snapFlow/x_y_snapFlow_$ID.txt       | sort | uniq -c | awk '{if ($2==2) {print $1} else {print 0 }}')
N2after=$(awk '{ print $4 }' $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt | sort | uniq -c | awk '{if ($2==2) {print $1} else {print 0 }}')

echo N2befor $N2befor vs N2after $N2after

cp $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt $SNAP/snapFlow/x_y_snapFlow${n}_$ID.txt
rm -f  $SNAP/snapFlow_shp/x_y_snapFlow${n}_$ID.*
pkascii2ogr -n "Snap"  -ot "Integer"  -i $SNAP/snapFlow/x_y_snapFlow${n}_$ID.txt -o $SNAP/snapFlow_shp/x_y_snapFlow${n}_$ID.shp

cp $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt $SNAP/snapFlow/x_y_snapFlow_$ID.txt
if [ $N2after -eq 0 ]  || [  $n -eq 12  ]  ; then
rm -r $SNAP/snapFlow_shp/x_y_snapFlowFinal_$ID.*
pkascii2ogr  -n "Station"    -ot "String"  -n "Snap" -ot "Integer" -i $SNAP/snapFlow/x_y_snapFlow${n}_$ID.txt -o $SNAP/snapFlow_shp/x_y_snapFlowFinal_$ID.shp
cp $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt  $SNAP/snapFlow/x_y_snapFlowFinal_$ID.txt
rm -f $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt
break
fi
rm -f $SNAP/snapFlow/x_y_snapFlowAdjust_$ID.txt
done 

mv $RAM/x_y_$ID.txt $SNAP/camels_no/x_y_camels_$ID.txt
EOF

rm -f $RAM/flow_${ID}_msk.tif  $RAM/stream_${ID}_msk.tif  $RAM/x_y_$ID.txt  $SNAP/snapFlow/x_y_snapFlow_$ID.txt   

#### create shp 

rm -f  $SNAP/snapFlow_shp/x_y_snapFlowAdjust$ID.* $SNAP/snapFlow/x_y_adjust_$ID.txt $SNAP/snapFlow_shp/x_y_snapFlow?_$ID.* $SNAP/snapFlow/x_y_snapFlow??_$ID.* $SNAP/snapFlow_shp/x_y_snapFlow??_$ID.*

else 

rm $RAM/x_y_$ID.txt 

fi 
exit 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/CAMELS/snapFlow
awk '{  print $3 , $1 , $2  }'  x_y_snapFlowFinal_h??v??.txt > x_y_snapFlowFinal.txt 

