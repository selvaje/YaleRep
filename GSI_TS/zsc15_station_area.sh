IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap



for file in $IN/Q??_1958to2022.csv  $IN/Q???_1958to2022.csv  ; do 
    paste -d "," $IN/lonlat.csv $file | grep -v  "124\.4833,1\.4833" | awk -F "," '{if ($2 > -60 && $2 < 85) {for (col=3; col <= NF; col++) {printf ("%s\n", $col)}}}' > $OUT/$(basename $file .csv)_1col.txt
done
                                                                            ## station in the sea        ### transpose from west to east 
awk  -F "," '{if ($2 >= -60 &&  $2 <= 85 ) {print $1,$2}}' $IN/lonlat.csv | grep -v  "124\.4833 1\.4833"   | sed   's/-179.2500 66.4100/180.7500 66.4100/g'  >   $IN/x_y.txt
awk         '{ print $1,$2, NR  }'  $IN/x_y.txt > $IN/x_y_ID.txt
awk         '{ print NR, $1,$2  }'  $IN/x_y.txt > $IN/ID_x_y.txt 

awk -F "," '{ for (col = 1; col <= 780 ; col++ ) {printf ("%s\n", $1)}}' $IN/ID_x_y.txt    > $OUT/ID_lonlat_1col.txt


# for YYYY in $(seq 1958 2022) ; do for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $YYYY $MM ; done ; done > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt
# rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# for time in $( seq 1 $(wc  -l $IN/x_y_ID.txt | awk '{print $1}')) ; do   
#    cat  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt  >> /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# done 

paste -d " " $OUT/ID_lonlat_1col.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt $OUT/Qmin_1958to2022_1col.txt \
      $OUT/Q10_1958to2022_1col.txt  $OUT/Q20_1958to2022_1col.txt $OUT/Q30_1958to2022_1col.txt $OUT/Q40_1958to2022_1col.txt $OUT/Q50_1958to2022_1col.txt \
      $OUT/Q60_1958to2022_1col.txt  $OUT/Q70_1958to2022_1col.txt $OUT/Q80_1958to2022_1col.txt $OUT/Q90_1958to2022_1col.txt \
      $OUT/Qmax_1958to2022_1col.txt | grep -v "NaN" > $OUT/ID_lonlat_date_Qquantiles.txt 

awk  '{ print $1 , $2 , $3 , $4 , $5   }'  $OUT/ID_lonlat_date_Qquantiles.txt  > $OUT/ID_lonlat_date_4Qquantiles.txt
awk  '{ print $6 , $7 , $8 , $9 , $10 , $11, $12 , $13 , $14, $15 , $16 }'  $OUT/ID_lonlat_date_Qquantiles.txt  > $OUT/Qquantiles.txt

#  rm $OUT/Q*_1958to2022_1col.txt

exit

cut -d " " -f2-20   quantiles_swap/ID_lonlat_date_Qquantiles.txt | uniq | wc -l    12523963



wc -l lonlat.csv x_y_ID.txt x_y.txt 
  41263 lonlat.csv
  41233 x_y_ID.txt
  41233 x_y.txt

32161740  = echo "41233 * 780" | bc 

wc -l $OUT/lonlat_1col.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt $OUT/Qmin_1958to2022_1col.txt 
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/lonlat_1col.txt
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/Qmin_1958to2022_1col.txt
