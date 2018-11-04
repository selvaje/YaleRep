#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc36_bivariate_BinCound_WatershedCount.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc36_bivariate_BinCound_WatershedCount.R.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc36_bivariate_BinCound_WatershedCount.R.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc36_bivariate_BinCound_WatershedCount.R.sh

module load Apps/R/3.3.2-generic

R --vanilla --no-readline -q <<EOF

library(classInt)
library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
library(sp)
setEPS()
require(raster)
require(ggplot2)


bnplot <- c()
tcplot <- c()

binCount  <- raster("/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count.tif")          # meanraster
watCount  <- raster("/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_count.tif")     # sdraster 


grid<-raster(ncol=1680, nrow=4320)
grid[] <- 1:ncell(grid) 
grid.pdf<-as(grid, "SpatialPixelsDataFrame")

grid.pdf$binCount = (extract(binCount,grid.pdf)) 
grid.pdf$watCount = (extract(watCount,grid.pdf)) 
grid.df<-as.data.frame(grid.pdf)
 







tempy <- getValues(binCount) # y values    
tempx <- getValues(watCount) # x values
bnplot <- c(bnplot,tempy)
tcplot <- c(tcplot,tempx)

# look at the quantiles to set the break values for the plot
nquantiles=10 # set number of quantiles for the plot matrix
plotbrksbn<-quantile(bnplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #y-label values
plotbrkstc<-quantile(tcplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #x-label values

plotbrksbn=seq(1,15,1)
plotbrkstc=seq(1,10,1)

# tickspotsx<-seq(0,1,1/nquantiles) #x-label positions
# tickspotsy<-seq(0,1,1/nquantiles) #y-label positions

tickspotsx=seq(1,15,1)
tickspotsy=seq(1,10,1)

# col matrix function but with custom x and y labels
colmatxy<-function(outleg=paste0("/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/legend_count.eps") , nquantiles=nquantiles, upperleft=rgb(0,150,235, maxColorValue=255), upperright=rgb(130,0,80, maxColorValue=255), bottomleft="grey", bottomright=rgb(255,230,15, maxColorValue=255), xlab="mean", ylab="std", brksx, brksy,tckspotsx, tckspotsy){
my.data<-seq(0,1,.01)
my.class<-classIntervals(my.data,n=nquantiles,style="quantile")
my.pal.1<-findColours(my.class,c(upperleft,bottomleft))
my.pal.2<-findColours(my.class,c(upperright, bottomright))
col.matrix<-matrix(nrow = 101, ncol = 101, NA)
postscript(outleg  ,height=4,width=4 , paper="special" , horizo=F,)
for(i in 1:101){
my.col<-c(paste(my.pal.1[i]),paste(my.pal.2[i]))
col.matrix[102-i,]<-findColours(my.class,my.col)}
par(mai=c(1.2,1.2,0.5,0.5))
plot(c(1,1),pch=19,col=my.pal.1, cex=0.5,xlim=c(0,1),ylim=c(0,1),frame.plot=F,axes=F, xlab=xlab, ylab=ylab,cex.lab=1.7) # change axis label size
axis(side=1, at=tckspotsx, labels=seq(1,15,1), cex.axis=1.2)
axis(side=2, at=tckspotsy, labels=seq(1,10,1), cex.axis=1.2)
for(i in 1:101){
col.temp<-col.matrix[i-1,]
points(my.data,rep((i-1)/100,101),pch=15,col=col.temp, cex=1)}
dev.off()	       	       
seqs<-seq(0,100,(100/nquantiles))
seqs[1]<-1
col.matrix <- col.matrix[c(seqs), c(seqs)]
}


#brewer.pinkblue
col.matrix <- colmatxy(nquantiles=nquantiles, upperleft="yellow", upperright="red", bottomleft="blue", bottomright="green", xlab="Watershed count", ylab="Bin count", brksx=plotbrkstc, brksy=plotbrksbn, tckspotsx=tickspotsx,tckspotsy=tickspotsy)

plotbrksbn<-quantile(bnplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #y-label values
plotbrkstc<-quantile(tcplot,na.rm=TRUE, probs = c(seq(0,1,1/nquantiles))) #x-label values

collst <- list("brksx"=round(plotbrkstc, digits=3),"brksy"=round(plotbrksbn, digits=3),"colmat"=col.matrix)


save(collst,file="/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/collst.rda")  

collst



dev.off()
EOF


exit 

# map 


R --vanilla --no-readline -q <<EOF

library(classInt)
library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
library(sp)
setEPS()


binCount  <- raster("/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_count.tif")          # meanraster
watCount  <- raster("/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_count.tif")     # sdraster 

tempy <- getValues(binCount) # y values    
tempx <- getValues(watCount) # x values



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

plotbrksbn=seq(0,15,1)
plotbrkstc=seq(0,10,1)


tickspotsx=seq(0,15,1)
tickspotsy=seq(0,10,1)

load("/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/collst.rda")  



bivmap<-bivariate.map(rasterx=watCount,rastery=binCount, colormatrix=collst[["colmat"]], nquantiles=nquantiles, brks1=collst[["brksx"]],brks2=collst[["brksy"]])
postscript("/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/additional_layers/bivariate_count.eps",height=12,width=16,horizo=F ,  paper="special" )
plot(bivmap,frame.plot=F,axes=F,box=F,add=F,legend=F,col=as.vector(collst[["colmat"]]))
dev.off()

EOF








