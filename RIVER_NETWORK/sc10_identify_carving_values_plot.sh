# cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp

# module load Apps/R/3.3.2-generic 

UNIT4000_001 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_001.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4000_010 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_010.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4000_100 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_100.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4000_200 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_200.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4000_300 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_300.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4000_400 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4000_400.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )

UNIT3753_001 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_001.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT3753_010 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_010.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT3753_100 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_100.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT3753_200 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_200.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT3753_300 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_300.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT3753_400 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT3753_400.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )

UNIT4001_001 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_001.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4001_010 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_010.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4001_100 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_100.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4001_200 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_200.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4001_300 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_300.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
UNIT4001_400 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/UNIT4001_400.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )

CALIBRATION_001 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_001.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
CALIBRATION_010 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_010.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
CALIBRATION_100 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_100.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
CALIBRATION_200 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_200.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
CALIBRATION_300 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_300.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )
CALIBRATION_400 = read.delim("/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/tmp/CALIBRATION_400.txt", sep=" " , header=FALSE , col.names=c("DIM","NPIXEL") )



postscript("/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/plot/calibration.ps" , paper="special" ,  height=5  , width=7.5, horizo=F  )	
par ( cex.lab=0.6 , cex=0.6 , cex.axis=0.6  , mfrow=c(2,2) )

plot   (UNIT4000_001 ,  ylim=c(3800000,5000000) ,pch=20 , cex=.6 ,col="red"  , xlab="Carving depth" , ylab="Number of Pixels" , main="South America" , cex.main=0.8)
points (UNIT4000_010 ,  ylim=c(3800000,5500000) ,pch=22 , cex=.6 ,col="blue"    )
points (UNIT4000_100 ,  ylim=c(3800000,5500000) ,pch=17 , cex=.6 ,col="black"   )
points (UNIT4000_200 ,  ylim=c(3800000,5500000) ,pch=18 , cex=.6 ,col="orange"  )
points (UNIT4000_300 ,  ylim=c(3800000,5500000) ,pch=15 , cex=.6 ,col="yellow"  )
points (UNIT4000_400 ,  ylim=c(3800000,5500000) ,pch="*"  , cex=.6 ,col="green"   )

# plot   (UNIT4001_001 ,  ylim=c(3800000,5000000) ,pch=20 ,cex=.6 , col="red"  , xlab="Carving depth" , ylab="Number of Pixels"  , main="Africa" , cex.main=0.8 )
# points (UNIT4001_010 ,                          ,pch=22 ,cex=.6 , col="blue"    )
# points (UNIT4001_100 ,                          ,pch=17 ,cex=.6 , col="black"   )
# points (UNIT4001_200 ,                          ,pch=18 ,cex=.6 , col="orange"  )
# points (UNIT4001_300 ,                          ,pch=15 ,cex=.6 , col="yellow"  )
# points (UNIT4001_400 ,                          ,pch="*" ,cex=.6 , col="green"   )

plot   (UNIT3753_001 ,  ylim=c(19000000,27000000) ,pch=20 ,cex=.6 , col="red"  , xlab="Carving depth" , ylab="Number of Pixels"  , main="North America" , cex.main=0.8)
points (UNIT3753_010 ,                            ,pch=22 ,cex=.6 , col="blue"    )
points (UNIT3753_100 ,                             pch=17 ,cex=.6 , col="black"   )
points (UNIT3753_200 ,                            ,pch=18 ,cex=.6 , col="orange"  )
points (UNIT3753_300 ,                            ,pch=15 ,cex=.6 , col="yellow"  )
points (UNIT3753_400 ,                            ,pch="*" ,cex=.6 , col="green"   )

plot   (CALIBRATION_001 , ylim=c(23000000,32000000) ,pch=20 ,cex=.6 , col="red"  , xlab="Carving depth" , ylab="Number of Pixels" , main="Over all" , cex.main=0.8 )
points (CALIBRATION_010 ,                           ,pch=22 ,cex=.6 , col="blue"    )
points (CALIBRATION_100 ,                           ,pch=17 ,cex=.6 , col="black"   )
points (CALIBRATION_200 ,                           ,pch=18 ,cex=.6 , col="orange"  )
points (CALIBRATION_300 ,                           ,pch=15 ,cex=.6 , col="yellow"  )
points (CALIBRATION_400 ,                           ,pch="*" ,cex=.6 , col="green"   )

dev.off()




set yrange [3800000:5500000]   ; plot  'UNIT4000_001.txt' ,   'UNIT4000_010.txt' ,  'UNIT4000_100.txt' ,  'UNIT4000_200.txt' ,  'UNIT4000_300.txt' ,  'UNIT4000_400.txt' 
set yrange [18000000:32000000] ; plot  'UNIT3753_001.txt' ,   'UNIT3753_010.txt' ,  'UNIT3753_100.txt' ,  'UNIT3753_200.txt' ,  'UNIT3753_300.txt' ,  'UNIT3753_400.txt'
set yrange [23000000:35000000] ; plot  'CALIBRATION_001.txt' ,   'CALIBRATION_010.txt' ,  'CALIBRATION_100.txt' ,  'CALIBRATION_200.txt' ,  'CALIBRATION_300.txt' ,  'CALIBRATION_400.txt'

