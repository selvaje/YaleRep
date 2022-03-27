#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc06_prediction_Nemision.sh
#SBATCH -n 1 -c 4  -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_prediction_Nemision-last.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_prediction_Nemision-last.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc06_prediction_Nemision-last.sh 

export DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO


# awk   -F "," '{ if (NR>1) print $2, -9999    }'  $DIR/prediction/Main_input_output.csv  > $DIR/prediction/Main_input_output_ID.txt 
# pkreclass -m $DIR/global_prediction/map_pred_TN_mask.tif -msknodata -1 -nodata -9999 --code $DIR/prediction/Main_input_output_ID.txt -ot  Int32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/global_wsheds/global_grid_ID_mskNO3.tif -o $DIR/prediction/missingID.tif 
# rm $DIR/prediction/Main_input_output_ID.txt 
# pkgetmask -min -0.5 -max 99999999999  -data 1  -nodata 255  -ot  Int16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/prediction/missingID.tif -o $DIR/prediction/missingID_msk.tif 


echo   Main_input_output_SA.txt 6  Main_input_output_ERN2O.txt 9   Main_input_output_FDIN0.txt  10 Main_input_output_FN2O.txt 11  | xargs -n 2  -P 4 bash -c $'  
file=$1
col=$2
filename=$( basename $file .txt  )

echo $file 

if [ $filename =  "Main_input_output_FDIN0"   ] ; then 
awk -v col=$col  -F "," \'{ if (NR>1) print $2, int( $col / 1000 )   }\'  $DIR/prediction/Main_input_output.csv  > $DIR/prediction/$file
else 
awk -v col=$col  -F "," \'{ if (NR>1) print $2, $col   }\'           $DIR/prediction/Main_input_output.csv  > $DIR/prediction/$file
fi 

pkreclass  -m $DIR/global_prediction/map_pred_TN_mask.tif   -msknodata -1 -nodata -9999  \
           -m $DIR/global_prediction/map_pred_NO3_mask.tif  -msknodata -1 -nodata -9999  \
           -m $DIR/prediction/missingID_msk.tif             -msknodata  1 -nodata -9999  \
           --code $DIR/prediction/$file -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/global_wsheds/global_grid_ID_mskNO3.tif -o $DIR/prediction/$filename.tif

pksetmask  -m $DIR/global_prediction/map_pred_TN_mask.tif   -msknodata -1 -nodata -9999  \
           -m $DIR/global_prediction/map_pred_NO3_mask.tif  -msknodata -1 -nodata -9999  \
           -m $DIR/prediction/missingID_msk.tif             -msknodata  1 -nodata -9999  \
           -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/prediction/$filename.tif -o  $DIR/prediction/${filename}_msk.tif

gdal_edit.py -a_nodata -9999  $DIR/prediction/$filename.tif
gdal_edit.py -a_nodata -9999  $DIR/prediction/${filename}_msk.tif
pkstat -mm  -nodata -1   -nodata -9999 -i  $DIR/prediction/$filename.tif          > $DIR/prediction/$filename.mm
pkstat -mm  -nodata -1   -nodata -9999 -i  $DIR/prediction/${filename}_msk.tif    > $DIR/prediction/${filename}_msk.mm

oft-reclass   -oi $DIR/prediction/${filename}_oft.tif  $DIR/global_wsheds/global_grid_ID_mskNO3.tif <<EOF
$DIR/prediction/$file
1
1
2
-9999
EOF

pksetmask  -m $DIR/global_prediction/map_pred_TN_mask.tif     -msknodata -1 -nodata -9999  \
           -m $DIR/global_prediction/map_pred_NO3_mask.tif    -msknodata -1 -nodata -9999  \
           -m $DIR/prediction/missingID_msk.tif               -msknodata  1 -nodata -9999  \
           -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/prediction/${filename}_oft.tif -o  $DIR/prediction/${filename}_oft_msk.tif

gdal_edit.py -a_nodata -9999    $DIR/prediction/${filename}_oft_msk.tif


