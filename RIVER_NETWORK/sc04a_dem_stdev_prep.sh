export DIR=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev

# X=172800
# Y=69120 

# cp /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd_LandEnlarge.tif /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin 0 0 1000 69120        $DIR/be75_grd_LandEnlarge.tif $DIR/be75_grd_LandEnlarge_left.tif 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin 171800 0 1000  69120  $DIR/be75_grd_LandEnlarge.tif $DIR/be75_grd_LandEnlarge_right.tif 

# pixel=0.00001

# gdal_edit.py   -a_ullr   0 84   $( echo $X  \* $pixel  | bc )    $( echo 84 - $Y \* $pixel  | bc )  $DIR/be75_grd_LandEnlarge.tif
# gdal_edit.py   -a_ullr   $( echo 0 - 1000 \* $pixel | bc ) 84 0 $( echo 84 - $Y \* $pixel  | bc )  $DIR/be75_grd_LandEnlarge_right.tif 
# gdal_edit.py   -a_ullr   $( echo $X \* $pixel | bc ) 84 $(echo $X  \* $pixel + 0.01  | bc)  $(echo 84 - $Y \* $pixel  | bc )            $DIR/be75_grd_LandEnlarge_left.tif 

# gdalbuildvrt -overwrite   $DIR/out.vrt    $DIR/be75_grd_LandEnlarge.tif $DIR/be75_grd_LandEnlarge_left.tif   $DIR/be75_grd_LandEnlarge_right.tif 
# gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/out.vrt  $DIR/be75_grd_LandEnlarge_leftright.tif 

# Size is 174800, 69120  $DIR/be75_grd_LandEnlarge_leftright.tif  174800 / 40 = 4370  tile size 500  overlap 



seq 0 39 | xargs -n 1 -P 10  bash -c $' 
tile=$1
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9   -srcwin $( echo 4370  \* $tile | bc ) 0  $( echo 4370  + 500 | bc )  69120  $DIR/be75_grd_LandEnlarge_leftright.tif  $DIR/be75_grd_LandEnlarge_leftright_t$tile.tif
' _ 




