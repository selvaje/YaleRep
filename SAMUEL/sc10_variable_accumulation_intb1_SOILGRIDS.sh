#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 7:00:00       # 6 hours 
#SBATCH -o /home/st929/output/sc10_variable_accumulation_intb1_SOILGRIDS.sh.%J.out
#SBATCH -e /home/st929/output/sc10_variable_accumulation_intb1_SOILGRIDS.sh.%J.err
#SBATCH --mem=90G
#SBATCH --array=1-59
########################SBATCH --array=14,15,19-21,24-26,30-32  ## usa
################### 59 should be all land tiles?  11272024

ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  
## AWCtS_acc CLYPPT_acc SLTPPT_acc SNDPPT_acc WWP_acc 

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 
#                                                        constrain up to 2016 as in GSIM. TERRA goes until 2018
### 48 last ID in the tileComp_size_memory.txt usefull to start sc11
#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/out_TranspGrow/*.tif ; do for ID in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt ) ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print $4}' ) ;  sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_SOILGRIDS_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc10_variable_accumulation_intb1_SOILGRIDS.sh ; done ; sleep 1200 ; done 


source ~/bin/gdal3

#find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
#find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
#find  /gpfs/gibbs/pi/hydro/hydro/stderr  -mtime +2  -name "*.err" | xargs -n 1 -P 2 rm -ifr
#find  /gpfs/gibbs/pi/hydro/hydro/stdout  -mtime +2  -name "*.out" | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

##  SLURM_ARRAY_TASK_ID=33
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

#####
VAR=$var
mkdir -p /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/${VAR}_WeAv/tiles_20d
mv /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/${VAR}_WeAv/${VAR}_WeAv_h* /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/${VAR}_WeAv/tiles_20d

export tif=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/${VAR}_WeAv/${VAR}_WeAv.tif
export ID=$SLURM_ARRAY_TASK_ID #14,15,19-21,24-26,30-32
export MEM=66562
####

##
export SOILGRIDSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS ## didn't use this after change


export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export  RAM=/dev/shm
MEMG=$( awk -v MEM=$MEM 'BEGIN {  print int (int(MEM) / 3 )  }' ) 
SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
SOILGRIDSSC=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess

export  tifname=$(basename  $tif .tif )
dir=$(echo $tifname | cut -d "_"  -f 1 )

file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${ID}.tif
filename=$(basename $file .tif )
export tile=$ID

export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )
export ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo SOILGRIDS file $tifname 
echo tile  $file 
echo coordinates $ulx $uly $lrx $lry

### cp to the ram
echo are elv msk dep | xargs -n 1 -P 2 bash -c '
var="$1"
echo "Copying $var"
cp "$MERIT/${var}/${zone}${tile}_${var}.tif" "$RAM/${tifname}_${zone}${tile}_${var}.tif"
' _

GDAL_CACHEMAX=10000
gdal_translate -a_nodata 65535  -a_srs EPSG:4326 -r bilinear -ot Float32 -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $tif $RAM/${tifname}_${zone}${tile}_var.tif
##check here if it comes out

#### variable per area pixel 
gdalbuildvrt -separate $RAM/${tifname}_${zone}${tile}_varare.vrt    $RAM/${tifname}_${zone}${tile}_var.tif $RAM/${tifname}_${zone}${tile}_are.tif
### adding a small number to avoid to accumulate 0 values that finaly resoult in no-data accumulation.
oft-calc -ot Float32 $RAM/${tifname}_${zone}${tile}_varare.vrt $RAM/${tifname}_${zone}${tile}_varTMP.tif <<EOF
1
#1 #2 * 0.0001 +
EOF

if [[ $? -ne 0 ]]; then
    echo "Error in oft-calc command. Check input VRT and syntax."
    exit 1
fi


############   sea mask and var msk 
source ~/bin/pktools

pksetmask -ot Float32  -m $RAM/${tifname}_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999  -m $RAM/${tifname}_${zone}${tile}_var.tif -msknodata 65535   -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=3 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_varTMP.tif -o $RAM/${tifname}_${zone}${tile}_varare.tif

### gdal_translate -a_nodata -9999 -r average -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -of GTiff -tr 0.004166666666 0.004166666666 $RAM/${tifname}_${zone}${tile}_varare.tif $SOILGRIDSSC/${dir}_acc/$year/intb/${tifname}_${zone}${tile}_varare.tif

rm -f $RAM/${tifname}_${zone}${tile}_varTMP.tif $RAM/${tifname}_${zone}${tile}_are.tif

source ~/bin/grass8
echo START GRASS

grass -f --text --tmp-location $RAM/${tifname}_${zone}${tile}_elv.tif <<'EOF'

# Debugging: Check if GRASS session started and input file paths are correct
echo "Starting GRASS session with elevation file: $RAM/${tifname}_${zone}${tile}_elv.tif"
echo "Loading mask file: $RAM/${tifname}_${zone}${tile}_msk.tif"

# Link external files
r.external input=$RAM/${tifname}_${zone}${tile}_msk.tif output=msk --overwrite

