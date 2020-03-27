


~/bin/pkfilter -co  COMPRESS=LZW -co ZLEVEL=9 -co  INTERLEAVE=BAND -f savgolay   -nl 2  -nr 2 -ld 0 -m 2    -of  GTiff  -dx 1 -dy 1 -dz 1   -i  LST_MOD_QC_dayALL_tilef_Day.tif  -o LST_MOD_QC_dayALL_tilef_Day_sg.tif
gdallocationinfo -valonly   LST_MOD_QC_dayALL_tilef_Day.tif     958 796 > nofilter.txt
gdallocationinfo -valonly   LST_MOD_QC_dayALL_tilef_Day_sg.tif  958 796  > filter.txt
paste nofilter.txt date.txt > nofilter_date.txt
paste filter.txt date.txt > filter_date.txt

gnuplot
gnuplot> plot 'nofilter_date.txt'  u 2:1 
gnuplot> plot 'nofilter_date.txt'  u 2:1 ,  'filter_date.txt'  u 2:1



