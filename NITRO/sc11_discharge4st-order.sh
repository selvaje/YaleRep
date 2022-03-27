#!/bin/bash
#SBATCH -p day
#SBATCH -J sc10_pred_analysis.sh 
#SBATCH -n 1 -c 3  -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_discharge4st-order.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_discharge4st-order.sh.%J.err
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc11_discharge4st-order.sh

export WIDTH=/project/fas/sbsc/ga254/dataproces/NITRO/width_pred
export ORDER=/project/fas/sbsc/sd566/global_wsheds/global_results_merged/netCDF/stream_order_lakes0.tif
export FLO=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/FLO1K
export NITRO=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO
export RAM=/dev/shm

# w_pete1  <- (0.510 * x ) + 1.86              =   
# w_pete2  <- (0.423 * x ) + 2.56              =
# a-coefficient = 8.5 and b-exponent = 0.47    =
# w_georg  <- (0.47  * x ) + log(8.5)          =


# exp(log (x)^0. + 2.)
# due that 
# exp ( 2.4 * log(4) + 2.3 )  =   (4^2.4) *  exp(2.3 ) 

# w_pete1  <- (0.510 * log (q)  ) + 1.86    to obtain w =  exp ((0.510 * log (q)  ) + 1.86)



# gdal_calc.py --co=COMPRESS=LZW --co=ZLEVEL=9 --co=INTERLEAVE=BAND --NoDataValue=-9999 --type='Float32' -A $FLO/FLO1K.ts.1960.2015.qav_mean_fill_msk.tif \
# --calc="(exp( log((A.astype(float) + 0.00001 ) * 0.510 ) + 1.86))"   --outfile=$WIDTH/width_EQpete1.tif  --overwrite

# gdal_calc.py --co=COMPRESS=LZW --co=ZLEVEL=9 --co=INTERLEAVE=BAND --NoDataValue=-9999 --type='Float32' -A $FLO/FLO1K.ts.1960.2015.qav_mean_fill_msk.tif \
# --calc="(exp( log((A.astype(float) + 0.00001 ) * 0.423 ) + 2.56))"  --outfile=$WIDTH/width_EQpete2.tif  --overwrite

# gdal_calc.py --co=COMPRESS=LZW --co=ZLEVEL=9 --co=INTERLEAVE=BAND --NoDataValue=-9999 --type='Float32' -A $FLO/FLO1K.ts.1960.2015.qav_mean_fill_msk.tif \
# --calc="(exp( log((A.astype(float) + 0.00001 ) * 0.470 ) + 2.14))"  --outfile=$WIDTH/width_EQgeor1.tif  --overwrite

# for EQ in pete1 pete2 geor1 ; do 
# export EQ
# seq 1 9 | xargs  -n 1 -P 3 bash -c $'
# ORD=$1

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $ORDER  -msknodata $ORD  -nodata -1 -p "!"  -i $WIDTH/width_EQ${EQ}.tif   -o  $WIDTH/width_EQ${EQ}_order${1}.tif 
# gdalinfo -stats  $WIDTH/width_EQ${EQ}_order${1}.tif   | grep MEAN | awk -F "=" \'{ print $2  }\' > $WIDTH/width_EQ${EQ}_mean_order${1}.txt
# rm -f  $WIDTH/width_EQ${EQ}_order${1}.tif.aux.xml 
# rm -f  $WIDTH/width_EQ${EQ}_order${1}.tif

# ' _ 

# cat $WIDTH/width_EQ${EQ}_mean_order?.txt  > $WIDTH/width_EQ${EQ}_mean.txt
# rm -f $WIDTH/width_EQ${EQ}_mean_order?.txt
# done 

# echo "ORD EQpete1 EQpete2 EQgeor1" > $WIDTH/width_all_mean.txt 
# paste <(seq 1 9 ) $WIDTH/width_EQpete1_mean.txt $WIDTH/width_EQpete2_mean.txt  $WIDTH/width_EQgeor1_mean.txt >> $WIDTH/width_all_mean.txt

# width and length for stream order 

# awk '{if(NR>1) print $2 ,   $11   }' $NITRO/emision_table_valid_cor_area_width.txt | sort -k 1,1  > $NITRO/Cell_ID_WQmean.txt &
# awk '{if(NR>1) print $2 ,   $12   }' $NITRO/emision_table_valid_cor_area_width.txt | sort -k 1,1 > $NITRO/Cell_ID_Length.txt 

# # L = mean(sqrt(A), sqrt(2*A))
# awk '{if(NR>1) print $2 ,   ($12 + sqrt ( ($12^2) * 2 ) ) / 2 }' $NITRO/emision_table_valid_cor_area_width.txt | sort -k 1,1 > $NITRO/Cell_ID_Length2.txt 

