#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_tiling20d_lbasin_oftbb_TilesLarge.sh.%A_%a.out   
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_tiling20d_lbasin_oftbb_TilesLarge.sh.%A_%a.err
#SBATCH --job-name=sc31_tiling20d_lbasin_oftbb_TilesLarge.sh 
#SBATCH --array=1-166
#SBATCH --mem=24G

####  116 small basin = tails compUnit ; compUnit 1-116   ;   array 1-116
####  50  large basin = large compUnit ; compUnit 151-200 ; array 117-166
####  sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc31_tiling20d_lbasin_oftbb_TilesLarge.sh

###### rm /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_large/*  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_tiles/*

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

## SLURM_ARRAY_TASK_ID=11

export ID=$(awk -v SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID '{ if (NR == (SLURM_ARRAY_TASK_ID + 1 )) print}' $SCMH/lbasin_tiles_final20d_1p/uniq_computational_unit.txt)
# export ID=10 

# select tiles for each tilenumber.
export GDAL_CACHEMAX=20000

echo buidlvrt 
cd $SCMH/lbasin_tiles_final20d_1p

### tile selection 

if [ $SLURM_ARRAY_TASK_ID = 1  ] ; then  
wc=$(  wc -l $SCMH/lbasin_tiles_final20d_1p/uniq_computational_unit.txt | awk '{ print $1 -1  }' )
paste -d " " $SCMH/lbasin_tiles_final20d_1p/uniq_computational_unit.txt   <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0 ; shuf -i 1-255 -n $wc -r) | awk '{ if (NR==1) {print $0 , 0 } else { print $0 , 255 }}'  >   $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.txt 
fi 

if [ $SLURM_ARRAY_TASK_ID -le 116  ] ; then  

gdalbuildvrt -overwrite   -srcnodata 0 -vrtnodata 0  $RAM/bid$ID.vrt    $(ls  $( join -1 1 -2 1 <(cat lbasin_h??v??_histile.txt | awk '{ if ($1!=0)  print $1 , $3}' | sort -k 1,1) <(awk -v ID=$ID '{ if($2==ID) print $1}'   reclass_computational_unit.txt | sort -k 1,1 ) | awk '{ print $2}' | sort | uniq  ) )

awk -v ID=$ID '{ if($2==ID) print $1 , $2 } '  $SCMH/lbasin_tiles_final20d_1p/reclass_computational_unit.txt >  $RAM/lbasin_${ID}.txt 

pkreclass -of GTiff -nodata 0 -ot UInt32 -code  $RAM/lbasin_${ID}.txt  -co COMPRESS=DEFLATE -co ZLEVEL=9   -i $RAM/bid$ID.vrt   -o  $RAM/bid$ID.tif 
rm -f  $RAM/lbasin_${ID}.txt $SCMH/lbasin_compUnit_tiles/bid$ID.vrt 

pkstat --hist -i    $RAM/bid$ID.vrt  | grep -v " 0" > $SCMH/lbasin_compUnit_tiles/bid${ID}_test.hist

pkgetmask -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -min $(echo $ID - 0.5 | bc ) -max $(echo $ID + 0.5 | bc ) -data $ID -nodata 0 -i $RAM/bid$ID.tif -o $RAM/bid${ID}_msk.tif 

echo oftbb with region zoom
gdal_edit.py  -a_nodata 0    $RAM/bid${ID}_msk.tif 
grass78  -f -text --tmp-location  -c $RAM/bid${ID}_msk.tif    <<'EOF'
r.external  input=$RAM/bid${ID}_msk.tif   output=msk   --overwrite
g.region -a zoom=msk   --o   #### With the -a flag all four boundaries are adjusted to be even multiples of the resolution, aligning the region to the resolution supplied by the user. 
                             #### The default is to align the region resolution to match the region boundaries.
r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  nodata=0   type=UInt32    format=GTiff input=msk output=$RAM/bid${ID}_msk_zoom.tif 
EOF
gdal_edit.py -tr  0.000833333333333333333333333333333   -0.000833333333333333333333333333333    $RAM/bid${ID}_msk_zoom.tif

### round to the larger extent to integer degree to avoid tile extend with rounded number 

geo_string=$(getCorners4Gtranslate $RAM/bid${ID}_msk_zoom.tif  | awk '{ 
if ($1<0) {ulx=int($1 - 1) } else {  ulx=int($1)     } ; 
if ($2<0) {uly=int($2)     } else {  uly=int($2 + 1) } ; 
if ($3<0) {lrx=int($3)     } else {  lrx=int($3 + 1) } ; 
if ($4<0) {lry=int($4 - 1) } else {  lry=int($4)     } ; 
print ulx , uly , lrx , lry  }')

gdal_translate -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string $RAM/bid${ID}_msk.tif  $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif 

gdal_edit.py -a_ullr  $geo_string  $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif 
gdal_edit.py -a_ullr  $geo_string  $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif 

pkstat -hist -i  $RAM/bid${ID}_msk.tif   | grep -v " 0" > $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.hist

rm -f $RAM/bid${ID}_msk_zoom.tif  
gdal_translate -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin  $(getCorners4Gtranslate $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif) $RAM/bid$ID.vrt  $RAM/bid${ID}_crop.tif

gdal_edit.py -a_ullr  $(getCorners4Gtranslate $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif)              $RAM/bid${ID}_crop.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333     $RAM/bid${ID}_crop.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif)              $RAM/bid${ID}_crop.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333     $RAM/bid${ID}_crop.tif

