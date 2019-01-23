

# DIR=/project/fas/sbsc/ga254/dataproces/NP/pearson

# for file in  $DIR/soil_avg_02_*_season_*_CONUS_corr_mask.tif $DIR/lu_9_*_season_*_CONUS_corr_mask.tif $DIR/lu_7_*_season_*_CONUS_corr_mask.tif ; do 
#      pkstat  -nbin 1000  -src_min -1 -src_max 1    -hist -i $file | awk '{ if ($1<-0.5 ||  $1>+0.5) print   }'    >  $DIR/$(basename   $file .tif)_hist.txt 
# done 


module load Apps/R/3.3.2-generic

R --vanilla --no-readline   -q  <<'EOF'
library(plotrix)
library(zoo)

rm(list = ls())

DIR="/project/fas/sbsc/ga254/dataproces/NP/pearson/"
luTN1 =  read.table(paste0(DIR,"lu_9_TN_season_1_CONUS_corr_mask_hist.txt")) # winter 
luTN2 =  read.table(paste0(DIR,"lu_9_TN_season_2_CONUS_corr_mask_hist.txt")) # spring 
luTN3 =  read.table(paste0(DIR,"lu_9_TN_season_3_CONUS_corr_mask_hist.txt")) # Summer 
luTN4 =  read.table(paste0(DIR,"lu_9_TN_season_4_CONUS_corr_mask_hist.txt")) # Fall

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_9_TN_pearson_hist.pdf",width=6 , height=6 )

par(bty="n") # deleting the box

# rollmean(luTN1$V2[1:200],21) 

