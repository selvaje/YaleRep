#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_variable_accumulation_intb1_GRWL_forloop.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_variable_accumulation_intb1_GRWL_forloop.sh.%J.err

ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 
#                                                        constrain up to 2016 as in GSIM. GRWL goes until 2018
### 48 last ID in the tileComp_size_memory.txt usefull to start sc11
#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_{water,lake,delta,canal,river}.tif ; do for ID  in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt ) ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ if ($4<20000) { print int(20000 * 1.4) } else { print int ($4 * 1.5)  }   }' ) ;  sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_GRWL_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc10_variable_accumulation_intb1_GRWL_forloop.sh ; done ; sleep 1200  ; done 

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4
module load GRASS/7.8.0-foss-2018a-Python-3.6.4

find  /tmp/       -user $USER  -mtime +4  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +4  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  


# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

##  SLURM_ARRAY_TASK_ID=33
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

GRWLH=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL 
export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export  RAM=/dev/shm
MEMG=$( awk -v MEM=$MEM 'BEGIN {  print int ( MEM / 4  )   }' ) 
SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
GRWLSC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/GRWL 

export  tifname=$(basename  $tif .tif )
dir=$tifname
file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${ID}.tif
filename=$(basename $file .tif  )
export tile=$ID
export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )
export ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo GRWL file $tifname 
echo tile  $file 
echo coordinates $ulx $uly $lrx $lry

### cp to the ram
echo are msk | xargs -n 1 -P 2 bash -c $'
var=$1
cp $MERIT/${var}/${zone}${tile}_${var}.tif    $RAM/${tifname}_${zone}${tile}_${var}.tif
' _ 

# in this case we keep higher resolution 

GDAL_CACHEMAX=$MEMG
GDAL_NUM_THREADS=2
gdal_translate -of VRT  -projwin $ulx $uly $lrx $lry $GRWLH/GRWL_mask_V01.01_wgs84_tif/all_tif_dis.vrt  $RAM/${tifname}_${zone}${tile}_tmp.vrt 

# DN = 255 : River
# DN = 180 : Lake/reservoir 
# DN = 126 : Tidal rivers/delta 
# DN = 86 : Canal
# DN = 0 : Land/water not connected to the GRWL river network

