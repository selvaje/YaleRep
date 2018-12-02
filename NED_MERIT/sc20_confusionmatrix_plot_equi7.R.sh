# https://ragrawal.wordpress.com/2011/05/16/visualizing-confusion-matrix-in-r/
cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces


tile=NA_078_036

export tile 

 gdal_translate -projwin     $( getCorners4Gtranslate $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif )     NED/forms/tiles/${tile}.tif /tmp/${tile}_tmp.tif 
 gdal_edit.py    -a_ullr     $( getCorners4Gtranslate $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif )    /tmp/${tile}_tmp.tif 

 gdal_translate -srcwin 0 0 3000 3000 /tmp/${tile}_tmp.tif   /tmp/${tile}.tif 
 gdal_translate -srcwin 0 0 3000 3000 $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif    /dev/shm/${tile}.tif 

# pkdiff  -nodata 0  -cm  -ref   /tmp/$tile.tif  -i  /dev/shm/${tile}.tif    -cmo NED_MERIT/confusion/${tile}.txt

# pkstat  -nodata 0  -hist2d -i   /tmp/$tile.tif  -i /dev/shm/${tile}.tif |  awk '{ if (NF==3) print   }'   > NED_MERIT/confusion/${tile}_hist2d.txt  # confusion 
# pkstat  -nodata 0  -hist   -i   /tmp/$tile.tif                                                            > NED_MERIT/confusion/${tile}_hist.txt    # actual 


 gdal_translate -of XYZ   /tmp/${tile}.tif       /tmp/geom_100M_NED_NA_078_036.txt 
 gdal_translate -of XYZ   /dev/shm/${tile}.tif  /dev/shm/geom_100M_MERIT_NA_078_036.txt 

paste -d " "  <( awk '{  print $3  }'   /tmp/geom_100M_NED_NA_078_036.txt  )   <(  awk '{ print $3  }'    /dev/shm/geom_100M_MERIT_NA_078_036.txt ) >  /dev/shm/geom_NED_MERIT.txt 

module load Apps/R/3.3.2-generic

R --vanilla --no-readline -q  << 'EOF'
library (ggplot2)
library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)



geom_N = raster ("/tmp/NA_078_036.tif")
geom_M = raster ("/dev/shm/NA_078_036.tif")

geom_N

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/geomorphon_plots.pdf" , width=11.5, height=10   )

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,2,4) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(2,2) ,  xpd=NA  , bty= "n"   )  # bty= "n" remove the box

max=10.5 ; min=0.5 ; at=seq (1 , 10  , 1) ;  labels=c("flat","summit","ridge","shoulder","spur","slope","hollow","footslope","valley","depression")

des="MERIT Geomorphic classes" 
plot(geom_M , yaxp=c(3900000,4200000,1) , xaxp=c(7800000,8100000,1), cex.axis=1.2 ,   ,  col=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))(10),   xlab="", ylab="", main=des, legend=FALSE, cex.main=1, font.main=2 )
plot(geom_N, axis.args=list(at=at ,  labels=labels   , line=-0.68, tck=1 , cex.axis=1.2 ,  lwd = 0  ), smallplot=c(0.85,0.89, 0.1,0.8), zlim=c( 1 , 10 ) , legend.only=TRUE ,  legend.width=1, legend.shrink=2 , 
col=colorRampPalette(c("blue","green","yellow","orange" , "red", "brown", "black" ))(10)  )


des="3DEP-1 Geomorphic classes" 
plot(geom_N   , col=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))(10) , yaxt="n"  ,  xaxt="n" , xlab=""  , ylab="" , main=des   , legend=FALSE   , cex.main=1 , font.main=2 )

# extent   : 7800000,  8100000 , 3900000 , 4200000  (xmin, xmax, ymin, ymax) 
e = extent ( 7800000 , 7810000 , 3900000 , 3910000 ) 
geom_M = crop   (geom_M , e)
geom_N = crop   (geom_N , e)

plot(geom_M   , col=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))(10) , yaxt="n"  ,  xaxt="n" , xlab=""  , ylab=""    , legend=FALSE   , cex.main=1 , font.main=2 )
plot(geom_N   , col=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))(10) , yaxt="n"  ,  xaxt="n" , xlab=""  , ylab=""    , legend=FALSE   , cex.main=1 , font.main=2 )

geom_N

dev.off()

EOF

exit 



R --vanilla --no-readline -q  << 'EOF'
library (ggplot2)


tile  <- Sys.getenv(c('tile'))

class=c("flat","peak","ridge","shoulder","spur","slope","hollow","footslope","valley","pit" )

actual     = read.table(paste0("NED_MERIT/confusion/",tile,"_hist.txt"))
names(actual) = c("Actual","ActualFreq")

actual$actual_class  =  class 

confusion =  read.table(paste0("NED_MERIT/confusion/",tile,"_hist2d.txt"))
names(confusion) = c("Actual","Predicted","Freq")

confusion$predicted_class = c(class)

#calculate percentage of test cases based on actual frequency
confusion = merge(confusion, actual, by=c("Actual"))
confusion$Percent = confusion$Freq/confusion$ActualFreq*100

pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/confusion_matrix_",tile,".pdf") , width=9.7, height=8   )
 
#render plot
# we use three different layers
# first we draw tiles and fill color based on percentage of test cases

tile <- ggplot() +
geom_tile(aes(x=actual_class, y=predicted_class,fill=Percent), data=confusion, color="black", size=0.1) +
labs(x="3DEP-1 geomorphologic forms", y="MERIT geomorphologic forms\n" ) + 
theme(plot.margin = unit(c(1,1,1,1), "cm")) +
theme(axis.text.y=element_text(size=18 , color="black" )) +
theme(axis.text.x=element_text( angle = 45 , hjust=1  , size=18 , color="black" )) +
theme(axis.title.x=element_text(vjust=-4 , size=20)) +
theme(axis.title.y=element_text(size=20)) +
theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank()) +
theme( legend.title=element_text(size=18), legend.text=element_text(size=16))

tile = tile + 
geom_text(aes(x=Actual,y=Predicted, label=sprintf("%.1f", Percent)),data=confusion, size=5, colour="black") +
scale_fill_gradient(low="grey",high="red")

# lastly we draw diagonal tiles. We use alpha = 0 so as not to hide previous layers but use size=0.3 to highlight border
tile = tile + 
geom_tile(aes(x=Actual,y=Predicted),data=subset(confusion, as.character(Actual)==as.character(Predicted)), color="blue",size=0.6, fill="black", alpha=0) 
 
#render
tile

dev.off()

EOF