# Debug: Verify if mask layer is linked
if [[ $? -ne 0 ]]; then
    echo "Error linking mask file"
    exit 1
fi

echo "Loading elevation, depression, and variable accumulation layers..."
echo elv dep varare | xargs -n 1 -P 2 bash -c $'
r.external input=$RAM/${tifname}_${zone}${tile}_$1.tif output=$1 --overwrite
' _ 

# Set the mask
r.mask raster=msk --o
echo "Applied mask for flow accumulation"

# Set the region
echo "Setting region boundaries: n=$nL, s=$sL, e=$eL, w=$wL"
g.region w=$wL n=$nL s=$sL e=$eL res=0:00:03 --o
g.region -m

# Run r.watershed
echo "Running r.watershed with memory=30000"
r.watershed -a -b elevation=elv depression=dep accumulation=flow flow=varare memory=70000 --o --verbose

# Debug: Check if r.watershed command succeeded
if [[ $? -ne 0 ]]; then
    echo "Error in r.watershed"
    exit 1
fi

# Create a smaller box (crop)
echo "Calculating CropW, CropE, CropS, CropN from shapefile"
CropW=$(ogrinfo -al -where "id = '$tile'" $SC/tiles_comp/tilesComp.shp | grep " CropW" | awk '{print $4}')
CropE=$(ogrinfo -al -where "id = '$tile'" $SC/tiles_comp/tilesComp.shp | grep " CropE" | awk '{print $4}')
CropS=$(ogrinfo -al -where "id = '$tile'" $SC/tiles_comp/tilesComp.shp | grep " CropS" | awk '{print $4}')
CropN=$(ogrinfo -al -where "id = '$tile'" $SC/tiles_comp/tilesComp.shp | grep " CropN" | awk '{print $4}')

echo "Setting region to smallext with calculated boundaries"
nS=$(g.region -m | grep ^n= | awk -F "=" -v CropN=$CropN '{printf ("%.14f\n", $2 - CropN)}')
sS=$(g.region -m | grep ^s= | awk -F "=" -v CropS=$CropS '{printf ("%.14f\n", $2 + CropS)}')
eS=$(g.region -m | grep ^e= | awk -F "=" -v CropE=$CropE '{printf ("%.14f\n", $2 - CropE)}')
wS=$(g.region -m | grep ^w= | awk -F "=" -v CropW=$CropW '{printf ("%.14f\n", $2 + CropW)}')

echo "Calculated coordinates for smallext: nS=$nS, sS=$sS, eS=$eS, wS=$wS"
g.region w=$wS n=$nS s=$sS e=$eS res=0:00:03 save=smallext --o
g.region region=smallext --o
g.region -m

# Set the mask again
echo "Applying mask for varare layer"
r.mask raster=varare --o

# Export the result
echo "Exporting flow accumulation to GeoTIFF"
r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES,NUM_THREADS=2,BIGTIFF=YES" \
nodata=-9999999 type=Float32 format=GTiff input=flow output=$RAM/${tifname}_${zone}${tile}_acc.tif

# Debug: Check if export succeeded
if [[ $? -ne 0 ]]; then
    echo "Error in r.out.gdal export"
    exit 1
fi

EOF

# Final debug message
echo "Script completed successfully. Check the output at $RAM/${tifname}_${zone}${tile}_acc.tif"

rm -f $RAM/${tifname}_${zone}${tile}_{elv,msk,dep}.tif


source ~/bin/pktools
mkdir -p $SOILGRIDSSC/${dir}_acc

GDAL_CACHEMAX=$MEMG
### masking base on the flow accumulation and also base on the var resampled
pksetmask -ot Float32 -m $SC/flow_tiles_intb1/flow_${zone}${tile}_msk.tif -msknodata 0 -nodata -9999999  -m $RAM/${tifname}_${zone}${tile}_var.tif -msknodata 65535  -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -co BIGTIFF=YES -i $RAM/${tifname}_${zone}${tile}_acc.tif -o $SOILGRIDSSC/${dir}_acc/${tifname}_${zone}${tile}_acc.tif

echo processed file $SOILGRIDSSC/${dir}_acc/${tifname}_${zone}${tile}_acc.tif 

rm -f $RAM/${tifname}_${zone}${tile}_var.tif $RAM/${tifname}_${zone}${tile}_acc.tif

#####   for assesment  visualization

gdal_translate -a_nodata -9999999   -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -of GTiff -tr 0.004166666666 0.004166666666 $SOILGRIDSSC/${dir}_acc/${tifname}_${zone}${tile}_acc.tif $SOILGRIDSSC/${dir}_acc/${tifname}_${zone}${tile}_acc_5p.tif

## 48 last one in the list.
##########change to manual
#if [ $ID -eq  48  ] ; then     ### change back to 48 
#sbatch  --export=dir=$dir,tifname=$tifname  --job-name=sc11_tiling20d_SOILGRIDS_${tifname}.sh --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc10_var_acc_intb1_SOILGRIDS_${tifname}.sh | awk '{ printf ("%i:", $1)} END {gsub(":","") ; print $1 }' ) /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc11_tiling20d_SOILGRIDS.sh
#sleep 30
#fi 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

exit 

