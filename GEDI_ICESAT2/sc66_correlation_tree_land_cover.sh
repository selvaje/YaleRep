#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc66_correlation_tree_land_cover.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc66_correlation_tree_land_cover.sh.%A_%a.err
#SBATCH --job-name=sc66_correlation_tree_land_cover.sh
#SBATCH --mem=25G
#SBATCH --array=1-1148

### -p scavenge

### sbatch --export DIR=icesat2_66 /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc66_correlation_tree_land_cover.sh

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools

export RAM=/dev/shm
export TIFI=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/QC_tif/${DIR}   ###  NoData Value=-9
export TIFG=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif/mo          ###  NoData Value=-9
export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt/${DIR}

### SLURM_ARRAY_TASK_ID=117                                                   # 90m 
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

mkdir -p $TIFI
mkdir -p $TXT

echo $file 
echo $ID

## rm -f $TXT/*.txt

NTIF=$(ls $TIFG/pointF_inTile_${ID}_gr.tif  $TIFI/pointF_inTile_${ID}_gr.tif 2> /dev/null  | wc -l ) 

if [ $NTIF -eq 2   ] ; then 
export GDAL_CACHEMAX=3000

gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med -tr 0.00025 0.00025  -of AAIGrid /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt   $RAM/pointF_inTile_${ID}_gr_treecover2000.asc   ### without nodata

rm -f  $RAM/pointF_inTile_${ID}_gr_treecover2000.{prj,asc.aux}

gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r mode -tr 0.00025 0.00025  -of AAIGrid  /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC_GFC/ESALC_2018_rec.tif   $RAM/pointF_inTile_${ID}_gr_landcover2018.asc  ### NoData Value=0

rm -f  $RAM/pointF_inTile_${ID}_gr_landcover2018.{prj,asc.aux}


gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med  -tr 0.00025 0.00025  -of AAIGrid  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT/geomorphometry_90m_wgs84/slope/all_tif_slope.vrt  $RAM/pointF_inTile_${ID}_gr_terrainslop90m.asc  ### NoData Value=-9999

rm -f  $RAM/pointF_inTile_${ID}_gr_terrainslop90m.{prj,asc.aux}


ls $TIFG/pointF_inTile_${ID}_gr.tif  $TIFI/pointF_inTile_${ID}_gr.tif  | xargs -n 1 -P 2 bash -c $' 
tif=$1
tifname=$(basename $tif .tif)
folder=$(basename $(dirname $tif ))

if [[ $folder == mo ]]; then
	gdal_translate  -of AAIGrid   $tif   $RAM/${tifname}_${folder}.asc    # gedi 
	rm -f  $RAM/${tifname}_${folder}.{prj,asc.aux}
else
	gdal_translate  -of AAIGrid -b 1 $tif   $RAM/${tifname}_${folder}_1.asc 
	gdal_translate  -of AAIGrid -b 2 $tif   $RAM/${tifname}_${folder}_2.asc 
	gdal_translate  -of AAIGrid -b 3 $tif   $RAM/${tifname}_${folder}_3.asc 
	gdal_translate  -of AAIGrid -b 4 $tif   $RAM/${tifname}_${folder}_4.asc 
	gdal_translate  -of AAIGrid -b 5 $tif   $RAM/${tifname}_${folder}_5.asc 
	gdal_translate  -of AAIGrid -b 6 $tif   $RAM/${tifname}_${folder}_6.asc 	
	rm -f  $RAM/${tifname}_${folder}_{1,2,3,4,5,6}.{prj,asc.aux}
fi

rm -f  $RAM/${tifname}_${folder}_?.{prj,asc.aux}
' _

echo creating

paste -d " " \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFG).asc) \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_1.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_2.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_3.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_4.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_5.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_6.asc  )  \
  <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_treecover2000.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_landcover2018.asc  )  \
  <(awk '{if(NR>=7){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_gr_terrainslop90m.asc  )  \
  |  awk '{ if( $1!=-9 && $2!=-9 && $7!=-9 && $1!=0 && $2!=0 && $7!=0 && $8>0 && $9!=0 && $9<190 && $10>=0 && $10<90 ) print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' >  $TXT/filter_${ID}_tree_land_slope.txt 

echo delete files

rm -f $RAM/pointF_inTile_${ID}_gr_$( basename $TIFG).asc $RAM/pointF_inTile_${ID}_gr_$( basename $TIFI)_?.asc $RAM/pointF_inTile_${ID}_gr_treecover2000.asc $RAM/pointF_inTile_${ID}_gr_landcover2018.asc  $RAM/pointF_inTile_${ID}_gr_terrainslop90m.asc 

## check if $TXT/filter_$ID.txt is empty
[[ -s $TXT/filter_${ID}_tree_land_slope.txt  ]] || rm $TXT/filter_${ID}_tree_land_slope.txt 

fi 

exit

