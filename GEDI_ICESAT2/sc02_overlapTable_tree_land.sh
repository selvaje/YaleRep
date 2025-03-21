#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc01_overlapPoint_tree_land.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc01_overlapPoint_tree_land.sh.%A_%a.err
#SBATCH --job-name=sc01_overlapPoint_tree_land.sh
#SBATCH --mem=10G
#SBATCH --array=1-545

## 1-1148  ## test 476
### -p scavenge

### for NUM in 70 75 80 85 90 95 ; do sbatch --export=DIR=icesat2_${NUM} /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc01_overlapPoint_tree_land.sh ; done

### sbatch --export DIR=icesat2_66 /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc01_overlapPoint_tree_land.sh

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export RAM=/dev/shm
export TIFI=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/QC_tif/${DIR}
export TIFG=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif/mo
export GI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/

### SLURM_ARRAY_TASK_ID=117                                                   # 90m 
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/pointF_TIFI_TIFG_inTile_*_gr.txt | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export nameID=$(basename $file _gr.tif  )
export TILE=${nameID:24}

echo $file
echo $TILE


NTIF=$(ls $TIFG/pointF_inTile_${ID}_gr.tif  $TIFI/pointF_inTile_${ID}_gr.tif 2> /dev/null  | wc -l ) 


export GDAL_CACHEMAX=3000

gdallocationinfo  -valonly    $TIFG/pointF_inTile_${ID}_gr.tif < $file 


 $TIFI/pointF_inTile_${ID}_gr.tif 


exit 

gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med -tr 0.00025 0.00025  /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt   $RAM/pointF_inTile_${ID}_gr_treecover2000.tif 

pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9  \
            -m $TIFI/pointF_inTile_${ID}_gr.tif              -mskband 0   -msknodata -9  -nodata -9  \
            -m $RAM/pointF_inTile_${ID}_gr_treecover2000.tif              -msknodata  0  -nodata -9 \
            -i $TIFG/pointF_inTile_${ID}_gr.tif  -o /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_tif/pointF_TIFI_TIFG_inTile_${ID}_gr.tif

mv  $RAM/pointF_inTile_${ID}_gr_treecover2000.tif   /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/treecover2000/

MAX=$(pkstat  -mm  -i /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_tif/pointF_TIFI_TIFG_inTile_${ID}_gr.tif | awk '{ print int($4) }')
if [ $MAX = -9 ] ; then 
rm -f  /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_tif/pointF_TIFI_TIFG_inTile_${ID}_gr.tif 
else 

grass78  -f -text --tmp-location  -c /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_tif/pointF_TIFI_TIFG_inTile_${ID}_gr.tif    <<'EOF'
r.external  input=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_tif/pointF_TIFI_TIFG_inTile_${ID}_gr.tif   output=raster   --o
r.to.vect -t  input=raster   output=vector   type=point  --overwrite  # -t no attribute table 
v.out.ogr  --overwrite format=GPKG  input=vector  output=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_gpkg/pointF_TIFI_TIFG_inTile_${ID}_gr.gpkg 
v.out.ascii separator=" " precision=12   input=vector format=point  output=$RAM/pointF_TIFI_TIFG_inTile_${ID}_gr.txt
awk '{ print $1,$2}' $RAM/pointF_TIFI_TIFG_inTile_${ID}_gr.txt > /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/pointF_TIFI_TIFG_inTile_${ID}_gr.txt
rm  $RAM/pointF_TIFI_TIFG_inTile_${ID}_gr.txt
EOF

fi 
fi 

exit 

cat  /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/pointF_TIFI_TIFG_inTile_*_gr.txt >  /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/all_pointF_TIFI_TIFG_inTile_gr.txt
rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/all_pointF_TIFI_TIFG_inTile_gr.gpkg 
pkascii2ogr -f GPKG   -i /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/all_pointF_TIFI_TIFG_inTile_gr.txt -o /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_lat_lon/all_pointF_TIFI_TIFG_inTile_gr.gpkg 






### below not use usefull anymore . 


gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med -tr 0.00025 0.00025  -of AAIGrid  /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt   $RAM/pointF_inTile_${ID}_gr_treecover2000.asc

ls $TIFG/pointF_inTile_${ID}_gr.tif  $TIFI/pointF_inTile_${ID}_gr.tif  | xargs -n 1 -P 2 bash -c $' 
tif=$1
tifname=$(basename $tif .tif)
folder=$(basename $(dirname $tif ))
gdal_translate -b 1 -of AAIGrid   $tif   $RAM/${tifname}_${folder}.asc 
rm -f  $RAM/${tifname}_${folder}.{prj,asc.aux}
' _


#### when is over use ogrmerge.py  to create a global shp.. this you can open globaly.. 

echo creating

paste -d " " <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) { printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFG).asc) \
  <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI).asc  )  \
  <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_treecover2000.asc  )  \
  |   awk '{ if( $1!=-9 && $2!=-9 && $1!=0 && $2!=0 && $3!=0 ) print $1 , $2 , $3 }' >  $TXT/filter_${ID}_tree_land.txt 

rm -f $RAM/pointF_inTile_${ID}_gr_$( basename $TIFG).asc $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI).asc $RAM/pointF_inTile_${ID}_gr_treecover2000.asc  

## check if $TXT/filter_$ID.txt is empty
[[ -s $TXT/filter_${ID}_tree_land.txt  ]] || rm $TXT/filter_${ID}_tree_land.txt 

fi 

exit

gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med -tr 0.0008333333333333333333 0.0008333333333333333333  -of AAIGrid  /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt   $RAM/pointF_inTile_${ID}_gr_treecover2000.asc

