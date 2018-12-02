

# super fast done in the loging node 
# bash /gpfs/home/fas/sbsc/ga254/scripts/HYDROSHEDS/sc02_rasterize_vectors.sh

export DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/HYDROSHEDS/shp30sec
export NITRO=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO

# ls $DIR/*.shp | xargs -n 1   -P 7    bash -c $' 
# file=$1
# filename=$( basename $file .shp   )
# gdal_rasterize   -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr  0.00833333333333333 0.00833333333333333 -te $( getCorners4Gwarp  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/prediction/prediction_WQmean_order7.tif ) -init 0  -a_nodata 0 -burn 1 -ot Byte   $file $DIR/$filename.tif
# ' _

# gdalbuildvrt  -srcnodata 0 -vrtnodata 0   $DIR/globe_riv_30s.vrt      $DIR/??_riv_30s.tif   

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    -ot Byte   -a_nodata 0  $DIR/globe_riv_30s.vrt   $DIR/globe_riv_30s.tif

# rm -f   $DIR/globe_riv_30s.vrt


# calculate 


# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/globe_riv_30s.tif    -msknodata 0  -nodata 0  -i $NITRO/global_wsheds/30arc-sec-Area_prj6842_crop.tif   -o $DIR/globe_riv_30s_area.tif 

#  calculate total length  

# pkstat -hist -i $DIR/globe_riv_30s_area.tif | grep -v " 0" > $DIR/globe_riv_30s_area_hist.txt 

awk ' {if (NR>1 )  sum=sum+   ( ( sqrt ( 2 * $1 ) )/1000 *  $2 / 1.080850909  )   } END { printf ("%i\n" , sum )   } '    $DIR/globe_riv_30s_area_hist.txt 

 
