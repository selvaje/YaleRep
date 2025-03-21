#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_snapingByTiles.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_snapingByTiles.sh.%A_%a.err
#SBATCH --job-name=sc11_snapingByTiles.sh
#SBATCH --mem=16G
#SBATCH --array=1-116

### testing 58    h18v02
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc11_snapingByTiles_flowred.sh

####  wc -l   quantiles/x_y_ID.txt  40813  # this are uniq pare of lat lon 
####  wc -l   quantiles/x_y.txt   orig_txt/x_y_ID_*.txt  41234 29 punti   lost because they are in antartica 
####  wc -l   snapFlow_txt/x_y_snapFlowYesSnap_*.txt   snapFlow_txt/x_y_snapFlowNoSnap_*.txt 41234 
####  wc -l   snapFlow_txt/x_y_snapFlowFinal_stream_flow_*.txt   41213 

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
paste -d " " $QNT/x_y_ID.txt <( gdallocationinfo -geoloc -valonly $file  <  <(awk '{print $1, $2 }' $QNT/x_y_ID.txt) ) | awk '{if (NF==4) print $1, $2,$3 }'  > $RAM/x_y_ID_$TILE.txt

awk '{ print $1, $2 }'  $RAM/x_y_ID_$TILE.txt >  $RAM/x_y_$TILE.txt

if [ -s $RAM/x_y_ID_$TILE.txt ] ; then 

cp  $RAM/x_y_ID_$TILE.txt $IN/orig_txt/x_y_ID_$TILE.txt
cp  $RAM/x_y_$TILE.txt $IN/orig_txt/x_y_$TILE.txt


pkascii2ogr -f "GPKG" -n "GSI_TM_no" -ot "Integer"    -i $IN/orig_txt/x_y_ID_$TILE.txt  -o $IN/orig_shp/x_y_orig_ID_$TILE.gpkg   # crate a shapefile 

export GDAL_CACHEMAX=15000 

gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment.vrt  $RAM/stream_${TILE}_msk.tif # create  file tile  that is larger  
  
gdal_translate -projwin $(getCorners4Gtranslate $file | awk '{ print $1 - 0.2, $2 + 0.2, $3 + 0.2, $4 - 0.2}') -co COMPRESS=DEFLATE -co ZLEVEL=9 $MH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation.vrt $RAM/flow_${TILE}_msk.tif    # create  file tile  that is larger  

# module load GRASS/8.2.0-foss-2022b
# for installatioin
# grass --text ~/grassdb/nc_spm_08_grass7/PERMANENT/
#  g.extension extension=r.stream.segment     url=/home/ga254/grass_addons/src/raster/r.stream.segment 
# grass  -f --text --tmp-location  $RAM/stream_${TILE}_msk.tif  <<'EOF'


# for var in flow stream ; do 
# r.external  input=$RAM/${var}_${TILE}_msk.tif     output=$var       --overwrite     # import the files  (mask) 
# done
# rm -f $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt

# for n in $(seq 1 21 ) ; do 
# echo "loop $n" wc $N2befor
# if [ $n -eq 1  ] ; then INPOINT=$RAM/x_y_ID_$TILE.txt  ; fi 
# if [ $n -gt 1  ] ; then INPOINT=$IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt   ; fi 

# v.in.ascii in=$INPOINT   out=x_y_orig  separator=space columns="Long double precision, Lat double precision, Station integer" x=1 y=2 skip=0 --overwrite  # import txt 

# # Vector file containing outlets or inits after snapping. On layer 1, the original categories are preserved, on layer 2 there are four categories which mean:
# # 1 skipped (not in use yet)
# # 2 unresolved (points remain unsnapped due to lack of streams in search radius)
# # 3 snapped (points snapped to streamlines)
# # 4 correct (points which remain on their original position, which were originally corrected)
# # 0 correct (points which remain on their original position, which were originally corrected). The 0 code happen when use the accumulation=flow 
# # 1413563215 1702127980 -145245235 there are few points that report a strange code number 
# # in case of adding the flow the snapping code 0 need to be read as 4

# r.stream.snap accumulation=flow threshold=$(echo "5 - (0.25 * ($n - 1))" | bc)  input=x_y_orig output=x_y_snap stream_rast=stream radius=30 --overwrite memory=10000   # snapping 

# paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
#              <(v.db.select -c map=x_y_orig columns=Station) \
#              <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100 || $1 < 0) {print 2} else {print $1}}') | awk '{if ($4==2)   print $1, $2, $3}' > $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt   # file with x y + snaped_code  = 2 

# paste -d " " <(v.report map=x_y_snap option=coor layer=1 | awk -F "|" '{if(NR>1) print $2,$3 }')\
#              <(v.db.select -c map=x_y_orig columns=Station) \
#              <(v.category input=x_y_snap layer=2 type=point option=print | awk '{if($1==0){print 4} else if ($1 > 100 || $1 < 0) {print 2} else {print $1}}') | awk '{if ($4>2)   print $1, $2, $3,$4}' >> $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt   # file with x y + snaped_code = 3 , 4 

