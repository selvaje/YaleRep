IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap



for file in $IN/Q??_1958to2022.csv  $IN/Q???_1958to2022.csv  ; do 
    paste -d "," $IN/lonlat.csv $file | grep -v  "124\.4833,1\.4833" | awk -F "," '{if ($2 > -60 && $2 < 85) {for (col=3; col <= NF; col++) {printf ("%s\n", $col)}}}' > $OUT/$(basename $file .csv)_1col.txt
done
                                                                            ## station in the sea        ### transpose from west to east 
awk  -F "," '{if ($2 >= -60 &&  $2 <= 85 ) {print $1,$2}}' $IN/lonlat.csv | grep -v  "124\.4833 1\.4833"   | sed   's/-179.2500 66.4100/180.7500 66.4100/g'  >   $IN/x_y.txt
sort $IN/x_y.txt | uniq |  awk  '{ print $1,$2,NR}'   > $IN/x_y_ID.txt ## uniq lat long and ID
sort $IN/x_y.txt | uniq |  awk  '{ print NR,$1,$2}'   > $IN/ID_x_y.txt

awk -F "," '{ for (col = 1; col <= 780 ; col++ ) {printf ("%s\n", $1)}}' $IN/x_y.txt    > $OUT/lonlat_1col.txt # keep using the all lat long to be able to paste, no yet remove same lat long


# for YYYY in $(seq 1958 2022) ; do for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $YYYY $MM ; done ; done > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt
# rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# for time in $( seq 1 $(wc  -l $IN/x_y.txt | awk '{print $1}')) ; do   
#    cat  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt  >> /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# done 

paste -d " " $OUT/lonlat_1col.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt $OUT/Qmin_1958to2022_1col.txt \
      $OUT/Q10_1958to2022_1col.txt  $OUT/Q20_1958to2022_1col.txt $OUT/Q30_1958to2022_1col.txt $OUT/Q40_1958to2022_1col.txt $OUT/Q50_1958to2022_1col.txt \
      $OUT/Q60_1958to2022_1col.txt  $OUT/Q70_1958to2022_1col.txt $OUT/Q80_1958to2022_1col.txt $OUT/Q90_1958to2022_1col.txt \
      $OUT/Qmax_1958to2022_1col.txt | grep -v "NaN" | sort | uniq  > $OUT/lonlat_date_Qquantiles.txt 

join -1 1 -2 1 <( awk '{ print $2"x"$3,$1}' $IN/ID_x_y.txt| sort) <( awk '{print $1"x"$2,$0}' $OUT/lonlat_date_Qquantiles.txt | sort ) | cut -d " "  -f2-17 >  $OUT/ID_lonlat_date_Qquantiles.txt

awk  '{ print $1 , $2 , $3 , $4 , $5   }'  $OUT/ID_lonlat_date_Qquantiles.txt  > $OUT/ID_lonlat_date_4Qquantiles.txt
awk  '{ print $6 , $7 , $8 , $9 , $10 , $11, $12 , $13 , $14, $15 , $16 }'  $OUT/ID_lonlat_date_Qquantiles.txt  > $OUT/Qquantiles.txt

#  rm $OUT/Q*_1958to2022_1col.txt

exit

wc -l lonlat.csv x_y_ID.txt x_y.txt 
  41263 lonlat.csv
  41233 x_y.txt

wc -l ID_x_y.txt
  40813 

wc -l  $OUT/lonlat_date_Qquantiles.txt   $OUT/IDu_lonlat_date_Qquantiles.txt

12481071 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/lonlat_date_Qquantiles.txt
12481071 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/IDu_lonlat_date_Qquantiles.txt
  
32161740  = echo "41233 * 780" | bc 

wc -l $OUT/lonlat_1col.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt $OUT/Qmin_1958to2022_1col.txt 
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/lonlat_1col.txt
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
  32161740 /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap/Qmin_1958to2022_1col.txt
