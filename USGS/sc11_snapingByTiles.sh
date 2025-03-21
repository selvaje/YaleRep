#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 1 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_snapingByTiles.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_snapingByTiles.sh.%A_%a.err
#SBATCH --mem=16G
#SBATCH --array=14,15,19,20,24,25,30,31

#######1-116
###### for TH in 1 2 3 4 5 6 7 8 9 10 ; do sbatch --job-name=sc11_snapingByTiles_th$TH.sh --export=TH=$TH   /gpfs/gibbs/pi/hydro/hydro/scripts/USGS/sc11_snapingByTiles.sh ; done
###### ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | grep -n -e h04v04 -e  h04v02 -e h06v02 -e h06v04 -e h08v04 -e h08v02 -e h10v02 -e h10v04
###### 14,15,19,20,24,25,30,31

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/USGS
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export TH=$TH

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=112  ##### array  112    ID 96  small area for testing 

export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

echo $file 
## 3314 points txt_orig/usgs_site_x_y.txt 
if [ $TH -eq 1  ] ; then  
paste -d " " <(awk '{ print $1, $2 ,$3}' $IN/txt_orig/usgs_site_x_y.txt) <( gdallocationinfo -geoloc -valonly $file < <(awk '{print $1,$2}' $IN/txt_orig/usgs_site_x_y.txt)) | awk '{if (NF==4) print $1,$2,$3}' > $IN/txt_orig/x_y_usgs_$ID.txt

if [ -s $IN/txt_orig/x_y_usgs_$ID.txt ] ; then 
pkascii2ogr -n "usgs_no" -ot "String"    -i $IN/txt_orig/x_y_usgs_$ID.txt  -o $IN/shp_orig/x_y_usgs_$ID.shp
fi 
else 
sleep 300
fi 

if [ -s $IN/txt_orig/x_y_usgs_$ID.txt ] ; then 

export GDAL_CACHEMAX=15000 

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/stream_tiles_final20d_ovr/all_stream_dis.vrt  $RAM/stream_${ID}_msk_th${TH}.tif

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $SC/flow_tiles/all_tif_dis.vrt $RAM/flow_${ID}_msk_th${TH}.tif 

###  rm -fr $SC/grassdb/loc_$tile 
### grass78 -f -text -c  $RAM/stream_${ID}_msk.tif    $IN/loc_$ID   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/stream_${ID}_msk_th${TH}.tif  <<'EOF'

for var in flow stream ; do 
r.external  input=$RAM/${var}_${ID}_msk_th${TH}.tif     output=$var       --overwrite  
done

v.in.ascii in=$IN/txt_orig/x_y_usgs_$ID.txt  out=x_y_usgs  separator=space columns="Long double precision, Lat double precision, Station varchar(24)" x=1 y=2 skip=0 --overwrite

# Vector file containing outlets or inits after snapping. On layer 1, the original categories are preserved, on layer 2 there are four categories which mean:
# 1 skipped (not in use yet)
# 2 unresolved (points remain unsnapped due to lack of streams in search radius
# 3 snapped (points snapped to streamlines)
# 4 correct (points which remain on their original position, which were originally corrected)
# 0 correct (points which remain on their original position, which were originally corrected). The 0 code happen when use the accumulation=flow 
# 1413563215 1702127980 there are few points that report a strange code number 

r.stream.snap accumulation=flow threshold=$TH input=x_y_usgs output=x_y_snap stream_rast=stream radius=100 --overwrite memory=10000

# in case of adding the flow the snapping code 0 need to be read as 4
paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
             <(v.db.select -c map=x_y_usgs columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100) {print 2} else {print $1}}') | awk '{print $1, $2, $3,$4}' > $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt

rm -f  $IN/shp_snapFlow/x_y_snapFlow0_${ID}_th${TH}.*
pkascii2ogr -n "Station" -ot "String" -n "Snap" -ot "Integer" -i $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt -o $IN/shp_snapFlow/x_y_snapFlow1_${ID}_th${TH}.shp
cp $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt $IN/txt_snapFlow/x_y_snapFlow1_${ID}_th${TH}.txt