cp $RAM/bid${ID}_crop.tif  $SCMH/lbasin_compUnit_tiles/bid${ID}_crop.tif
pkstat --hist -i  $RAM/bid${ID}_crop.tif | grep -v " 0" > $SCMH/lbasin_compUnit_tiles/bid${ID}_crop.hist

pksetmask -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif -msknodata 0 -nodata 0 -i $RAM/bid${ID}_crop.tif -o $SCMH/lbasin_compUnit_tiles/bid$ID.tif

pkstat --hist -i  $SCMH/lbasin_compUnit_tiles/bid${ID}.tif | grep -v " 0" > $SCMH/lbasin_compUnit_tiles/bid${ID}.hist

echo apply ct
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/lbasin_compUnit_tiles/bid${ID}_msk.tif $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.txt  $SCMH/lbasin_compUnit_tiles_ct/bid${ID}_msk.tif

fi 

# large basins selection 

if [ $SLURM_ARRAY_TASK_ID -ge 117  ] ; then  

echo builvrt 

export IDB=$( awk -v ID=$ID '{ if($2==ID) print $1}' $SCMH/lbasin_tiles_final20d_1p/reclass_computational_unit.txt)
gdalbuildvrt   -srcnodata 0 -vrtnodata 0  -overwrite  $RAM/bid$ID.vrt  $(ls  $(grep ^"$IDB " lbasin_h??v??_histile.txt  | awk '{ print  $3    }' ) )

echo translate

#####  round to 1 decimal 

gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9    $RAM/bid$ID.vrt  $RAM/bid${ID}_tiles.tif
gdal_edit.py -tr   0.000833333333333333333333333333333   -0.000833333333333333333333333333333 $RAM/bid${ID}_tiles.tif

##  cp  $RAM/bid${ID}_tiles.tif    $SCMH/lbasin_compUnit_large

grass78  -f -text --tmp-location  -c $RAM/bid${ID}_tiles.tif    <<'EOF'
r.external  input=$RAM/bid${ID}_tiles.tif   output=tiles   --overwrite

r.mapcalc " tiles_$IDB = if (tiles == $IDB , $IDB , null() ) "
g.region -a zoom=tiles_$IDB --o #### With the -a flag all four boundaries are adjusted to be even multiples of the resolution, aligning the region to the resolution supplied by the user. 
                                #### The default is to align the region resolution to match the region boundaries.

r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES"  nodata=0   type=UInt32    format=GTiff input=tiles_$IDB output=$RAM/bid${ID}_zoom.tif 
EOF

gdal_edit.py -tr   0.000833333333333333333333333333333   -0.000833333333333333333333333333333  $RAM/bid${ID}_zoom.tif
## cp $RAM/bid${ID}_zoom.tif  $SCMH/lbasin_compUnit_large

geo_string=$(getCorners4Gtranslate $RAM/bid${ID}_zoom.tif  | awk '{ 
if ($1<0) {ulx=int($1 - 1) } else {  ulx=int($1)     } ; 
if ($2<0) {uly=int($2)     } else {  uly=int($2 + 1) } ; 
if ($3<0) {lrx=int($3)     } else {  lrx=int($3 + 1) } ; 
if ($4<0) {lry=int($4 - 1) } else {  lry=int($4)     } ; 
print ulx , uly , lrx , lry }')

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  $RAM/bid${ID}_zoom.tif $RAM/bid${ID}_crop.tif

rm -f $RAM/bid${ID}_zoom.tif

pksetmask -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $RAM/bid${ID}_crop.tif -p "!" -msknodata $IDB -nodata 0 -i $RAM/bid${ID}_crop.tif -o $SCMH/lbasin_compUnit_large/bid${ID}.tif

gdal_edit.py -a_ullr  $(getCorners4Gtranslate $RAM/bid${ID}_crop.tif  ) $SCMH/lbasin_compUnit_large/bid${ID}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SCMH/lbasin_compUnit_large/bid${ID}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $RAM/bid${ID}_crop.tif  ) $SCMH/lbasin_compUnit_large/bid${ID}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SCMH/lbasin_compUnit_large/bid${ID}.tif

pkreclass -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9  -c $IDB -r $ID  -nodata 0 -i $SCMH/lbasin_compUnit_large/bid${ID}.tif   -o $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif

gdal_edit.py -a_ullr  $(getCorners4Gtranslate $RAM/bid${ID}_crop.tif ) $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $RAM/bid${ID}_crop.tif ) $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif

pkstat --hist -i  $SCMH/lbasin_compUnit_large/bid${ID}.tif     | grep -v " 0" > $SCMH/lbasin_compUnit_large/bid${ID}.hist
pkstat --hist -i  $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif | grep -v " 0" > $SCMH/lbasin_compUnit_large/bid${ID}_msk.hist

echo apply ct
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/lbasin_compUnit_large/bid${ID}_msk.tif $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.txt  $SCMH/lbasin_compUnit_large_ct/bid${ID}_msk.tif

rm  -f $RAM/bid$ID.vrt  $RAM/bid${ID}_crop.tif 
fi 


if [ $SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_MAX  ] ; then 
sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc31_tiling20d_lbasin_oftbb_TilesLarge.sh | awk '{ print $1  }' | uniq )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh

# sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc31_tiling20d_lbasin_oftbb_TilesLarge.sh | awk '{ print $1  }' | uniq )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc33_merge20d_1-40p_ct_compUnit.sh 

sleep 30
fi
