# bash /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc30_equi7_distortion_assment_equi7_wgs84.sh 


export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI7=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm


# rm $SCRATCH/equi7val/*
#                       #   9996100 216900  10010400 202900
#  gdal_translate -projwin   9950000 270000  10010000 210000  $MERIT/equi7/dem/NA/NA_096_000.tif   $SCRATCH/equi7val/NA_equi_south.tif 
#  gdaltindex  $SCRATCH/equi7val/NA_equi_south_shp.shp   $SCRATCH/equi7val/NA_equi_south.tif 

#  gdal_translate  -a_ullr  9950000 8060000  10010000 8000000 $SCRATCH/equi7val/NA_equi_south.tif  $SCRATCH/equi7val/NA_equi_north.tif 
#  gdaltindex  $SCRATCH/equi7val/NA_equi_north_shp.shp   $SCRATCH/equi7val/NA_equi_north.tif 
 # from equi7 to wgs84

# gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9  -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333   -r bilinear  -overwrite    $SCRATCH/equi7val/NA_equi_north.tif     $SCRATCH/equi7val/NA_equi_north_towgs84.tif 

# gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9  -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333   -r bilinear  -overwrite    $SCRATCH/equi7val/NA_equi_south.tif     $SCRATCH/equi7val/NA_equi_south_towgs84.tif 



# # calculate slope and tri  

# for var in slope tri ; do 

# if [ $var = tri ]   ; then varn=TRI   ; fi  
# if [ $var = slope ] ; then varn=slope ; fi  

# gdaldem ${varn} -s 111120    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    $SCRATCH/equi7val/NA_equi_south_towgs84.tif     $SCRATCH/equi7val/NA_equi_south_towgs84_${var}.tif 
# gdaldem ${varn} -s 111120    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    $SCRATCH/equi7val/NA_equi_north_towgs84.tif     $SCRATCH/equi7val/NA_equi_north_towgs84_${var}.tif 

# gdaldem ${varn}    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND     $SCRATCH/equi7val/NA_equi_north.tif     $SCRATCH/equi7val/NA_equi_north_${var}.tif 
# gdaldem ${varn}    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND     $SCRATCH/equi7val/NA_equi_south.tif     $SCRATCH/equi7val/NA_equi_south_${var}.tif 

# gdalwarp -te $( getCorners4Gwarp  $SCRATCH/equi7val/NA_equi_north_${var}.tif )   -co COMPRESS=DEFLATE -co ZLEVEL=9  -t_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj -s_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 100 100   -r bilinear  -overwrite  $SCRATCH/equi7val/NA_equi_north_towgs84_${var}.tif   $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi.tif 

# gdalwarp -te $( getCorners4Gwarp  $SCRATCH/equi7val/NA_equi_south_${var}.tif )    -co COMPRESS=DEFLATE -co ZLEVEL=9  -t_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj -s_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 100 100   -r bilinear  -overwrite  $SCRATCH/equi7val/NA_equi_south_towgs84_${var}.tif   $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi.tif 

# gdal_translate  -srcwin 10  10  580 580      $SCRATCH/equi7val/NA_equi_north_${var}.tif      $SCRATCH/equi7val/NA_equi_north_${var}_crop.tif 
# gdal_translate  -srcwin 10  10  580 580      $SCRATCH/equi7val/NA_equi_south_${var}.tif      $SCRATCH/equi7val/NA_equi_south_${var}_crop.tif 

# gdal_translate  -srcwin 10  10  580 580      $SCRATCH/equi7val/NA_equi_north.tif      $SCRATCH/equi7val/NA_equi_north_crop.tif 
# gdal_translate  -srcwin 10  10  580 580      $SCRATCH/equi7val/NA_equi_south.tif      $SCRATCH/equi7val/NA_equi_south_crop.tif 


# gdal_translate -projwin $(getCorners4Gtranslate $SCRATCH/equi7val/NA_equi_north_${var}_crop.tif) $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi.tif $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi_crop.tif 
# gdal_translate -projwin $(getCorners4Gtranslate $SCRATCH/equi7val/NA_equi_south_${var}_crop.tif) $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi.tif $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi_crop.tif 

# gdal_translate -projwin $(getCorners4Gtranslate $SCRATCH/equi7val/NA_equi_north_${var}_crop.tif) $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi.tif $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi_crop.tif 
# gdal_translate -projwin $(getCorners4Gtranslate $SCRATCH/equi7val/NA_equi_south_${var}_crop.tif) $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi.tif $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi_crop.tif 

