#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc10_pred_analysis.sh 
#SBATCH -n 1 -c 5  -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_pred_analysis.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_pred_analysis.sh.%J.err
#SBATCH --mail-user=email


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc10_pred_analysis.sh 

seq 1 9 | xargs  -n 1 -P 5 bash -c $'
ORD=$1
DIR=/project/fas/sbsc/ga254/dataproces/NP
order=/project/fas/sbsc/sd566/global_wsheds/global_results_merged/netCDF/stream_order_lakes0.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $order  -msknodata $ORD  -nodata -1 -p "!" \
 -i  $DIR/prediction/prediction_FN2O_fill.tif   -o  $DIR/pred_analysis/prediction_FN20_fill_order${1}.tif 

pkstat --hist -src_min 0 -src_max 50 -nbin 200  -nodata -1 -i  $DIR/pred_analysis/prediction_FN20_fill_order${1}.tif >  $DIR/pred_analysis/prediction_FN20_fill_order${1}hist.txt

pkstat --hist -src_min 0 -src_max 50 -nbin 200  -nodata -1 -kde  -i  $DIR/pred_analysis/prediction_FN20_fill_order${1}.tif >  $DIR/pred_analysis/prediction_FN20_fill_order${1}histkde.txt

' _ 

rm /project/fas/sbsc/ga254/dataproces/NP/pred_analysis/*.tif.aux.xml

