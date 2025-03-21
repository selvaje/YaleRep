#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 7:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_variable_accumulation_intb1_ESALC_forloop.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_variable_accumulation_intb1_ESALC_forloop.sh.%J.err

ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 
#                                                        constrain up to 2016 as in GSIM. ESALC goes until 2018
### 48 last ID in the tileComp_size_memory.txt usefull to start sc11
#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC??/LC??_Y1992.tif ; do for ID  in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt ) ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print $4}' ) ;  sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_ESALC_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc10_variable_accumulation_intb1_ESALC_forloop.sh ; done ; sleep 1200  ; done 

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4
module load GRASS/7.8.0-foss-2018a-Python-3.6.4

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /gpfs/gibbs/pi/hydro/hydro/stderr  -mtime +2  -name "*.err"  2>/dev/null | xargs -n 1 -P 2 rm -ifr
find  /gpfs/gibbs/pi/hydro/hydro/stdout  -mtime +2  -name "*.out"  2>/dev/null | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

##  SLURM_ARRAY_TASK_ID=33
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

ESALCH=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC 
export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export  RAM=/dev/shm
MEMG=$( awk -v MEM=$MEM 'BEGIN {  print int (int(MEM) / 3 )  }' ) 
SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
ESALCSC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/ESALC 

export  tifname=$(basename  $tif .tif )
dir=$(echo $tifname | cut -d "_"  -f 1 ) 
year=$(echo $tifname |  awk -F "_"  '{ gsub("Y","") ;  print $2   }'   ) 
file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${ID}.tif
filename=$(basename $file .tif  )
export tile=$ID
export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )
export ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo ESALC file $tifname 
echo tile  $file 
echo coordinates $ulx $uly $lrx $lry

### cp to the ram
echo are elv msk dep | xargs -n 1 -P 2 bash -c $'
var=$1
cp $MERIT/${var}/${zone}${tile}_${var}.tif    $RAM/${tifname}_${zone}${tile}_${var}.tif
' _ 

GDAL_CACHEMAX=$MEMG
gdal_translate -a_nodata -9999  -a_srs EPSG:4326 -r nearest -ot Float32  -tr 0.000833333333333333333 0.000833333333333333333   -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $tif $RAM/${tifname}_${zone}${tile}_var.tif

#### variable per area pixel 
gdalbuildvrt -separate $RAM/${tifname}_${zone}${tile}_varare.vrt    $RAM/${tifname}_${zone}${tile}_var.tif $RAM/${tifname}_${zone}${tile}_are.tif
### adding a small number to avoid to accumulate 0 values that finaly resoult in no-data accumulation.
oft-calc -ot Float32  $RAM/${tifname}_${zone}${tile}_varare.vrt   $RAM/${tifname}_${zone}${tile}_varTMP.tif <<EOF
1
#1 #2 * 1000000 * 0.0001 +
EOF

############   sea mask and var msk 
pksetmask -ot Float32  -m $RAM/${tifname}_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=3 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_varTMP.tif -o $RAM/${tifname}_${zone}${tile}_varare.tif

# gdal_translate -a_nodata -9999999   -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -of GTiff -tr 0.004166666666 0.004166666666 $RAM/${tifname}_${zone}${tile}_varare.tif $ESALCSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_varare.tif

rm -f $RAM/${tifname}_${zone}${tile}_varTMP.tif $RAM/${tifname}_${zone}${tile}_are.tif

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

r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES,NUM_THREADS=2,BIGTIFF=YES" nodata=-9999999 type=Float32 format=GTiff input=flow output=$RAM/${tifname}_${zone}${tile}_acc.tif

EOF

rm -f $RAM/${tifname}_${zone}${tile}_{elv,msk,dep}.tif

GDAL_CACHEMAX=$MEMG
### masking base on the flow accumulation and also base on the var resampled
pksetmask -ot Float32 -m $SC/flow_tiles_intb1/flow_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_acc.tif -o $ESALCSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_acc.tif

echo processed file $ESALCSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_acc.tif 

rm -f $RAM/${tifname}_${zone}${tile}_var.tif $RAM/${tifname}_${zone}${tile}_acc.tif

#####   for assesment

gdal_translate -a_nodata -9999999   -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -of GTiff -tr 0.004166666666 0.004166666666 $ESALCSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_acc.tif $ESALCSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_acc_5p.tif

## 48 last one in the list.

if [ $ID -eq  48  ] ; then     ### change back to 48 
sbatch  --export=dir=$dir,year=$year,tifname=$tifname  --job-name=sc11_tiling20d_ESALC_${tifname}.sh    --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep  sc10_var_acc_intb1_ESALC_forloop_${tifname}.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  ) /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc11_tiling20d_ESALC_nofollowing.sh
sleep 30
fi 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

exit 

