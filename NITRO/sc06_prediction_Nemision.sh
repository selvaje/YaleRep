#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc06_prediction_Nemision.sh
#SBATCH -n 1 -c 10  -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_prediction_Nemision.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_prediction_Nemision.sh.%J.err
#SBATCH --mail-user=email


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc06_prediction_Nemision.sh

export DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP

awk '{ print $2   }' $DIR/gfortran_code/Output_N2O_emission_valid.dat | sort  > $DIR/gfortran_code/Output_N2O_emission_valid_ID.txt 
awk '{ if (NR>1) print $2   }' $DIR/emision_table_valid_cor.txt                 | sort  > $DIR/emision_table_valid_cor_ID.txt
join -v 2 -1 1  -2 1 $DIR/gfortran_code/Output_N2O_emission_valid_ID.txt $DIR/emision_table_valid_cor_ID.txt > $DIR/gfortran_code/Inconsistent_PR.dat

awk '{ if (NR>2) print NR, $1 }' $DIR/gfortran_code/header.txt   | xargs -n 2 -P 10 bash -c $'  

n=$1
H=$2

if [ $n -eq 10 ] ; then 

awk -v n=$n  \'{ if ($n == "dune") { print $2 , 1 } 
            else if ($n == "pool_riffle") { print $2 , 2 }  
                 if ($n == "step_pool_cascade") { print $2 , 3 } }\'  $DIR/gfortran_code/Output_N2O_emission_valid.dat >   $DIR/prediction/Output_N2O_emission_$H.dat
awk          \'{ print $1 , "-1" }\'                                  $DIR/gfortran_code/Inconsistent_PR.dat           >>  $DIR/prediction/Output_N2O_emission_$H.dat  
awk          \'{ print $2 , "-1" }\'                                  $DIR/emision_table_notvalid.txt                  >>  $DIR/prediction/Output_N2O_emission_$H.dat

else 

awk -v n=$n  \'{ printf ("%i  %.12f\\n" , $2 ,  $n) }\'       $DIR/gfortran_code/Output_N2O_emission_valid.dat   >   $DIR/prediction/Output_N2O_emission_$H.dat  
awk        \'{ print $1 , "-1" }\'                          $DIR/gfortran_code/Inconsistent_PR.dat              >>   $DIR/prediction/Output_N2O_emission_$H.dat  
awk          \'{ print $2 , "-1" }\'                          $DIR/emision_table_notvalid.txt                   >>   $DIR/prediction/Output_N2O_emission_$H.dat  

fi 


# find min and max
paste <(awk \'{ if ($2 != -1) print    }\'   Output_N2O_emission_$H.dat  |  awk \'min=="" || $2 < min {min=$2} END{ print min}\' )  <(awk \'{ if ($2 != -1) print    }\'   Output_N2O_emission_$H.dat  |  awk \'min=="" || $2 > min {min=$2} END{ print min}\' )  > $DIR/prediction/Output_N2O_emission_${H}_min_max.dat 

#  
pkreclass -m $DIR/global_prediction/map_pred_TN_mask.tif -msknodata -1 -nodata -9999 --code $DIR/prediction/Output_N2O_emission_$H.dat -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/global_wsheds/global_grid_ID_mskNO3.tif -o $DIR/prediction/prediction_$H.tif 
gdal_edit.py -a_nodata -9999  $DIR/prediction/prediction_$H.tif  
pkstat -mm  -nodata -1   -nodata -9999 -i   $DIR/prediction/prediction_$H.tif  > $DIR/prediction/prediction_${H}_min_max.txt  

# includes the -9999 and -1 in the mask to be interpolated  
pkgetmask  -ot Byte  -min -10000  -max -0.5  -co COMPRESS=DEFLATE -co ZLEVEL=9    -data 0 -nodata 1  -i   $DIR/prediction/prediction_$H.tif   -o  $DIR/prediction/prediction_${H}_-1.tif  
pkfillnodata  -m    $DIR/prediction/prediction_${H}_-1.tif  -d 10      -i   $DIR/prediction/prediction_$H.tif  -o   $DIR/prediction/prediction_${H}_fill_tmp.tif 

# $DIR/prediction/prediction_${H}_fill_tmp.tif cisono 2 pixels che non vengono interpolati e quindi li masko 

# re-mask the final results 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/global_prediction/map_pred_NO3_mask.tif  -msknodata -1 -nodata -9999 \
                                            -m $DIR/prediction/prediction_${H}_fill_tmp.tif  -msknodata -1 -nodata -9999 \
 -i  $DIR/prediction/prediction_${H}_fill_tmp.tif  -o  $DIR/prediction/prediction_${H}_fill.tif 

pkstat -mm    -nodata -9999 -i $DIR/prediction/prediction_${H}_fill.tif  > $DIR/prediction/prediction_${H}_fill_min_max.txt 
' _ 

