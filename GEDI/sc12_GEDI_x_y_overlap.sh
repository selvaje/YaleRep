#!/bin/bash
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc12_GEDI_x_y_overlap.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc12_GEDI_x_y_overlap.sh.%A_%a.err
#SBATCH --job-name=sc12_GEDI_x_y_overlap.sh
#SBATCH --mem=10G
#SBATCH --array=1-1148

### --array=1-1148
#### -p scavenge

##x_y_sensitivity 

### for string in x_y_day x_y_coveragebeam x_y_degrade ; do sbatch --export=string=$string /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc12_GEDI_x_y_overlap.sh ; done 


find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools

if [ $string = x_y_allfilter ]       ;  then DIR=af  ; fi 
if [ $string = x_y_day ]             ;  then DIR=dy  ; fi 
if [ $string = x_y_coveragebeam ]    ;  then DIR=cb  ; fi 
if [ $string = x_y_sensitivity ]     ;  then DIR=st  ; fi 
if [ $string = x_y_degrade ]         ;  then DIR=de  ; fi 

mkdir -p /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/overlap_tif/{dy,cb,st,de,ge}
mkdir -p /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/overlap_txt/{dy,cb,st,de,ge}

export RAM=/dev/shm
export TIFY=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif/af        #### x_y_allfilter 
export TIFX=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/QC_tif/$DIR   ## many 

export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/overlap_txt/$DIR
export string=$string

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/???????_elv.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export ID=$(basename $file _elv.tif  )

echo $file 
echo $ID

NTIF=$( ls $TIFY/pointF_inTile_$ID.tif  $TIFX/pointF_inTile_$ID.tif  2> /dev/null  | wc -l ) 

if [ $NTIF -eq 2   ] ; then 

export GDAL_CACHEMAX=3000
ls $TIFY/pointF_inTile_$ID.tif  $TIFX/pointF_inTile_$ID.tif  | xargs -n 1 -P 2 bash -c $' 
tif=$1
tifname=$(basename $tif .tif)
folder=$(basename $(dirname $tif ))
gdal_translate  -of AAIGrid   $tif   $RAM/${tifname}_${folder}.asc 
rm -f  $RAM/$RAM/${tifname}_${folder}.{prj,asc.aux}
' _


echo creating

paste -d " " <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) { printf ("%2.2f\n", $i )}}}'  $RAM/pointF_inTile_${ID}_af.asc   ) <(awk '{if(NR>=6){for(i = 1; i <= NF; ++i) {printf ("%2.2f\n", $i )}}}' $RAM/pointF_inTile_${ID}_${DIR}.asc  ) |   awk '{ if( $1!=-9 && $2!=-9 ) print $1 , $2 }' >  $TXT/filter_${DIR}_$ID.txt 

## check if $TXT/filter_${DIR}_$ID.txt is empty
[[ -s $TXT/filter_${DIR}_$ID.txt ]] || rm $TXT/filter_${DIR}_$ID.txt

fi 
