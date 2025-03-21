#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_txt4Correlation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_txt4Correlation.sh.%J.err
#SBATCH --job-name=sc12_txt4Correlation.sh
#SBATCH --mem=20G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc12_txt4Correlation.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  
source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/loomis/project/sbsc/hydro/dataproces/NHDPlus_HR


paste -d " " <(cat $NHDP/raster_flow_val/flow_*_pos_msk.txt ) <(cat $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_*_msk.txt) > $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt
paste -d " " <(cat $NHDP/raster_flow_val/flow_*_mer_msk.txt ) <(cat $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_*_msk.txt) > $NHDP/raster_flow_val/flow_MERIT_NHDP.txt


awk 'NR%100==0' $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt > $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp100.txt
awk 'NR%10==0'  $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt > $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp10.txt

awk '{if($1 > 0 && $2 > 0 )  print $1, $2 }' $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt >   $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0.txt
awk '{if($1 > 1 && $2 > 1 )  print $1, $2 }' $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt >   $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt1.txt

awk '{if($1 > 0 && $2 > 0 )  print $1, $2 }' $NHDP/raster_flow_val/flow_MERIT_NHDP.txt >   $NHDP/raster_flow_val/flow_MERIT_NHDP_gt0.txt
awk '{if($1 > 1 && $2 > 1 )  print $1, $2 }' $NHDP/raster_flow_val/flow_MERIT_NHDP.txt >   $NHDP/raster_flow_val/flow_MERIT_NHDP_gt1.txt

awk '{if($1 > 1 && $2 > 1 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp100.txt >  $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp100_log.txt
awk '{if($1 > 1 && $2 > 1 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp10.txt >   $NHDP/raster_flow_val/flow_HYDRO_NHDP_samp10_log.txt

awk '{if($1 > 1 && $2 > 1 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt >   $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt1_log.txt
awk '{if($1 > 0 && $2 > 0 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt >   $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0_log.txt

awk '{if($1 > 1 && $2 > 1 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_MERIT_NHDP.txt >   $NHDP/raster_flow_val/flow_MERIT_NHDP_gt1_log.txt
awk '{if($1 > 0 && $2 > 0 )  print log($1), log($2) }' $NHDP/raster_flow_val/flow_MERIT_NHDP.txt >   $NHDP/raster_flow_val/flow_MERIT_NHDP_gt0_log.txt


awk   'function abs(x){return ((x < 0.0) ? -x : x)}  {print $1 , $2 , abs($1 - $2) }' $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0.txt  > $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0_abs.txt


pkstatascii -c 0 -c 1  -regerr  -rmse -cor   -i $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt1_log.txt > $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt1_log_correlation.txt 
pkstatascii -c 0 -c 1  -regerr  -rmse -cor   -i $NHDP/raster_flow_val/flow_MERIT_NHDP_gt1_log.txt > $NHDP/raster_flow_val/flow_MERIT_NHDP_gt1_log_correlation.txt 

pkstatascii -c 0 -c 1  -regerr  -rmse -cor   -i $NHDP/raster_flow_val/flow_HYDRO_NHDP.txt > $NHDP/raster_flow_val/flow_HYDRO_NHDP_correlation.txt 
pkstatascii -c 0 -c 1  -regerr  -rmse -cor   -i $NHDP/raster_flow_val/flow_MERIT_NHDP.txt > $NHDP/raster_flow_val/flow_MERIT_NHDP_correlation.txt 

# pkstatascii -c 2 -nbin  100  -hist -i $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0_abs.txt > $NHDP/raster_flow_val/flow_HYDRO_NHDP_gt0_abs_percentile.txt