# awk \'{  print $1 ":" $1 ":" $2 ":" $2 }\'  $DIR/prediction/$file   >   $DIR/prediction/${file}.grass   

# rm -fr  $DIR/prediction/loc_$filename
# source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $DIR/prediction  loc_$filename  $DIR/global_wsheds/global_grid_ID_mskNO3.tif 

# r.recode input=global_grid_ID_mskNO3  output=$filename  rules=$DIR/prediction/${file}.grass   

# r.out.gdal -f --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Float32  format=GTiff nodata=-9999    input=$filename output=$DIR/prediction/${filename}_G.tif 

# pksetmask -m $DIR/global_prediction/map_pred_TN_mask.tif   -msknodata -1 -nodata -9999  \
#           -m $DIR/global_prediction/map_pred_NO3_mask.tif  -msknodata -1 -nodata -9999  \
#           -m $DIR/prediction/missingID_msk.tif             -msknodata  1 -nodata -9999  \
#           -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/prediction/${filename}_G.tif -o  $DIR/prediction/${filename}_G_msk.tif
# gdal_edit.py -a_nodata -9999  $DIR/prediction/${filename}_G_msk.tif
# pkstat -mm  -nodata -1   -nodata -9999 -i  $DIR/prediction/${filename}_G_msk.tif    > $DIR/prediction/${filename}_G_msk.mm

# rm -r  $DIR/prediction/loc_$filename

' _


# pkgetmask -min -10000  -max -9998   -data 0  -nodata 1  -ot  Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/prediction/Main_input_output_FN2O_msk.tif -o  $DIR/prediction/Main_input_output_msk_0_1.tif 
# pksetmask -m $DIR/prediction/Main_input_output_msk_0_1.tif -msknodata 0 -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/tif/COSCAT_1km.tif -o $DIR/prediction/COSCAT_1km_msk.tif
# gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $(getCorners4Gtranslate   $DIR/prediction/Main_input_output_msk_0_1.tif) $DIR/prediction/COSCAT_1km_msk.tif  $DIR/prediction/COSCAT_1km_msk_crop.tif


echo  Main_input_output_SA    Main_input_output_ERN2O    Main_input_output_FDIN0  Main_input_output_FN2O   | xargs -n 1  -P 4 bash -c $'  
oft-stat    -i  $DIR/prediction/${1}_msk.tif -o   $DIR/prediction/${1}_COSCAT.txt   -um   $DIR/prediction/COSCAT_1km_msk_crop.tif  -mm 

echo "id,npix,min,max,mean,stdev"   > $DIR/prediction/${1}_COSCAT.csv 
awk \'{ print $1","$2","$3","$4","$5","$6  }\'  $DIR/prediction/${1}_COSCAT.txt  >>    $DIR/prediction/${1}_COSCAT.csv 


' _ 


export DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO

pksetmask -m $DIR/global_prediction/map_pred_TN_mask.tif   -msknodata -1 -nodata -9999  \
          -m $DIR/global_prediction/map_pred_NO3_mask.tif  -msknodata -1 -nodata -9999  \
          -m $DIR/prediction/missingID_msk.tif             -msknodata  1 -nodata -9999  \
          -m $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk.tif -msknodata -1 -nodata -9999  \
          -m /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/tif/COSCAT_1km.tif -msknodata 0  -nodata -9999  \
          -ot  Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk.tif   -o $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.tif  
gdal_edit.py -a_nodata -9999   $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.tif  


pkgetmask -min -10000  -max -9998   -data 0  -nodata 1  -ot  Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.tif  -o  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_4coscat.tif  
pksetmask -m  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_4coscat.tif  -msknodata 0 -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/tif/COSCAT_1km.tif  -o $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_COSCAT.tif  

oft-stat  -i $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.tif  -o  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_COSCAT.txt -um $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_COSCAT.tif     -mm 

echo "id,npix,min,max,mean,stdev"   > $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.csv
awk '{ print $1","$2","$3","$4","$5","$6  }'  $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert_COSCAT.txt  >> $DIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_msk_nodesert.csv 


exit

