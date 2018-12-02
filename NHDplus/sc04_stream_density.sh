

DIR=/project/fas/sbsc/ga254/dataproces/NHDplus 

#  ~/bin/pkfilter -ct "none" -ot UInt16   -co COMPRESS=DEFLATE -co ZLEVEL=9   -d 40 -dx 40 -dy 40  -f sum -i /project/fas/sbsc/ga254/dataproces/NHDplus/NHDplus_H_250m_norm.tif   -o $DIR/NHDplus_H_10km_sum.tif

pkstat -hist -i $DIR/NHDplus_H_10km_sum.tif > $DIR/NHDplus_H_10km_sum.txt 


gdal_edit.py -a_nodata 0  /project/fas/sbsc/ga254/dataproces/NHDplus/NHDplus_H_10km_sum.tif 

rm -r /project/fas/sbsc/ga254/dataproces/NHDplus/grassdb/location
/gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh /project/fas/sbsc/ga254/dataproces/NHDplus/grassdb location /project/fas/sbsc/ga254/dataproces/NHDplus/NHDplus_H_10km_sum.tif 

perc=50 ; r.quantile -r  input=NHDplus_H_10km_sum  percentile=$perc | r.recode NHDplus_H_10km_sum out=NHDplus_H_10km_sum_p$perc rules=- --o
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte   format=GTiff nodata=0   input=NHDplus_H_10km_sum_p$perc     output=$DIR/NHDplus_H_10km_sum_p${perc}.tif 

perc=75 ; r.quantile -r  input=NHDplus_H_10km_sum  percentile=$perc | r.recode NHDplus_H_10km_sum out=NHDplus_H_10km_sum_p$perc rules=- --o
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte   format=GTiff nodata=0   input=NHDplus_H_10km_sum_p$perc     output=$DIR/NHDplus_H_10km_sum_p${perc}.tif 



exit



# usefull for buffer distance arround the stream 
r.stream.distance  stream_rast=stream  direction=drainage distance=distance  --overwrite