# gdal_translate -of XYZ  $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi_crop.tif  $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi_crop.txt 
# gdal_translate -of XYZ  $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi_crop.tif  $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi_crop.txt 

# gdal_translate -of XYZ  $SCRATCH/equi7val/NA_equi_north_${var}_crop.tif  $SCRATCH/equi7val/NA_equi_north_${var}_crop.txt 
# gdal_translate -of XYZ  $SCRATCH/equi7val/NA_equi_south_${var}_crop.tif  $SCRATCH/equi7val/NA_equi_south_${var}_crop.txt 

# paste <(awk '{ print $3  }'   $SCRATCH/equi7val/NA_equi_north_${var}_crop.txt )  <(awk '{ print $3  }'   $SCRATCH/equi7val/NA_equi_north_towgs84_${var}_toequi_crop.txt ) >   $SCRATCH/equi7val/NA_equi_wgs84_${var}_north.txt  
# paste <(awk '{ print $3  }'   $SCRATCH/equi7val/NA_equi_south_${var}_crop.txt )  <(awk '{ print $3  }'   $SCRATCH/equi7val/NA_equi_south_towgs84_${var}_toequi_crop.txt ) >   $SCRATCH/equi7val/NA_equi_wgs84_${var}_south.txt  

# done 

module load Apps/R/3.3.2-generic

#  World Geodetic System EPSG:4326 

R --vanilla --no-readline   -q  <<'EOF'

library(ggplot2)
library(rgdal)
library(raster)

north=read.table("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_wgs84_slope_north.txt")
colnames(north)[1] = "EQUI7"
colnames(north)[2] = "WGS"

x = north$EQUI7
y = north$WGS

lm = lm(  y ~ x) 
df <- data.frame(x = x, y = y, d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
p <- ggplot( data = df   , aes(x = x , y = y)) + 
    geom_point(aes(x, y, col = d), size = 0.4) +
    scale_color_identity() +
    geom_smooth(method = "lm", se = FALSE , color = "black" , formula=y ~ x , size=1.5)  +
    geom_abline(intercept = 0, slope = 1, color="red" , size=1.5 ) +
    labs(x = "EQUI7-DEM slope (degrees)")  + 
    labs(y = "WGS84-DEM slope (degrees)")  + 
    theme_bw()
ggsave("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_wgs84_slope_north.eps" ,   width=8, height=8)  

south=read.table("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_wgs84_slope_south.txt")
colnames(south)[1] = "EQUI7"
colnames(south)[2] = "WGS"

x = south$EQUI7
y = south$WGS

lm = lm(  y ~ x) 
df <- data.frame(x = x, y = y,
  d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
p <- ggplot( data = df   , aes(x = x , y = y)) + 
    geom_point(aes(x, y, col = d), size = 0.4) +
    scale_color_identity() +
    geom_smooth(method = "lm", se = FALSE , color = "black" , formula=y ~ x , size=1.5 )  +
    geom_abline(intercept = 0, slope = 1, color="red" , size=1.5 ) +
    labs(x = "EQUI7-DEM slope (degrees)")  + 
    labs(y = "WGS84-DEM slope (degrees)")  + 
    theme_bw()
ggsave("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_wgs84_slope_south.eps" ,   width=8, height=8)  

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)

NA_equi_south         = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_south.tif")
NA_equi_north         = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_north.tif")
NA_equi_north_towgs84 = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_north_towgs84.tif")
NA_equi_south_towgs84 = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_south_towgs84.tif")

NA_equi_south_slope         = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_south_slope.tif")
NA_equi_north_slope         = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_north_slope.tif")
NA_equi_north_towgs84_slope = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_north_towgs84_slope.tif")
NA_equi_south_towgs84_slope = raster("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/NA_equi_south_towgs84_slope.tif")

for ( tif  in c("NA_equi_south","NA_equi_north","NA_equi_north_towgs84","NA_equi_south_towgs84","NA_equi_south_slope","NA_equi_north_slope","NA_equi_north_towgs84_slope","NA_equi_south_towgs84_slope")) {
postscript(paste0("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/",tif,".eps") ,  paper="special" , width=8, height=7.15   )
par(oma=c(.1,.1,.1,.1) , mar=c(.1,.1,.1,.1) , xpd = NA)
raster = raster (paste0("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT/equi7val/",tif,".tif") )
plot(raster  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , legend=FALSE, ,  box=FALSE , axes=FALSE )

}

EOF



exit 


plot(raster, axis.args=list( at=at , labels=labels , line=-0.68, tck=0 , cex.axis=0.56   ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(-96.99 , 42.405, letter ,  font=2   ,   xpd=TRUE , cex=1.2 ) }



