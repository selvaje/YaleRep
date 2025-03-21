#!/bin/bash
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc15_summer_winter_overlap.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc15_summer_winter_overlap.sh.%A_%a.err
#SBATCH --job-name=sc15_summer_winter_overlap.sh
#SBATCH --mem=10G
#SBATCH --array=1-1148
#### -p scavenge
#### --array=1-11

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc15_summer_winter_overlap.sh


find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools

##########SLURM_ARRAY_TASK_ID=410

mkdir -p /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_overlap_txt
mkdir -p /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_overlap_txt

export RAM=/dev/shm
export TIFY=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_tif/summer        #### x_y_allfilter 
export TIFX=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_tif/winter   ## many 

export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_overlap_txt

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

echo $file 
echo $ID

NTIF=$( ls $TIFY/pointF_inTile_alltypes_$ID.tif  $TIFX/pointF_inTile_alltypes_$ID.tif  2> /dev/null  | wc -l ) 

if [ $NTIF -eq 2   ] ; then 

export GDAL_CACHEMAX=3000

ls $TIFY/pointF_inTile_alltypes_$ID.tif  $TIFX/pointF_inTile_alltypes_$ID.tif  | xargs -n 1 -P 2 bash -c $' 
tif=$1
tifname=$(basename $tif .tif)
folder=$(basename $(dirname $tif ))
gdal_translate  -of AAIGrid   $tif   $RAM/${tifname}_${folder}.asc 
rm -f  $RAM/${tifname}_${folder}.{prj,asc.aux}
' _


echo creating

paste -d " " <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) { printf ("%2.2f\n", $i )}}}'  $RAM/pointF_inTile_alltypes_${ID}_summer.asc   ) <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_alltypes_${ID}_winter.asc  ) |   awk '{ if( $1!=0 && $1!=-9 && $2!=-9 ) print $1 , $2 }' >  $TXT/filter_$ID.txt 

## check if $TXT/filter_alltypes_$ID.txt is empty
[[ -s $TXT/filter_$ID.txt ]] || rm $TXT/filter_$ID.txt

fi 
