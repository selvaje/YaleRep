IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles_swap

for file in $IN/Q??_1958to2022.csv  $IN/Q???_1958to2022.csv  ; do 
    paste -d "," $IN/lonlat.csv $file | grep -v  "124\.4833,1\.4833" | awk -F "," '{if ($2 > -60 && $2 < 85) {for (col=3; col <= NF; col++) {printf ("%s\n", $col)}}}' > $OUT/$(basename $file .csv)_1col.txt
done
                                                                                               ## station in the sea        ### transpose from west to east 
awk  -F "," '{ print  NR, $1, $2  }' $IN/lonlat.csv | awk   '{if ($3 >= -60 &&  $3 <= 85 ) {print $1,$2,$3 } }' | grep -v  "124\.4833 1\.4833"   | sed   's/-179.2500 66.4100/180.7500 66.4100/g'  >   $IN/IDs_x_y.txt  ## IDs IDstation 

awk  '{ print $2,$3}'    $IN/IDs_x_y.txt | sort  | uniq |  awk  '{ print $1,$2,NR}'   > $IN/x_y_IDcu.txt ## IDcu lat long cordinate uniq 
awk  '{ print $3,$1,$2}' $IN/x_y_IDcu.txt  > $IN/IDcu_x_y.txt 

join -1 1 -2 1 <( awk '{ print $2"x"$3,$1}' $IN/IDcu_x_y.txt| sort) <( awk '{print $2"x"$3,$1}'  $IN/IDs_x_y.txt  | sort  ) | awk '{ gsub("x", " ") ; print  $4 , $3 , $1 , $2   }' | sort -k 1 -g > $IN/IDs_IDcu_x_y.txt 

awk '{ for (col = 1; col <= 780 ; col++ ) {printf ("%s %s %s\n",$1, $2,$3)}}' $IN/IDs_x_y.txt  > $OUT/IDs_lonlat_1col.txt # keep using the all lat long to be able to paste, no yet remove same lat long


# for YYYY in $(seq 1958 2022) ; do for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $YYYY $MM ; done ; done > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt
# rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# for time in $( seq 1 $(wc  -l $IN/x_y.txt | awk '{print $1}')) ; do   
#    cat  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date.txt  >> /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt
# done 

paste -d " " $OUT/IDs_lonlat_1col.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/dateNcord.txt $OUT/Qmin_1958to2022_1col.txt \
      $OUT/Q10_1958to2022_1col.txt  $OUT/Q20_1958to2022_1col.txt $OUT/Q30_1958to2022_1col.txt $OUT/Q40_1958to2022_1col.txt $OUT/Q50_1958to2022_1col.txt \
      $OUT/Q60_1958to2022_1col.txt  $OUT/Q70_1958to2022_1col.txt $OUT/Q80_1958to2022_1col.txt $OUT/Q90_1958to2022_1col.txt \
      $OUT/Qmax_1958to2022_1col.txt | grep -v "NaN" | sort | uniq  > $OUT/IDs_lonlat_date_Qquantiles.txt 

join -1 1 -2 1 <( awk '{ print $2"x"$3,$1}' $IN/IDcu_x_y.txt| sort) <( awk '{print $2"x"$3,$0}' $OUT/IDs_lonlat_date_Qquantiles.txt | sort ) | cut -d " "  -f2-18 >  $OUT/IDcu_IDs_lonlat_date_Qquantiles.txt

awk  '{ print $1 , $2 , $3 , $4 , $5 , $6  }'  $OUT/IDcu_IDs_lonlat_date_Qquantiles.txt  > $OUT/IDcu_IDs_lonlat_date_4Qquantiles.txt
awk  '{ print $7 , $8 , $9 , $10 , $11, $12 , $13 , $14, $15 , $16 , $17 }'  $OUT/IDcu_IDs_lonlat_date_Qquantiles.txt > $OUT/Qquantiles.txt

#  rm $OUT/Q*_1958to2022_1col.txt

#### run in colab

import pandas as pd
df = pd.read_csv('station_catalogue.csv', low_memory=False)
df['area'] = df['area'].fillna(-9999)
df['altitude'] = df['altitude'].fillna(-9999)
selected_columns = df[['no','longitude', 'latitude', 'area', 'altitude']]
selected_columns.to_csv('station_catalogue_IDs_lon_lat_area_alt.txt', index=False, header=True, sep=' ')

#####  



exit
#### new coutn

wc -l $IN/IDs_x_y.txt    # IDs IDstation                                   ## 41233 
wc -l $IN/IDcu_x_y.txt   # IDcu ID cordinate uniq                          ## 40813
wc -l $IN/IDs_IDcu_x_y.txt   # IDs IDstation  # IDcu ID cordinate uniq     ## 41233 



#### old count 

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
