

DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/global_wsheds 




awk -F "," '{ if (NR>1) print $1 , $2  } ' $DIR/monthly_mean_min_max_1950_2000_yr3_stream_temp.csv  > $DIR/x_y_temp_obs.txt


for n in 4  ; do 
for file in tmax_avg.tif tmax_wavg.tif tmean_avg.tif tmean_wavg.tif tmin_avg.tif tmin_wavg.tif ; do 

echo $file $n $( bash /gpfs/loomis/home.grace/fas/sbsc/ga254/scripts/general/pearson_awk.sh \
 <(  paste -d" " <(gdallocationinfo -valonly -geoloc -wgs84 $DIR/$file  < x_y_temp_obs.txt | awk '{ print $1/10   }'  ) \
 <( awk -v n=$n   -F "," '{ if (NR>1) print $n   } ' $DIR/monthly_mean_min_max_1950_2000_yr3_stream_temp.csv )  | grep -v 999.9  ) 1 2  ) 

done 
done | sort -k 3,3 -g 



paste -d" " <(gdallocationinfo -valonly -geoloc -wgs84 $DIR/tmean_wavg.tif  < x_y_temp_obs.txt | awk '{ print $1/10   }'  ) \
 <( awk    -F "," '{ if (NR>1) print $4   } ' $DIR/monthly_mean_min_max_1950_2000_yr3_stream_temp.csv )  | grep -v 999.9  > tmean_wavg_tmean_obs.txt 
