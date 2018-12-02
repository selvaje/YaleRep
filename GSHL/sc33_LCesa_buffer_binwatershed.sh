# combine the dataset for buffwer and watershed bin data 

DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin/LST_plot_bin_buf

echo Madrid     -3.705310  40.409888 >  $DIR/city.txt
echo London     -0.114860  51.514306 >> $DIR/city.txt
echo Birminghan -1.909066  52.483376 >> $DIR/city.txt
echo Paris       2.311222  48.855701 >> $DIR/city.txt
echo Lyon        4.841879  45.741073 >> $DIR/city.txt
echo Barcelona   2.171079  41.404551 >> $DIR/city.txt
echo Lisbon     -9.142181  38.725270 >> $DIR/city.txt
echo Milan       9.179801  45.463652 >> $DIR/city.txt 
echo Roma       12.496749  41.888596 >> $DIR/city.txt
echo Palermo    13.356540  38.119028 >> $DIR/city.txt
echo Athene     23.725916  37.953777 >> $DIR/city.txt
echo Dusseldorf  6.810924  51.217426 >> $DIR/city.txt
echo Munchen    11.574068  48.137742 >> $DIR/city.txt
echo Amesterdam  4.893276  52.351364 >> $DIR/city.txt


export    LST=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin

cat   $DIR/city.txt     | xargs -n 3 -P 1  bash -c $' 

echo $1 $(gdallocationinfo  -geoloc -wgs84 -valonly  $LST/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin6_clump.tif    $2 $3  ) 

' _ > $DIR/city_bin6ID.txt 


# LST_plot_bin_buf/city_bin6ID.txt LST_plot_buf/city_bin6ID.txt 
# Madrid     378441                Madrid     66232
# London     371544                London     17101
# Birminghan 370731                Birminghan 12288
# Paris      373596                Paris      32205
# Lyon       375291                Lyon       47150
# Barcelona  377588                Barcelona  61362
# Lisbon     379662                Lisbon     71506
# Milan      375468                Milan      48694
# Roma       377328                Roma       60392
# Palermo    380007                Palermo    74285
# Athens     380044                Athens     75119
# Dusseldorf 371779                Dusseldorf 18120
# Munchen    373976                Munchen    35520
# Amesterdam 370773                Amesterdam 13064


paste $LST/LST_plot_bin_buf/city_bin6ID.txt $LST/LST_plot_buf/city_bin6ID.txt  > $LST/city_bin_buf.txt 

cat $LST/city_bin_buf.txt  | xargs -n 4 -P 1 bash -c  $' 

join -1 1 -1 1  -a 1  $LST/LST_plot/LST_MOYDmax_Day_value_${2}rec_bin_meanLST.txt  $LST/LST_plot_buf/LST_MOYDmax_Day_value_${4}_meanLST.txt

echo "########################"
                   
' _



