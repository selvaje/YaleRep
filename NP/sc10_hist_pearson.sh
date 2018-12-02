

DIR=/project/fas/sbsc/ga254/dataproces/NP/pearson

# for file in $DIR/lu_9_TN_season_*_CONUS_corr_mask.tif $DIR/lu_9_TP_season_*_CONUS_corr_mask.tif ; do 
#     pkstat  -nbin 1000  -src_min -1 -src_max 1    -hist -i $file | awk '{ if ($1<-0.5 ||  $1>+0.5) print   }'    >  $DIR/$(basename   $file .tif)_hist.txt 
# done 


module load Apps/R/3.3.2-generic

R --vanilla --no-readline   -q  <<EOF
library(plotrix)
library(zoo)


DIR="/project/fas/sbsc/ga254/dataproces/NP/pearson/"
luTN1 =  read.table(paste0(DIR,"lu_9_TN_season_1_CONUS_corr_mask_hist.txt"))
luTN2 =  read.table(paste0(DIR,"lu_9_TN_season_2_CONUS_corr_mask_hist.txt"))
luTN3 =  read.table(paste0(DIR,"lu_9_TN_season_3_CONUS_corr_mask_hist.txt"))
luTN4 =  read.table(paste0(DIR,"lu_9_TN_season_4_CONUS_corr_mask_hist.txt"))

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/figure/pdf/lu_9_TN_pearson_hist.pdf",width=6 , height=6 )

par(bty="n") # deleting the box



#  rollmean(luTN1\$V2[1:200],21) 

for ( SEASON in c("luTN1", "luTN2", "luTN3", "luTN4") ) { 


get(SEASON)\$D=c( rep(min(rollmean(get(SEASON)\$V2[1:250],21 , align="center"  )),10) ,  
                        rollmean(get(SEASON)\$V2[1:250],21 , align="center"  )  , 
            rep(max(rollmean(get(SEASON)\$V2[1:250],21 , align="center"  )),10)  ,  
            rep(max(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )),10) ,   
                        rollmean(get(SEASON)\$V2[251:500],21 , align ="center"  ), 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*1, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*2, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*3, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*4, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*5, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*6, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*7, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*8, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*9, 
            min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  )) -       ( min(rollmean(get(SEASON)\$V2[251:500],21 , align="center"  ))/10)*10 

SEASONmw=rbind(get(SEASON)[1:200,],get(SEASON)[301:500,])

assign(paste0(SEASON,"mw") , SEASONmw  )

}

str(luTN1)
ymax=max(luTN1\$V2, luTN2\$V2,luTN2\$V2,luTN2\$V2)


# plot(luTN1mw\$V1,luTN1mw\$D , type='l')
# lines(luTN1mw\$V1,luTN1mw\$V2 , type='l', col="red")


gap.plot(luTN1mw\$V1,luTN1mw\$D , gap=c(-0.6,+0.6)  , gap.axis="x", pch=16, type="l" , col="blue",  xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1) , xlab="Pearson coefficient" , ylab="Number of pixels" , ylim=c(0,ymax) )

gap.plot(luTN1mw\$V1,luTN1mw\$V2 , gap=c(-0.6,+0.6)  , gap.axis="x", pch=16, type="l" , col="red",  xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1) , add=TRUE)

gap.plot(luTN3\$V1,luTN3\$V2 , gap=c(-0.6,+0.6)  , gap.axis="x", pch=16, type="l" , col="green", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1) , add=TRUE)
gap.plot(luTN4\$V1,luTN4\$V2 , gap=c(-0.6,+0.6)  , gap.axis="x", pch=16, type="l" , col="black", xtics=c(-1:-0.6,+0.6:1), xticlab=c(-1:-0.6,+0.6:1) , add=TRUE)


# abline(v=seq(-0.6), col="white")  # hiding vertical lines
# axis.break(1,2,style="slash")               # plotting slashes for breakpoints

dev.off()
 
EOF