for n in $(seq 2 12 ) ; do 

### add random values to the cordinates that have  not be snaped (code=2 , or very high number . Random number smaller then the pixel resolution

awk -v min=-0.0008333333 -v max=+0.0008333333 '{if ($4==2 || $4 > 5 ) {srand(); print $1+( min+rand()*(max-min)), $2+( min+rand()*(max-min)), $3} else { print $1,$2,$3}}'  $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt  >  $IN/txt_snapFlow/x_y_adjust_${ID}_th${TH}.txt

v.in.ascii in=$IN/txt_snapFlow/x_y_adjust_${ID}_th${TH}.txt   out=x_y_usgs  separator=space columns="Long double precision, Lat double precision, Station varchar(24)" x=1 y=2 skip=0 --overwrite
r.stream.snap accumulation=flow threshold=$TH input=x_y_usgs output=x_y_snap stream_rast=stream radius=100 --overwrite memory=10000 
paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{ if (NR>1) print $2, $3 }' ) \
             <(v.db.select -c map=x_y_usgs columns=Station) \
             <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1>100) {print 2} else {print $1}}') | awk '{print $1,$2,$3,$4}' >  $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt
                                                                                             # 2 unresolved point 
N2after=$(awk '{ print $4 }' $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt   | sort | uniq -c | awk '{if ($2==2) {print $1} else {print 0 }}' | head -1  )

echo N2after $N2after

cp $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt $IN/txt_snapFlow/x_y_snapFlow${n}_${ID}_th${TH}.txt
rm -f  $IN/shp_snapFlow/x_y_snapFlow${n}_${ID}_th${TH}.*
pkascii2ogr -n "Snap"  -ot "Integer"  -i $IN/txt_snapFlow/x_y_snapFlow${n}_${ID}_th${TH}.txt   -o $IN/shp_snapFlow/x_y_snapFlow${n}_${ID}_th${TH}.shp

cp $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt    $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt
if [ $N2after -eq 0 ]  || [  $n -eq 12  ]  ; then
rm -fr $IN/shp_snapFlow/x_y_snapFlowFinal_${ID}_th${TH}.*
pkascii2ogr -n "Station" -ot "String" -n "Snap" -ot "Integer" -i $IN/txt_snapFlow/x_y_snapFlow${n}_${ID}_th${TH}.txt -o $IN/shp_snapFlow/x_y_snapFlowFinal_${ID}_th${TH}.shp
cp $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt  $IN/txt_snapFlow/x_y_snapFlowFinal_${ID}_th${TH}.txt
rm -f $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt
break
fi
rm -f $IN/txt_snapFlow/x_y_snapFlowAdjust_${ID}_th${TH}.txt
done 


EOF

rm -f $RAM/flow_${ID}_msk_th${TH}.tif   $RAM/stream_${ID}_msk_th${TH}.tif   $IN/txt_snapFlow/x_y_snapFlow_${ID}_th${TH}.txt

#### create shp 

rm -f $IN/shp_orig/x_y_usgs_${ID}_th${TH}.*  $IN/shp_snapFlow/x_y_snapFlowAdjust${ID}_th${TH}.* \
      $IN/txt_snapFlow/x_y_adjust_${ID}_th${TH}.txt  $IN/shp_snapFlow/x_y_snapFlow?_${ID}_th${TH}.* $IN/txt_snapFlow/x_y_snapFlow??_${ID}_th${TH}.*

else

rm  $IN/txt_orig/x_y_usgs_$ID.txt

fi
exit 


if [ $SLURM_ARRAY_TASK_ID -eq 31   ] ; then 

sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc11_snapingByTiles_th$TH.sh   |  awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )   --job-name=sc12_rwateroutlet_th$TH.sh   --export=TH=$TH /gpfs/gibbs/pi/hydro/hydro/scripts/USGS/sc12_rwateroutlet.sh 

fi 

