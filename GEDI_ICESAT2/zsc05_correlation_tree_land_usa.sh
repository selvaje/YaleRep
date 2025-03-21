#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc05_correlation_tree_land_usa.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc05_correlation_tree_land_usa.sh.%A_%a.err
#SBATCH --job-name=sc05_correlation_tree_land_usa.sh
#SBATCH --mem=10G
#SBATCH --array=299,344,390,438,298,343,389,437,297,342,388,436,296,341,387,435,251,295,340,386,434,250,294,339,385,433,249,293,338,384,432,248,292,337,383,431,247,291,336,382,430,290,335,381,334,380,428,427

### -p scavenge

### for NUM in 70 75 80 85 90 95 ; do sbatch --export=DIR=icesat2_${NUM} /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc05_correlation_tree_land_usa.sh ; done

### sbatch --export DIR=icesat2_66 /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc05_correlation_tree_land_usa.sh

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools

export RAM=/dev/shm
export TIFI=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/QC_tif/${DIR}
export TIFG=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif/mo
export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_usa/${DIR}

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

gdalwarp -te $(getCorners4Gwarp $TIFG/pointF_inTile_${ID}_gr.tif ) -r med -tr 0.00025 0.00025  -of AAIGrid  /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt   $RAM/pointF_inTile_${ID}_gr_treecover2000.asc

ls $TIFG/pointF_inTile_${ID}_gr.tif  $TIFI/pointF_inTile_${ID}_gr.tif  | xargs -n 1 -P 2 bash -c $' 
tif=$1
tifname=$(basename $tif .tif)
folder=$(basename $(dirname $tif ))
gdal_translate  -of AAIGrid   $tif   $RAM/${tifname}_${folder}.asc 
rm -f  $RAM/${tifname}_${folder}.{prj,asc.aux}
' _

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

