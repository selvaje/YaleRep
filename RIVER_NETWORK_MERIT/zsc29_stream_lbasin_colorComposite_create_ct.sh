#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc29_stream_lbasin_colorComposite_creat_ct.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc29_stream_lbasin_colorComposite_create_ct.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc29_stream_lbasin_colorComposite_create_ct.sh


# 1-126
####    sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc29_stream_lbasin_colorComposite_create_ct.sh
####    sbatch  --dependency=afterany:$(qmys | grep sc28_tiling20d_aggregate.sh  | awk '{ print $1  }' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc29_stream_lbasin_colorComposite_create_ct.sh


export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm

echo lbasin stream | xargs -n 1 -P 2 bash -c $'  
VAR=$1
cat  $MERIT/${VAR}_tiles_final20d/${VAR}_*_hist.txt | sort -g  | uniq >  $MERIT/tmp/${VAR}_hist.txt 
pkcreatect -min 0 -max 255 | awk \'{ print $2, $3, $4 , $5 , rand() }\' | sort -k 5,5 -g | awk \'{ print $1, $2, $3 , $4  }\' > $MERIT/tmp/random_color_${VAR}_hist.txt 
mult=$(expr $( wc -l  $MERIT/tmp/${VAR}_hist.txt    | awk \'{print $1 }\'  )  / $( wc -l $MERIT/tmp/random_color_${VAR}_hist.txt   | awk \'{print $1 }\' ) + 1 )
for seq in $( seq 1 $mult ) ; do cat $MERIT/tmp/random_color_${VAR}_hist.txt  ; done >   $MERIT/tmp/random_color_multi_${VAR}.txt
paste -d " "  $MERIT/tmp/${VAR}_hist.txt   $MERIT/tmp/random_color_multi_${VAR}.txt  | awk \'{ if (NF==5 ) print  }\' | awk \'{ if(NR==1 ) {print  0, 0, 0, 0, 0 } else {print $0} }\'  >  $MERIT/tmp/${VAR}_hist_ct.txt 

rm  $MERIT/tmp/${VAR}_hist.txt   $MERIT/tmp/random_color_multi_${VAR}.txt  $MERIT/tmp/random_color_${VAR}_hist.txt    $MERIT/tmp/random_color_multi_${VAR}.txt
' _ 


sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc30_stream_lbasin_colorComposite_apply_ct.sh  