# join -a 1 -1 1 -2 1 global_wsheds/global_grid_ID_mskNO3_clean_s.txt $NITRO/Cell_ID_WQmean.txt  | awk '{if (NF==1) {print $1, -9999} else { print $1 , $2 }}' > $NITRO/Cell_ID_WQmean_4rec.txt   &
# join -a 1 -1 1 -2 1 global_wsheds/global_grid_ID_mskNO3_clean_s.txt $NITRO/Cell_ID_Length.txt  | awk '{if (NF==1) {print $1, -9999} else { print $1 , $2 }}' > $NITRO/Cell_ID_Length_4rec.txt 
# join -a 1 -1 1 -2 1 global_wsheds/global_grid_ID_mskNO3_clean_s.txt $NITRO/Cell_ID_Length2.txt | awk '{if (NF==1) {print $1, -9999} else { print $1 , $2 }}' > $NITRO/Cell_ID_Length2_4rec.txt  

# pkreclass -m $NITRO/global_prediction/map_pred_TN_mask.tif -msknodata -1 -nodata -9999 --code $NITRO/Cell_ID_WQmean_4rec.txt   \
#    -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $NITRO/global_wsheds/global_grid_ID_mskNO3.tif -o $NITRO/prediction/prediction_WQmean.tif &

# pkreclass -m $NITRO/global_prediction/map_pred_TN_mask.tif -msknodata -1 -nodata -9999 --code $NITRO/Cell_ID_Length_4rec.txt   \
#    -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $NITRO/global_wsheds/global_grid_ID_mskNO3.tif -o $NITRO/prediction/prediction_Length.tif 

# pkreclass -m $NITRO/global_prediction/map_pred_TN_mask.tif -msknodata -1 -nodata -9999 --code $NITRO/Cell_ID_Length2_4rec.txt     \
#    -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $NITRO/global_wsheds/global_grid_ID_mskNO3.tif -o $NITRO/prediction/prediction_Length2.tif

# rm $NITRO/Cell_ID_*.txt 


# for file in $NITRO/prediction/prediction_Length.tif $NITRO/prediction/prediction_Length2.tif $NITRO/prediction/prediction_WQmean.tif ; do 

# export file 
# export filename=$( basename $file .tif )

# seq 1 9 | xargs  -n 1 -P 3 bash -c $'
# ORD=$1

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $ORDER  -msknodata $ORD  -nodata -9999  -p "!"  -i $file -o  $NITRO/prediction/${filename}_order${1}.tif 
# gdal_edit.py -a_nodata -9999  $NITRO/prediction/${filename}_order${1}.tif 
# gdalinfo -stats   $NITRO/prediction/${filename}_order${1}.tif    | grep MEAN | awk -F "=" \'{ printf("%.2f\\n", $2)  }\' >  $NITRO/prediction/${filename}_order${1}.txt
# rm -f  $NITRO/prediction/${filename}_order${1}.tif.aux.xml 

# # multiply the mean for the number of pixels 
# if [ $filename != "prediction_WQmean"  ] ; then 
# ncell=$(pkstat -nbin 1 -nodata -9999 -hist  -i $NITRO/prediction/${filename}_order${1}.tif  | awk \'{  print $2  }\')
# awk -v ncell=$ncell  \'{  printf("%.2f\\n", $1 * ncell ) }\'  $NITRO/prediction/${filename}_order${1}.txt    >  $NITRO/prediction/${filename}_order${1}.txtdel 
# mv  $NITRO/prediction/${filename}_order${1}.txtdel  $NITRO/prediction/${filename}_order${1}.txt 
# fi  

# #### rm -f  $NITRO/prediction/${filename}_order${1}.tif 

# ' _ 

# cat   $NITRO/prediction/${filename}_order?.txt  > $NITRO/prediction/${filename}_order_mean.txt
# rm -f $NITRO/prediction/${filename}_order?.txt

# done 

# echo Order WQmean Length Length2   > $NITRO/prediction/Order_WQmean_Length_Length2.txt 
# paste <(seq 1 9 ) $NITRO/prediction/prediction_WQmean_order_mean.txt $NITRO/prediction/prediction_Length_order_mean.txt  $NITRO/prediction/prediction_Length2_order_mean.txt  >> $NITRO/prediction/Order_WQmean_Length_Length2.txt 

############## add attribute to coscat region 

# crop comscat 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $NITRO/prediction/prediction_Length2_order1.tif) /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/tif/COSCAT_1km.tif  $RAM/COSCAT_1km_crop.tif   

echo   $NITRO/prediction/prediction_Length.tif $NITRO/prediction/prediction_Length2.tif $NITRO/prediction/prediction_WQmean.tif | xargs -n 1 -P 3 bash -c $' 
export file=$1 
export filename=$( basename $file .tif ) 
export mesure=${filename:11:8}


