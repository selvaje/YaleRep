



module load Apps/R/3.3.2-generic

#######################################
#########################################
############## lu 7  ########################


R --vanilla --no-readline   -q  <<'EOF'
library(plotrix)
library(zoo)

rm(list = ls())

DIR="/project/fas/sbsc/ga254/dataproces/NP/ratioNP_dist_predictors/"
luTDNTDP1   =  read.table(paste0(DIR,"lu_7_usa_TDN_TDP_ratio_1_class_ABCDF.hist")) # winter 
luTDNTDP2   =  read.table(paste0(DIR,"lu_7_usa_TDN_TDP_ratio_2_class_ABCDF.hist")) # spring
luTDNTDP3   =  read.table(paste0(DIR,"lu_7_usa_TDN_TDP_ratio_3_class_ABCDF.hist")) # summer  
luTDNTDP4   =  read.table(paste0(DIR,"lu_7_usa_TDN_TDP_ratio_4_class_ABCDF.hist")) # fall

luTNTP1   =  read.table(paste0(DIR,"lu_7_usa_TN_TP_ratio_1_class_ABCDF.hist")) # winter 
luTNTP2   =  read.table(paste0(DIR,"lu_7_usa_TN_TP_ratio_2_class_ABCDF.hist")) # spring
luTNTP3   =  read.table(paste0(DIR,"lu_7_usa_TN_TP_ratio_3_class_ABCDF.hist")) # summer
luTNTP4   =  read.table(paste0(DIR,"lu_7_usa_TN_TP_ratio_4_class_ABCDF.hist")) # fall

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_7_TNTP_ratio_1_hist.pdf",width=6 , height=6 )


plot(rollmean(luTDNTDP1$V6,11), type="l" , ylim=c( 0 , max( rollmean(luTDNTDP1$V6,11 )))) ; 
lines( rollmean(luTDNTDP1$V5,11)  ,   lty=2,  ,type="l" , col="black")
lines( rollmean(luTDNTDP1$V4,11)  ,   lty=3,  ,type="l" , col="black")
lines( rollmean(luTDNTDP1$V3,11)  ,   lty=4,  ,type="l" , col="black")
lines( rollmean(luTDNTDP1$V2,11)  ,   lty=5,  ,type="l" , col="black")



plot(rollmean(luTNTP1$V6,11), type="l" , ylim=c( 0 , max( rollmean(luTNTP1$V6,11 )))) ; 
lines( rollmean(luTNTP1$V5,11)  ,   lty=2,  ,type="l" , col="black")
lines( rollmean(luTNTP1$V4,11)  ,   lty=3,  ,type="l" , col="black")
lines( rollmean(luTNTP1$V3,11)  ,   lty=4,  ,type="l" , col="black")
lines( rollmean(luTNTP1$V2,11)  ,   lty=5,  ,type="l" , col="black")

###############33


plot(rollmean(luTNTP1$V6,11), type="l", ylim=c(0.1, max( rollmean(luTNTP1$V6,11 ))), log='y' , lty=1 , xlab=("Cultivated and Managed Vegetation (%)"), 
ylab=("Number of pixels (log scale)") , main="Cultivated and Managed Vegetation (%) pdf for TN/TP winter classes"   )  ; 
lines( rollmean(luTNTP1$V5,11)  ,   lty=2,  ,type="l" , col="red")
lines( rollmean(luTNTP1$V4,11)  ,   lty=3,  ,type="l" , col="green")
lines( rollmean(luTNTP1$V3,11)  ,   lty=4,  ,type="l" , col="black")
lines( rollmean(luTNTP1$V2,11)  ,   lty=5,  ,type="l" , col="blue")
legend(41, 1,legend=c("> 25 heavily P limited","18-25 moderately P limited","14-18 N and P balanced","11-14 moderately N limited","< 11 heaviliy N"), 
col=c("black","red","green","black","blue"), lty=1:5, cex=0.8)

###############


plot(rollmean(luTDNTDP1$V6,11), type="l", ylim=c(0.1, max( rollmean(luTDNTDP1$V6,11 ))), log='y' , lty=1 , xlab=("Cultivated and Managed Vegetation (%)"), ylab=("Number of pixels (log scale)") , main="TDN/TDP winter" )  ; 
lines( rollmean(luTDNTDP1$V5,11)  ,   lty=2,  ,type="l" , col="red")
lines( rollmean(luTDNTDP1$V4,11)  ,   lty=3,  ,type="l" , col="green")
lines( rollmean(luTDNTDP1$V3,11)  ,   lty=4,  ,type="l" , col="black")
lines( rollmean(luTDNTDP1$V2,11)  ,   lty=5,  ,type="l" , col="blue")
legend(41, 1,legend=c("> 25 heavily P limited","18-25 moderately P limited","14-18 N and P balanced","11-14 moderately N limited","< 11 heaviliy N"), 
col=c("black","red","green","black","blue"), lty=1:5, cex=0.8)





                                                                                                                                            




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