for ( SEASON in c("luTN1", "luTN2", "luTN3", "luTN4") ) {


D  =   c( rep(min(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10) ,
                             rollmean(get(SEASON)$V2[1:250],21 , align="center"  )  ,
            rep(max(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10)      ,
            rep(max(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )),10)    ,
                        rollmean(get(SEASON)$V2[251:500],21 , align ="center"  )    ,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*1,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*2,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*3,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*4,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*5,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*6,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*7,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*8,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*9,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*10 )


S = get(SEASON)
S$D = D

assign(paste0(SEASON) , S  )

SEASONmw=rbind(get(SEASON)[1:200,],get(SEASON)[301:500,])

assign(paste0(SEASON,"mw") , SEASONmw  )

}

str(luTN1)
ymax=max(luTN1mw$D, luTN2mw$D,luTN3mw$D,luTN4mw$D)

gap.plot(luTN3mw$V1,luTN3mw$D, ylim=c(0,1600), gap=c(-0.6,+0.6), gap.axis="x", lch=16 , lwd=3 , lty=2 , type="l" , col="black",  xtics=c(-1,+0.6), xticlab=c(-1,+0.6) , xlab="Pearson coefficient" , ylab="Number of pixels" ) # summer 

gap.plot(luTN2mw$V1,luTN2mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=18, lty=1 , lwd=3 , type="l" , col="black",   xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # spring
gap.plot(luTN1mw$V1,luTN1mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=19, lwd=3 ,  lty=3 ,type="l" , col="black", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # winter
gap.plot(luTN4mw$V1,luTN4mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=17, lwd=3 ,lty=4 ,type="l" , col="black", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # fall

abline(v=seq(-0.6), col="black")  # hiding vertical lines


dev.off() 
EOF

# TP 

R --vanilla --no-readline   -q  <<'EOF'
library(plotrix)
library(zoo)

rm(list = ls())

DIR="/project/fas/sbsc/ga254/dataproces/NP/pearson/"
luTP1 =  read.table(paste0(DIR,"lu_9_TP_season_1_CONUS_corr_mask_hist.txt")) # winter 
luTP2 =  read.table(paste0(DIR,"lu_9_TP_season_2_CONUS_corr_mask_hist.txt")) # spring 
luTP3 =  read.table(paste0(DIR,"lu_9_TP_season_3_CONUS_corr_mask_hist.txt")) # Summer 
luTP4 =  read.table(paste0(DIR,"lu_9_TP_season_4_CONUS_corr_mask_hist.txt")) # Fall

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_9_TP_pearson_hist.pdf",width=6 , height=6 )

par(bty="n") # deleting the box

# rollmean(luTP1$V2[1:200],21) 

for ( SEASON in c("luTP1", "luTP2", "luTP3", "luTP4") ) {


D  =   c( rep(min(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10) ,
                             rollmean(get(SEASON)$V2[1:250],21 , align="center"  )  ,
            rep(max(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10)      ,
            rep(max(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )),10)    ,
                        rollmean(get(SEASON)$V2[251:500],21 , align ="center"  )    ,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*1,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*2,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*3,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*4,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*5,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*6,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*7,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*8,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*9,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*10 )


S = get(SEASON)
S$D = D

assign(paste0(SEASON) , S  )

SEASONmw=rbind(get(SEASON)[1:200,],get(SEASON)[301:500,])

assign(paste0(SEASON,"mw") , SEASONmw  )

}

str(luTP1)
ymax=max(luTP1mw$D, luTP2mw$D,luTP3mw$D,luTP4mw$D)

gap.plot(luTP3mw$V1,luTP3mw$D, ylim=c(0,1600), gap=c(-0.6,+0.6), gap.axis="x", lch=16 , lwd=3 , lty=2 , type="l" , col="black",  xtics=c(-1,+0.6), xticlab=c(-1,+0.6) , xlab="Pearson coefficient" , ylab="Number of pixels" ) # summer 

gap.plot(luTP2mw$V1,luTP2mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=18, lty=1 , lwd=3 , type="l" , col="black",   xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # spring
gap.plot(luTP1mw$V1,luTP1mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=19, lwd=3 ,  lty=3 ,type="l" , col="black", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # winter
gap.plot(luTP4mw$V1,luTP4mw$D, gap=c(-0.6,+0.6), gap.axis="x", lch=17, lwd=3 ,lty=4 ,type="l" , col="black", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1), add=TRUE) # fall

abline(v=seq(-0.6), col="black")  # hiding vertical lines

dev.off() 
EOF


########################################
#########################################
############## lu 7  ########################


R --vanilla --no-readline   -q  <<'EOF'
library(plotrix)
library(zoo)

rm(list = ls())

DIR="/project/fas/sbsc/ga254/dataproces/NP/pearson/"
luTN1 =  read.table(paste0(DIR,"lu_7_TN_season_1_CONUS_corr_mask_hist.txt")) # winter 
luTN2 =  read.table(paste0(DIR,"lu_7_TN_season_2_CONUS_corr_mask_hist.txt")) # spring 
luTN3 =  read.table(paste0(DIR,"lu_7_TN_season_3_CONUS_corr_mask_hist.txt")) # Summer 
luTN4 =  read.table(paste0(DIR,"lu_7_TN_season_4_CONUS_corr_mask_hist.txt")) # Fall

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_7_TN_pearson_hist.pdf",width=6 , height=6 )

par(bty="n") # deleting the box

# rollmean(luTN1$V2[1:200],21) 

for ( SEASON in c("luTN1", "luTN2", "luTN3", "luTN4") ) {


D  =   c( rep(min(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10) ,
                             rollmean(get(SEASON)$V2[1:250],21 , align="center"  )  ,
            rep(max(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10)      ,
            rep(max(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )),10)    ,
                        rollmean(get(SEASON)$V2[251:500],21 , align ="center"  )    ,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*1,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*2,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*3,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*4,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*5,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*6,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*7,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*8,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*9,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*10 )


S = get(SEASON)
S$D = D

assign(paste0(SEASON) , S  )

SEASONmw=rbind(get(SEASON)[1:200,],get(SEASON)[301:500,])

assign(paste0(SEASON,"mw") , SEASONmw  )

}

str(luTN1)
ymax=max(luTN1mw$D, luTN2mw$D,luTN3mw$D,luTN4mw$D)

plot(luTN3mw$V1,luTN3mw$D, ylim=c(0,6000), lch=16 , lwd=3 , lty=2 , type="l" , col="black", xlab="Pearson coefficient" , ylab="Number of pixels" ) # summer 

lines(luTN2mw$V1,luTN2mw$D,  lch=18, lty=1 , lwd=3 ,type="l" , col="black",  add=TRUE) # spring
lines(luTN1mw$V1,luTN1mw$D,  lch=19, lwd=3 , lty=3 ,type="l" , col="black",  add=TRUE) # winter
lines(luTN4mw$V1,luTN4mw$D,  lch=17, lwd=3 , lty=4 ,type="l" , col="black",  add=TRUE) # fall

dev.off() 
EOF

# TP 

R --vanilla --no-readline   -q  <<'EOF'
library(plotrix)
library(zoo)

rm(list = ls())

DIR="/project/fas/sbsc/ga254/dataproces/NP/pearson/"
luTP1 =  read.table(paste0(DIR,"lu_7_TP_season_1_CONUS_corr_mask_hist.txt")) # winter 
luTP2 =  read.table(paste0(DIR,"lu_7_TP_season_2_CONUS_corr_mask_hist.txt")) # spring 
luTP3 =  read.table(paste0(DIR,"lu_7_TP_season_3_CONUS_corr_mask_hist.txt")) # Summer 
luTP4 =  read.table(paste0(DIR,"lu_7_TP_season_4_CONUS_corr_mask_hist.txt")) # Fall

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_7_TP_pearson_hist.pdf",width=6 , height=6 )

par(bty="n") # deleting the box

# rollmean(luTP1$V2[1:200],21) 

for ( SEASON in c("luTP1", "luTP2", "luTP3", "luTP4") ) {


D  =   c( rep(min(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10) ,
                             rollmean(get(SEASON)$V2[1:250],21 , align="center"  )  ,
            rep(max(rollmean(get(SEASON)$V2[1:250],21 , align="center"  )),10)      ,
            rep(max(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )),10)    ,
                        rollmean(get(SEASON)$V2[251:500],21 , align ="center"  )    ,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*1,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*2,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*3,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*4,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*5,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*6,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*7,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*8,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*9,
            min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)$V2[251:500],21 , align="center"  ))/10)*10 )


S = get(SEASON)
S$D = D

assign(paste0(SEASON) , S  )

SEASONmw=rbind(get(SEASON)[1:200,],get(SEASON)[301:500,])

assign(paste0(SEASON,"mw") , SEASONmw  )

}

str(luTP1)
ymax=max(luTP1mw$D, luTP2mw$D,luTP3mw$D,luTP4mw$D)

plot(luTP3mw$V1,luTP3mw$D, ylim=c(0,3000), lch=16 , lwd=3 , lty=2 , type="l" , col="black", xlab="Pearson coefficient" , ylab="Number of pixels" ) # summer 

lines(luTP2mw$V1,luTP2mw$D,  lch=18, lty=1 , lwd=3 ,type="l" , col="black",  add=TRUE) # spring
lines(luTP1mw$V1,luTP1mw$D,  lch=19, lwd=3 , lty=3 ,type="l" , col="black",  add=TRUE) # winter
lines(luTP4mw$V1,luTP4mw$D,  lch=17, lwd=3 , lty=4 ,type="l" , col="black",  add=TRUE) # fall

dev.off() 
EOF





