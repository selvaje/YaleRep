DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K


# Historical (1960-2015) yearly minimum, mean, maximum river discharge trends                                                                                                                                                               
# Plotted trends in graph; and data tables in CSV format                                                                                                                                                                                    
# Brahmaputra   Lat 24.0050  Long  89.6850   Bera             
# Brahmaputra   Lat 26.9100  Long  94.21800  Jorhat        94.21800  26.9100                                                                                                                                                                
# Brahmaputra   Lat 26.4127  Long  92.1698   Guwahati      92.16980  29.4127                                                                                                                                                                
# Brahmaputra   Lat 28.2574  Long  94.9869   beiben       95.2035 29.2709

# https://www.google.com/maps/place/24%C2%B000'18.0%22N+89%C2%B041'06.0%22E/@22.9903932,89.9919104,8.29z/data=!4m5!3m4!1s0x0:0x0!8m2!3d24.005!4d89.685                                                                                      
# https://www.google.com/maps/place/26%C2%B054'36.0%22N+94%C2%B013'04.8%22E/@26.7763515,94.2039319,9.33z/data=!4m5!3m4!1s0x0:0x0!8m2!3d26.91!4d94.218                                                                                       
# https://www.google.com/maps/place/26%C2%B024'45.7%22N+92%C2%B010'11.3%22E/@26.428006,92.1490225,12.83z/data=!4m5!3m4!1s0x0:0x0!8m2!3d26.4127!4d92.1698                                                                                    
# https://www.google.com/maps/place/29%C2%B016'15.2%22N+95%C2%B012'12.6%22E/@29.255042,95.2081115,13.75z/data=!4m5!3m4!1s0x0:0x0!8m2!3d29.2709!4d95.2035

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin 81.5 26    82.5 25   FLO1K.ts.1960.2015.qav_mean.tif  allahabad/FLO1K.ts.1960.2015.qav_mean_allahabad.tif                                                                        

# paste  <(seq 1960 2015)  <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 89.6850  24.0050) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc 89.6850 24.0050) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc 89.6850 24.0050) > $DIR/brahmaputra/bera_min_mean_max.txt

# paste  <(seq 1960 2015)  <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 94.21800 26.9100) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc 94.21800 26.9100) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc 94.21800 26.9100) > $DIR/brahmaputra/jorhat_min_mean_max.txt

# paste  <(seq 1960 2015)  <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 92.16980 26.4127) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc 92.16980 26.4127) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc 92.16980 26.4127) > $DIR/brahmaputra/guwahati_min_mean_max.txt

paste  <(seq 1960 2015)  <(gdallocationinfo -geoloc -valonly $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 95.2035 29.2709) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc 95.2035 29.2709) <(gdallocationinfo -geoloc -valonly  $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc 95.2035 29.2709) > $DIR/brahmaputra/beiben_min_mean_max.txt



exit


table = read.table("jorhat_min_mean_max.txt" , header=F)
plot (table$V1 ,  table$V2, type="l" , ylim=c(min(table),max(table)) , col="green" , xlab="Year" , ylab="Discharge (m3/s)" )  ;  lines (table$V1 ,  table$V3, type="l" , col="black")  ; lines (table$V1 ,  table$V4, type="l" , col="red")
abline ( lm (table$V4 ~  table$V1 ) , col='red')  ;  abline ( lm (table$V3 ~  table$V1 ) , col='black')  ; abline ( lm (table$V2 ~  table$V1 ) , col='green')  ;


table = read.table("guwahati_min_mean_max.txt" , header=F)
plot (table$V1 ,  table$V2, type="l" , ylim=c(min(table),max(table)) , col="green" , xlab="Year" , ylab="Discharge (m3/s)" )  ;  lines (table$V1 ,  table$V3, type="l" , col="black")  ; lines (table$V1 ,  table$V4, type="l" , col="red")
abline ( lm (table$V4 ~  table$V1 ) , col='red')  ;  abline ( lm (table$V3 ~  table$V1 ) , col='black')  ; abline ( lm (table$V2 ~  table$V1 ) , col='green')  ;