for ORD in $(seq 1 9) ; do 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9   -m $NITRO/prediction/${filename}_order${ORD}.tif  -msknodata -9999 -nodata 0   -i $RAM/COSCAT_1km_crop.tif  -o  $NITRO/COSCAT/COSCAT_1km_${mesure}_order${ORD}_msk.tif   

if [ $filename = prediction_WQmean ] ; then 
oft-stat    -i  $NITRO/prediction/${filename}_order${ORD}.tif  -o  $NITRO/COSCAT/COSCAT_order${ORD}_$mesure.txt   -um  $NITRO/COSCAT/COSCAT_1km_${mesure}_order${ORD}_msk.tif -nostd 

else 
oft-stat-sum -i  $NITRO/prediction/${filename}_order${ORD}.tif  -o  $NITRO/COSCAT/COSCAT_order${ORD}_$mesure.txt  -um  $NITRO/COSCAT/COSCAT_1km_${mesure}_order${ORD}_msk.tif -nostd 
fi 

rm -f  $NITRO/COSCAT/COSCAT_1km_${mesure}_order${ORD}_msk.tif 
done 



# join    -a 1 -e EMPTY -o auto   -1 1 -2 1 test1 test2 

echo SBCODE ORD1 ORD2 ORD3 ORD4 ORD5 ORD6 ORD7 ORD8 ORD9  > $NITRO/COSCAT/COSCAT_order_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(awk \'{print $1,$3}\' $NITRO/COSCAT/COSCAT_order1_$mesure.txt | sort -k 1,1) <(awk \'{print $1,$3}\' $NITRO/COSCAT/COSCAT_order2_$mesure.txt | sort -k 1,1) > $NITRO/COSCAT/COSCAT_order12_$mesure.txt
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order12_$mesure.txt)       <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order3_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order123_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order123_$mesure.txt)      <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order4_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order1234_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order1234_$mesure.txt)     <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order5_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order12345_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order12345_$mesure.txt)    <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order6_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order123456_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order123456_$mesure.txt)   <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order7_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order1234567_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order1234567_$mesure.txt)  <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order8_$mesure.txt | sort -k 1,1) >  $NITRO/COSCAT/COSCAT_order12345678_$mesure.txt 
join -a 1 -e EMPTY -o auto -1 1 -2 1  <(sort -k 1,1  $NITRO/COSCAT/COSCAT_order12345678_$mesure.txt) <(awk \'{print $1 ,  $3}\' $NITRO/COSCAT/COSCAT_order9_$mesure.txt | sort -k 1,1) >> $NITRO/COSCAT/COSCAT_order_$mesure.txt 



rm -f $NITRO/COSCAT/COSCAT_order1*_$mesure.txt 
# rm -f $NITRO/COSCAT/COSCAT_order?_$mesure.txt 


' _ 

rm -f $RAM/COSCAT_1km_crop.tif   

exit 

############## add attribute to coscat region  very slow to use shp 

echo   $NITRO/prediction/prediction_Length.tif $NITRO/prediction/prediction_Length2.tif $NITRO/prediction/prediction_WQmean.tif | xargs -n 1 -P 3 bash -c $' 
export file=$1 
export filename=$( basename $file .tif ) 
export mesure=${filename:11:8}

if [ $filename = prediction_WQmean ] ; then rule=mean ; else rule=sum ; fi 

rm -f $NITRO/COSCAT/COSCAT_order1_$mesure.*
pkextractogr  -srcnodata -9999 -f "ESRI Shapefile"    -r $rule -s /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/shp/COSCAT.shp -i $NITRO/prediction/${filename}_order1.tif -o $NITRO/COSCAT/COSCAT_order1_$mesure.shp

for ORD in $(seq 2 9) ; do 
ORDP=$(expr $ORD - 1 )
pkextractogr  -srcnodata -9999 -f "ESRI Shapefile"    -r $rule -s  $NITRO/COSCAT/COSCAT_order${ORDP}_$mesure.shp     -i   $NITRO/prediction/${filename}_order${ORD}.tif -o $NITRO/COSCAT/COSCAT_order${ORD}_$mesure.shp 
rm -f $NITRO/COSCAT/COSCAT_order${ORDP}_$mesure.*
done 

rm -f $NITRO/COSCAT/COSCAT_order1_$mesure.*
mv $NITRO/COSCAT/COSCAT_order1_$mesure.shp  $NITRO/COSCAT/COSCAT_order_$mesure.shp
mv $NITRO/COSCAT/COSCAT_order1_$mesure.prj  $NITRO/COSCAT/COSCAT_order_$mesure.prj
mv $NITRO/COSCAT/COSCAT_order1_$mesure.dbf  $NITRO/COSCAT/COSCAT_order_$mesure.dbf
mv $NITRO/COSCAT/COSCAT_order1_$mesure.shx  $NITRO/COSCAT/COSCAT_order_$mesure.shx

' _ 