# ### below if you have points with code=2 

# N2befor=$( wc -l   $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt | awk '{ print $1 }'  )  

# if [ $N2befor -gt 0 ]    ; then  
# echo "loop continue for  $N2befor points using flow $(echo "5 - (0.25 * ($n ))" | bc) "   ### descrbe the successive loop

# nb=$(expr $n - 1 )  # number before 
# ### add random values to the cordinates that have  not be snaped (code=2 , or very high number , or very low-negative). Random number smaller then the pixel resolution

# awk -v min=-0.0008333333 -v max=+0.0008333333 '{ srand(); print $1+( min+rand()*(max-min)), $2+( min+rand()*(max-min)), $3 }'  $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt  >  $IN/snapFlow_txt/x_y_snapFlowNoSnapT_$TILE.txt 

# mv  $IN/snapFlow_txt/x_y_snapFlowNoSnapT_$TILE.txt   $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt 

# else
# break
# fi
# done 

# if [ ! -s $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt    ] ; then rm $IN/snapFlow_txt/x_y_snapFlowNoSnap_$TILE.txt ; fi

# EOF

source ~/bin/gdal3
source ~/bin/pktools

### calculate raster ID.
xsize=$(gdalinfo $RAM/stream_${TILE}_msk.tif | grep "Size is" | awk '{ print int($3)}' )
ysize=$(gdalinfo $RAM/stream_${TILE}_msk.tif | grep "Size is" | awk '{ print int($4)}' )
xll=$(getCorners4Gtranslate $RAM/stream_${TILE}_msk.tif | awk '{ print $1}')
yll=$(getCorners4Gtranslate $RAM/stream_${TILE}_msk.tif | awk '{ print $4}') 

echo "ncols        $xsize"                  >  $SC/rasterID/rasterID_$TILE.asc 
echo "nrows        $ysize"                  >> $SC/rasterID/rasterID_$TILE.asc 
echo "xllcorner    $xll"                    >> $SC/rasterID/rasterID_$TILE.asc 
echo "yllcorner    $yll"                    >> $SC/rasterID/rasterID_$TILE.asc 
echo "cellsize     0.000833333333333"       >> $SC/rasterID/rasterID_$TILE.asc

awk -v xsize=$xsize -v ysize=$ysize  ' BEGIN {  
for (row=1 ; row<=ysize ; row++)  { 
     for (col=1 ; col<=xsize ; col++) { 
         printf ("%i " ,  col+(row-1)*xsize  ) } ; printf ("\n")  }}'                        >> $SC/rasterID/rasterID_$TILE.asc
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 $SC/rasterID/rasterID_$TILE.asc    $SC/rasterID/rasterID_$TILE.tif 
rm -f $SC/rasterID/rasterID_$TILE.asc 

paste -d " "  <( awk '{print $1,$2,$3}' $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt   ) \
      <(gdallocationinfo -valonly -geoloc  $RAM/stream_${TILE}_msk.tif      < <(awk '{print $1,$2}' $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt )) \
      <(gdallocationinfo -valonly -geoloc  $SC/rasterID/rasterID_$TILE.tif  < <(awk '{print $1,$2}' $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt )) \
      <(gdallocationinfo -valonly -geoloc  $RAM/flow_${TILE}_msk.tif        < <(awk '{print $1,$2}' $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt )) \
      > $IN/snapFlow_txt/x_y_snapFlowFinal_stream_IDr_flow_$TILE.txt

pkascii2ogr -f "GPKG" -n "IDstation"  -ot "Integer"  -n "IDstream" -ot "Integer" -n "IDraster" -ot "Integer"    -n "Flow" -ot "Real" -i $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt -o $IN/snapFlow_shp/x_y_snapFlowFinal_$TILE.gpkg

rm -f $RAM/flow_${TILE}_msk.tif  $RAM/stream_${TILE}_msk.tif  $RAM/x_y_$TILE.txt  $IN/snapFlow_txt/x_y_snapFlow_$TILE.txt $IN/snapFlow_txt/x_y_snapFlow?_$TILE.txt $IN/snapFlow_txt/x_y_snapFlow??_$TILE.txt
rm -f $IN/orig_shp/x_y_orig_$TILE.*  $IN/snapFlow_shp/x_y_snapFlowAdjust$ID.* $IN/snapFlow_txt/x_y_adjust_$TILE.txt $IN/snapFlow_shp/x_y_snapFlow?_$TILE.*  $IN/snapFlow_txt/x_y_snapFlow??_$TILE.*  $IN/snapFlow_shp/x_y_snapFlow??_$TILE.*

else 

rm $RAM/x_y_$TILE.txt 

fi 

