#/usr/local/bin/bash

forms=(T TD)

export dirIn=
export dirOut=

for form in ${forms[@]}
do
   echo ${form}
done | xargs -n 1 -P 4 bash -c $'
form=$1
export nutN=${form}N
export nutP=${form}P
export legpre=map_pred_CONUS_bivar_leg_${form}_N-P_man    

R --vanilla --no-readline -q <<EOF

library(classInt)
library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
library(sp)

dirIn <- Sys.getenv(c(\'dirIn\'))
dirOut <- Sys.getenv(c(\'dirOut\'))				 
nutN <- Sys.getenv(c(\'nutN\'))
nutP <- Sys.getenv(c(\'nutP\'))
legpre <- Sys.getenv(c(\'legpre\'))


bnplot <- c()
tcplot <- c()
for (i in (1:4)){
figmean <- paste0("map_pred_CONUS_mean_",nutN,"_",i,"_10k_clump_filled.tif")
figstd <- paste0("map_pred_CONUS_mean_",nutP,"_",i,"_10k_clump_filled.tif")
meanraster <- raster(paste0(dirIn,figmean))
sdraster <- raster(paste0(dirIn,figstd))
tempy <- getValues(meanraster) # y values
tempx <- getValues(sdraster) # x values
bnplot <- c(bnplot,tempy)
tcplot <- c(tcplot,tempx)
}

# look at the quantiles to set the break values for the plot
nquantiles=10 # set number of quantiles for the plot matrix
plotbrksbn<-quantile(bnplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #y-label values
plotbrkstc<-quantile(tcplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #x-label values

plotbrksbn
plotbrkstc

tickspotsx<-seq(0,1,1/nquantiles) #x-label positions
tickspotsy<-seq(0,1,1/nquantiles) #y-label positions

tickspotsx
tickspotsy

# col matrix function but with custom x and y labels
colmatxy<-function(outleg=paste0(dirOut,legpre,".ps"),nquantiles=nquantiles, upperleft=rgb(0,150,235, maxColorValue=255), upperright=rgb(130,0,80, maxColorValue=255), bottomleft="grey", bottomright=rgb(255,230,15, maxColorValue=255), xlab="mean", ylab="std", brksx, brksy,tckspotsx, tckspotsy){
my.data<-seq(0,1,.01)
my.class<-classIntervals(my.data,n=nquantiles,style="quantile")
my.pal.1<-findColours(my.class,c(upperleft,bottomleft))
my.pal.2<-findColours(my.class,c(upperright, bottomright))
col.matrix<-matrix(nrow = 101, ncol = 101, NA)
postscript(outleg,height=4,width=4 , paper="special" , horizo=F,)
for(i in 1:101){
my.col<-c(paste(my.pal.1[i]),paste(my.pal.2[i]))
col.matrix[102-i,]<-findColours(my.class,my.col)}
par(mai=c(1.2,1.2,0.5,0.5))
plot(c(1,1),pch=19,col=my.pal.1, cex=0.5,xlim=c(0,1),ylim=c(0,1),frame.plot=F,axes=F, xlab=xlab, ylab=ylab,cex.lab=1.7) # change axis label size
axis(side=1, at=tckspotsx, labels=brksx, cex.axis=1.2)
axis(side=2, at=tckspotsy, labels=brksy, cex.axis=1.2)
for(i in 1:101){
col.temp<-col.matrix[i-1,]
points(my.data,rep((i-1)/100,101),pch=15,col=col.temp, cex=1)}
dev.off()	       	       
seqs<-seq(0,100,(100/nquantiles))
seqs[1]<-1
col.matrix <- col.matrix[c(seqs), c(seqs)]
}


#brewer.pinkblue
col.matrix <- colmatxy(nquantiles=nquantiles, upperleft="yellow", upperright="red", bottomleft="blue", bottomright="green", xlab=nutP, ylab=nutN, brksx=round(plotbrkstc, digits=2), brksy=round(plotbrksbn, digits=2),tckspotsx=tickspotsx,tckspotsy=tickspotsy)

plotbrksbn<-quantile(bnplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #y-label values
plotbrkstc<-quantile(tcplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #x-label values

collst <- list("brksx"=round(plotbrkstc, digits=3),"brksy"=round(plotbrksbn, digits=3),"colmat"=col.matrix)
outnam <- paste0(legpre,".rda")    
save(collst,file=paste0(dirOut,outnam))


EOF

ps2epsi  ${dirOut}/${legpre}.ps   ${dirOut}/${legpre}.eps    ; rm ${dirOut}/${legpre}.ps
epstopdf ${dirOut}/${legpre}.eps

' _


for form in ${forms[@]}
do
    for j in 1 2 3 4
    do
      echo ${form}  $j
    done
done | xargs -n 2 -P 4 bash -c $'
export form=$1
export i=$2
export nutN=${form}N_${i}
export nutP=${form}P_${i}
export legpre=map_pred_CONUS_bivar_leg_${form}_N-P_man    
export figoutpre=map_pred_CONUS_bivar_${form}_N-P_${i}_man

R --vanilla --no-readline -q <<EOF

library(classInt)
library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
library(sp)

dirIn <- Sys.getenv(c(\'dirIn\'))
dirOut <- Sys.getenv(c(\'dirOut\'))				 
legpre <- Sys.getenv(c(\'legpre\'))
nutN <- Sys.getenv(c(\'nutN\'))
nutP <- Sys.getenv(c(\'nutP\'))
season <- Sys.getenv(c(\'i\'))
form <- Sys.getenv(c(\'form\'))

figmean <- paste0("map_pred_CONUS_mean_",nutN,"_10k_clump_filled.tif")
figstd <- paste0("map_pred_CONUS_mean_",nutP,"_10k_clump_filled.tif")
figoutpre <- paste0("map_pred_CONUS_bivar_",form,"_N-P_",season,"_man")

meanraster <- raster(paste0(dirIn,figmean))
sdraster <- raster(paste0(dirIn,figstd))

bivariate.map<-function(rasterx, rastery, colormatrix=col.matrix, nquantiles=nquantiles,brks1,brks2){
quanmean<-getValues(rasterx)
temp <- data.frame(quanmean, quantile=rep(NA, length(quanmean)))
#brks <- with(temp, quantile(temp,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))))
r1 <- within(temp, quantile <- cut(quanmean, breaks = brks1, labels = 2:length(brks1),include.lowest = TRUE))
quantr<-data.frame(r1[,2]) 
quanvar<-getValues(rastery)
temp <- data.frame(quanvar, quantile=rep(NA, length(quanvar)))
#brks <- with(temp, quantile(temp,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))))
r2 <- within(temp, quantile <- cut(quanvar, breaks = brks2, labels = 2:length(brks2),include.lowest = TRUE))
quantr2<-data.frame(r2[,2])
as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}
col.matrix2<-colormatrix
cn<-unique(colormatrix)
for(i in 1:length(col.matrix2)){
ifelse(is.na(col.matrix2[i]),col.matrix2[i]<-1,col.matrix2[i]<-which(col.matrix2[i]==cn)[1])}
cols<-numeric(length(quantr[,1]))
for(i in 1:length(quantr[,1])){
a<-as.numeric.factor(quantr[i,1])
b<-as.numeric.factor(quantr2[i,1])
cols[i]<-as.numeric(col.matrix2[b,a])}
r<-rasterx
r[1:length(r)]<-cols
return(r)}

load(paste0(dirOut,legpre,".rda"))

bivmap<-bivariate.map(rasterx=sdraster,rastery=meanraster, colormatrix=collst[["colmat"]], nquantiles=nquantiles, brks1=collst[["brksx"]],brks2=collst[["brksy"]])
postscript(paste0(dirOut,figoutpre,".ps"),height=12,width=16,horizo=F ,  paper="special" )
plot(bivmap,frame.plot=F,axes=F,box=F,add=F,legend=F,col=as.vector(collst[["colmat"]]))
dev.off()

EOF

ps2epsi  ${dirOut}/${figoutpre}.ps ${dirOut}/${figoutpre}.eps  ; rm ${dirOut}/${figoutpre}.ps
epstopdf ${dirOut}/${figoutpre}.eps

' _





