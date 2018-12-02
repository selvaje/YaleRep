DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

# Y=11562        # 14028
# for X in $(seq 14028 14103 ); do 
#     echo  $(gdallocationinfo  -valonly $DIR/output/stream_unit_small/occurrence_250m.tif  $X $Y | awk '{ print $1/100  }' ) \
#           $(gdallocationinfo  -valonly $DIR/output/stream_unit_small/be75_grd_LandEnlarge.tif $X $Y) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log001_DIM50_w5.tif  $X $Y ) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log010_DIM50_w5.tif  $X $Y ) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log100_DIM50_w5.tif  $X $Y ) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log200_DIM50_w5.tif  $X $Y ) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log300_DIM50_w5.tif  $X $Y ) \
#           $( gdallocationinfo -valonly $DIR/dem_unit/be75_grd_LandEnlarge_GLOBE_cond3753_log400_DIM50_w5.tif  $X $Y ) 
# done   >  $DIR/dem_unit/dem_profile.txt

 
# # 300 and 400 problem 

module load Apps/R/3.1.1-generic
# # module load Rpkgs/RGDAL/0.9-3
# # module load Rpkgs/RASTER/2.5.

# R  --vanilla  <<EOF

# # library(raster)
# # tif = raster("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/occurrence_250m_profile.tif")

# table = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.txt")
# postscript("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.ps" , paper="special" , horizo=F , width=8, height=4  )

# # par (oma=c(4,1,6,1) , mar=c(1,4,0,0) , cex.lab=1 , cex=1 , cex.axis=1 , mfcol=c(1,2) 

# x=  seq( -95.7750000 , -96.7750000  ,  by=-0.002083333333333  ) [1:76]

# plot(x , table\$V2  , type="l"  ,  ylim=c(min(table[-1]),max(table[-1])) , ylab=("Elevation (m)") , xlab=("") )
# lines(x , table\$V3  , type="l" , col='red' , lty=10    )
# lines(x , table\$V4  , type="l"  , col='blue' ,  lty=8   )
# lines(x , table\$V5  , type="l"  , col='yellow' , lty=7   )
# lines(x , table\$V6  , type="l"  , col='green' , lty=6   )
# lines(x , table\$V7  , type="l"  , col='magenta', lty=5   )
# lines(x , table\$V8  , type="l"  , col='brown'  , lty=4  )
# # lines(x , table\$V9  , type="l"  , col='green'  , lty=3   )
# # lines(x , table\$V10 , type="l"  , col='grey' , lty=2    )
# lines(x, table\$V2  , type="l"  , col='black'  )

# segments( -95.935 , 150,  -95.932 , 150,   col='black'          ) # ;  mtext ("DEM",  at=c(-96.93, 130) , col = "black" ,  cex=0.6   , line=-2   ) 
# segments( -95.935 , 145,  -95.932 , 145,   col='red' , lty=10   ) 
# segments( -95.935 , 140,  -95.932 , 140,   col='blue' ,  lty=8  ) 
# segments( -95.935 , 135,  -95.932 , 135,   col='yellow' , lty=7 )
# segments( -95.935 , 130,  -95.932 , 130,   col='green' , lty=6 ) 
# segments( -95.935 , 125,  -95.932 , 125,   col='magenta', lty=5 ) 
# segments( -95.935 , 120,  -95.932 , 120,   col='brown'  , lty=4 ) 


# mtext ( "Longitude " , side=1.2 , cex=0.6 , line=1 , outer=TRUE , at=c(-95) , col = "black" ) 

# dev.off()

# EOF

# convert -flatten -density 300  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.ps  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.png
# ps2epsi /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.ps /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.eps

# evince /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/dem_profile.eps 

R  --vanilla  <<EOF

table001 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_001_s.txt")
table010 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_010_s.txt")
table100 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_100_s.txt")
table200 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_200_s.txt")
table300 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_300_s.txt")
table400 = read.table("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_400_s.txt")

postscript("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.ps" , paper="special" , horizo=F , width=6, height=8  )

par(oma=c(2,3,3,3) , mar=c(5,5,0,0))

plot ( table001\$V1 , table001\$V2  , type="l"  , col='red'   , lty=10  ,   ylim=c( 19700000 ,   26613000)  , xlab=c("Carving depth (m)")  , ylab=c("Number of pixels")  , lwd=3 , cex.lab=2, cex.axis=2  )
lines( table010\$V1 , table010\$V2  , type="l"  , col='blue' ,  lty=8  ,lwd=3 )
lines( table200\$V1 , table200\$V2  , type="l"  , col='yellow' , lty=7 ,lwd=4  )
lines( table100\$V1 , table100\$V2  , type="l"  , col='green' , lty=6  ,lwd=3  )
lines( table300\$V1 , table300\$V2  , type="l"  , col='magenta', lty=5 ,lwd=3  )
lines( table400\$V1 , table400\$V2  , type="l"  , col='brown'  , lty=4 ,lwd=3 )

dev.off()

EOF

convert -flatten -density 300  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.ps  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.png
ps2epsi /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.ps /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.eps

evince /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/calibration.eps 