echo pkreclass 
if [ $tifname = GRWL_river ]  ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -of GTiff -c 255 -r 1 -c 180 -r 0 -c 126 -r 0 -c 86 -r 0 -i $RAM/${tifname}_${zone}${tile}_tmp.vrt -o /tmp/${tifname}_${zone}${tile}_var.tif ; fi 
if [ $tifname = GRWL_lake ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -of GTiff -c 255 -r 0 -c 180 -r 1 -c 126 -r 0 -c 86 -r 0 -i $RAM/${tifname}_${zone}${tile}_tmp.vrt -o /tmp/${tifname}_${zone}${tile}_var.tif ; fi 
if [ $tifname = GRWL_delta ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -of GTiff -c 255 -r 0 -c 180 -r 0 -c 126 -r 1 -c 86 -r 0 -i $RAM/${tifname}_${zone}${tile}_tmp.vrt -o /tmp/${tifname}_${zone}${tile}_var.tif ; fi 
if [ $tifname = GRWL_canal ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -of GTiff -c 255 -r 0 -c 180 -r 0 -c 126 -r 0 -c 86 -r 1 -i $RAM/${tifname}_${zone}${tile}_tmp.vrt -o /tmp/${tifname}_${zone}${tile}_var.tif ; fi 
if [ $tifname = GRWL_water ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -of GTiff -c 255 -r 1 -c 180 -r 1 -c 126 -r 1 -c 86 -r 1 -i $RAM/${tifname}_${zone}${tile}_tmp.vrt -o /tmp/${tifname}_${zone}${tile}_var.tif ; fi 
rm -f $RAM/${tifname}_${zone}${tile}_tmp.vrt

# resampling the area 

gdal_translate -a_srs EPSG:4326 -r nearest -ot Float32 -tr 0.000277777777777777777777 0.000277777777777777777777  -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/${tifname}_${zone}${tile}_are.tif /tmp/${tifname}_${zone}${tile}_areRes.tif
rm -f $RAM/${tifname}_${zone}${tile}_are.tif 
#### variable per area pixel 
gdalbuildvrt -separate -tr 0.000277777777777777777777 0.000277777777777777777777  $RAM/${tifname}_${zone}${tile}_varare.vrt   /tmp/${tifname}_${zone}${tile}_var.tif /tmp/${tifname}_${zone}${tile}_areRes.tif
gdalinfo  $RAM/${tifname}_${zone}${tile}_varare.vrt 
### adding a small number to avoid to accumulate 0 values that finaly resoult in no-data accumulation.
oft-calc -ot Float32  $RAM/${tifname}_${zone}${tile}_varare.vrt   /tmp/${tifname}_${zone}${tile}_varTMP.tif <<EOF
1
#1 #2 * 1000000 * 0.0001 +
EOF
rm -r /tmp/${tifname}_${zone}${tile}_areRes.tif  /tmp/${tifname}_${zone}${tile}_var.tif 
############   sea mask and var msk  ## resampling down 
gdal_translate  -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co BIGTIFF=YES  -co NUM_THREADS=2  -tr 0.000833333333333333 0.000833333333333333 /tmp/${tifname}_${zone}${tile}_varTMP.tif $RAM/${tifname}_${zone}${tile}_varareRes.tif
rm -f /tmp/${tifname}_${zone}${tile}_varTMP.tif  $RAM/${tifname}_${zone}${tile}_areRes.tif 

pksetmask -ot Float32  -m $RAM/${tifname}_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_varareRes.tif -o $RAM/${tifname}_${zone}${tile}_varare.tif

gdalinfo -mm $RAM/${tifname}_${zone}${tile}_varare.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0 ); print $3, $4}' >  $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_varare.mm

# gdal_translate -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2   $RAM/${tifname}_${zone}${tile}_varareRes.tif  $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_varare.tif

# gdal_translate -a_nodata -9999 -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -of GTiff -tr 0.00833333333333333 0.00833333333333333 $RAM/${tifname}_${zone}${tile}_varare.tif  $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_varare10p.tif
rm -f $RAM/${tifname}_${zone}${tile}_are.tif

echo elv dep | xargs -n 1 -P 2 bash -c $'
var=$1
cp $MERIT/${var}/${zone}${tile}_${var}.tif    $RAM/${tifname}_${zone}${tile}_${var}.tif
' _ 

echo START GRASS

grass78  -f -text --tmp-location  -c $RAM/${tifname}_${zone}${tile}_elv.tif    <<'EOF'

r.external  input=$RAM/${tifname}_${zone}${tile}_msk.tif     output=msk      --overwrite # create the folder structure  

echo elv dep varare | xargs -n 1 -P 2 bash -c $'
r.external  input=$RAM/${tifname}_${zone}${tile}_$1.tif      output=$1        --overwrite 
' _ 

r.mask raster=msk --o # usefull to mask the flow accumulation 

nL=$uly ; sL=$lry ; eL=$lrx ; wL=$ulx

g.region w=$wL  n=$nL  s=$sL  e=$eL  res=0:00:03   --o 
g.region  -m

### maximum ram 66571M  for 2^63 -1   (2 147 483 647 cell)  / 1 000 000  * 31 M   

####  -m  Enable disk swap memory option: Operation is slow   
####  -a Use positive flow accumulation even for likely underestimates
####  -b Beautify flat areas
####   threshold=0.05  = 0.05 km2 = 50000 m2 = 50000 / 90*90 = 6.17 cell 

r.watershed -a  -b  elevation=elv  depression=dep  accumulation=flow flow=varare   memory=70000 --o --verbose 
##### create a smaller box

CropW=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropW" | awk '{  print $4 }' )
CropE=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropE" | awk '{  print $4 }' )
CropS=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropS" | awk '{  print $4 }' )
CropN=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropN" | awk '{  print $4 }' )

nS=$(g.region -m  | grep ^n= | awk -F "=" -v CropN=$CropN  '{ printf ("%.14f\n" , $2 - CropN ) }' )
sS=$(g.region -m  | grep ^s= | awk -F "=" -v CropS=$CropS  '{ printf ("%.14f\n" , $2 + CropS ) }' )
eS=$(g.region -m  | grep ^e= | awk -F "=" -v CropE=$CropE  '{ printf ("%.14f\n" , $2 - CropE ) }' )
wS=$(g.region -m  | grep ^w= | awk -F "=" -v CropW=$CropW  '{ printf ("%.14f\n" , $2 + CropW ) }' )

g.region w=$wS  n=$nS  s=$sS  e=$eS  res=0:00:03  save=smallext --o 
g.region region=smallext --o
g.region  -m
r.mask raster=varare  --o # usefull to mask the flow_var in case no data in the var

r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" nodata=-9999 type=Float64 format=GTiff input=flow output=$RAM/${tifname}_${zone}${tile}_acc.tif

EOF

rm -f $RAM/${tifname}_${zone}${tile}_{elv,msk,dep}.tif


#### variable accumulation divided by the positive flow accumulation
gdalbuildvrt -separate -overwrite $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${zone}${tile}_acc.tif $SC/flow_tiles_intb1/flow_${zone}${tile}_pos.tif

oft-calc -ot Float64  $RAM/${tifname}_${tile}_acc.vrt  $RAM/${tifname}_${zone}${tile}_acc_pos.tif  <<EOF
1
#1 #2 /
EOF

GDAL_CACHEMAX=$MEMG
### masking base on the flow accumulation and also base on the var resampled
pksetmask -ot Int32 -m $SC/flow_tiles_intb1/flow_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999  \
-co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_acc_pos.tif -o $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc.tif

gdalinfo -mm  $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0 ); print $3, $4}' >  $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc.mm

echo processed file $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc.tif 

rm -f $RAM/${tifname}_${zone}${tile}_var.tif $RAM/${tifname}_${zone}${tile}_acc.tif

#####   for assesment

gdal_translate -a_nodata -9999   -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9  -of GTiff -tr 0.004166666666 0.004166666666 $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc.tif $GRWLSC/${dir}_acc/intb/${tifname}_${zone}${tile}_acc_5p.tif

## 48 last one in the list.

if [ $ID -eq  48  ] ; then     ### change back to 48 
sbatch  --export=dir=$dir,tifname=$tifname  --job-name=sc11_tiling20d_${tifname}.sh    --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep  sc10_var_acc_intb1_GRWL_forloop_${tifname}.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  ) /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc11_tiling20d_GRWL.sh
sleep 30
fi 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

exit 

