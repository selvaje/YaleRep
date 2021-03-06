# module load Apps/R/3.1.1-generic
# R

# eventualy # other data in ftp://aftp.cmdl.noaa.gov/data/radiation/   
# to enlarge the script in automatick 
options(width=as.integer(system("stty -a | head -n 1 | awk '{print $7}' | sed 's/;//'", intern=T)))

library(data.table)
library(sp)
library(foreign)  
library(rgl)
library(reshape)
library(latticeExtra)
options("width"=200)

load("/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/validation/wrdc_gaw/Rdata/wrdc.gaw.RData")
load("/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/validation/wrdc/Rdata/wrdc.RData")
load("/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/validation/geba/Rdata/geba.RData")
load("/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/validation/nsrdb/RData/nsrdb.RData4")


# per controllare i data.frame 

randomRows = function(df){
   return(df[sample(nrow(df),20),])
}


##### geba https://www1.ethz.ch/geba/  

# clean the data  and aggregate 
# c'e' un anno == 1000 la linea successiva del qc riporta l'anno di appartenenza. per ora non corretto

# his   2161    1 GLOBAL 10-2MJm-2d-1         Ab(R)      WRR   01-JAN-82   31-DEC-91
# his   2159    2 DIRECT calcm-2d-1           Ab(R)      IPS   01-JAN-64   31-DEC-79
# his   2161    3 DIFFUS 10-2MJm-2d-1         Ab(R)      WRR   01-JAN-82   31-DEC-91


# wrdc.gaw the direct is normal                  J/cm² 
# geba probably is normal also in geba
# wrdc global and diffuse                        J/cm²
# NSRDB 1991–2010 update is a serially complete collection of hourly values of the three most common measurements of solar radiation (i.e., global horizontal, direct normal, and diffuse horizontal)

# conctrollare le unita di misura forse moltiplicare per 10 

even_indexes<-seq(1,13694,2)
geba.dif.clean = data.frame(geba.dif[even_indexes,])
geba.dif.agr  = aggregate ( geba.dif.clean, by=list(geba.dif.clean$STAT)  , FUN=mean  , na.rm=TRUE  )
geba.dif.agr$Group.1 = NULL
geba.dif.agr$YEAR = NULL
geba.dif.agr$MEANY  = NULL
geba.dif.agr$db  = "geba"


d.geba.dif.agr=melt(geba.dif.agr,id.vars=c("STAT","db"))
d.geba.dif.agr$MO = d.geba.dif.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.geba.dif.agr$MO <- ifelse(d.geba.dif.agr$variable==month[m], m, d.geba.dif.agr$MO  )
}


even_indexes<-seq(1,1842,2)
geba.dir.clean = data.frame(geba.dir[even_indexes,])
geba.dir.agr  = aggregate ( geba.dir.clean, by=list(geba.dir.clean$STAT)  , FUN=mean  , na.rm=TRUE  )
geba.dir.agr$Group.1 = NULL
geba.dir.agr$YEAR = NULL
geba.dir.agr$MEANY  = NULL
geba.dir.agr$db  = "geba"


d.geba.dir.agr=melt(geba.dir.agr,id.vars=c("STAT","db"))
d.geba.dir.agr$MO = d.geba.dir.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.geba.dir.agr$MO <- ifelse(d.geba.dir.agr$variable==month[m], m, d.geba.dir.agr$MO  )
}


even_indexes<-seq(1,62994,2)
geba.glo.clean = data.frame(geba.glo[even_indexes,])
geba.glo.agr  = aggregate ( geba.glo.clean, by=list(geba.glo.clean$STAT)  , FUN=mean  , na.rm=TRUE  )
geba.glo.agr$Group.1 = NULL
geba.glo.agr$YEAR = NULL
geba.glo.agr$MEANY  = NULL
geba.glo.agr$db  = "geba"


d.geba.glo.agr=melt(geba.glo.agr,id.vars=c("STAT","db"))
d.geba.glo.agr$MO = d.geba.glo.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.geba.glo.agr$MO <- ifelse(d.geba.glo.agr$variable==month[m], m, d.geba.glo.agr$MO  )
}


# ready for the validation 

######  wrdc http://wrdc.mgo.rssi.ru/Protected/DataCGI_HTML/data_list_full/root_index.html
# global and diffuse 

# flag (F) = 0 (blank in the table) means that a value has good quality flag = 1 - questionable value flag = 2 - bad or missing value   

wrdc.dif$year = as.numeric(wrdc.dif$year )
wrdc.dif.agr.mean = aggregate ( . ~ year + station ,   data = wrdc.dif  , FUN=mean  , na.rm=TRUE  )
wrdc.dif.agr = aggregate ( wrdc.dif.agr.mean ,  by=list( wrdc.dif.agr.mean$station)   , FUN=mean  , na.rm=TRUE  )
wrdc.dif.agr$station = wrdc.dif.agr$Group.1
wrdc.dif.agr$Group.1 = NULL
wrdc.dif.agr$year = NULL
wrdc.dif.agr$DATE = NULL
wrdc.dif.agr$F.JAN = NULL
wrdc.dif.agr$F.FEB = NULL
wrdc.dif.agr$F.MAR = NULL
wrdc.dif.agr$F.APR = NULL
wrdc.dif.agr$F.MAY = NULL
wrdc.dif.agr$F.JUN = NULL
wrdc.dif.agr$F.JUL = NULL
wrdc.dif.agr$F.AUG = NULL
wrdc.dif.agr$F.SEP = NULL
wrdc.dif.agr$F.OCT = NULL
wrdc.dif.agr$F.NOV = NULL
wrdc.dif.agr$F.DEC = NULL
wrdc.dif.agr$db = "wrdc"


d.wrdc.dif.agr=melt(wrdc.dif.agr,id.vars=c("station","db"))
d.wrdc.dif.agr$MO = d.wrdc.dif.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.wrdc.dif.agr$MO <- ifelse(d.wrdc.dif.agr$variable==month[m], m, d.wrdc.dif.agr$MO  )
}


# ricontrollare e pulire il dato, riempire il gli na con i la media 

wrdc.glo$year = as.numeric(wrdc.glo$year )
wrdc.glo.agr.mean = aggregate ( . ~ year + station ,   data = wrdc.glo  , FUN=mean  , na.rm=TRUE  )
wrdc.glo.agr = aggregate ( wrdc.glo.agr.mean ,  by=list( wrdc.glo.agr.mean$station)   , FUN=mean  , na.rm=TRUE  )
wrdc.glo.agr$station = wrdc.glo.agr$Group.1
wrdc.glo.agr$Group.1 = NULL

wrdc.glo.agr$year = NULL
wrdc.glo.agr$DATE = NULL
wrdc.glo.agr$F.JAN = NULL
wrdc.glo.agr$F.FEB = NULL
wrdc.glo.agr$F.MAR = NULL
wrdc.glo.agr$F.APR = NULL
wrdc.glo.agr$F.MAY = NULL
wrdc.glo.agr$F.JUN = NULL
wrdc.glo.agr$F.JUL = NULL
wrdc.glo.agr$F.AUG = NULL
wrdc.glo.agr$F.SEP = NULL
wrdc.glo.agr$F.OCT = NULL
wrdc.glo.agr$F.NOV = NULL
wrdc.glo.agr$F.DEC = NULL
wrdc.glo.agr$db = "wrdc"

d.wrdc.glo.agr=melt(wrdc.glo.agr,id.vars=c("station","db"))
d.wrdc.glo.agr$MO = d.wrdc.glo.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.wrdc.glo.agr$MO <- ifelse(d.wrdc.glo.agr$variable==month[m], m, d.wrdc.glo.agr$MO  )
}

##### wrdc gaw http://wrdc.mgo.rssi.ru/wrdccgi/protect.exe?wrdc/data_gaw.htm

### wrdc.gaw.dif.agr

wrdc.gaw.dif$year = as.numeric(wrdc.gaw.dif$year )
wrdc.gaw.dif.agr.mean = aggregate ( . ~ year + station ,   data = wrdc.gaw.dif  , FUN=mean  , na.rm=TRUE  )
wrdc.gaw.dif.agr      = aggregate ( wrdc.gaw.dif.agr.mean ,  by=list( wrdc.gaw.dif.agr.mean$station)   , FUN=mean  , na.rm=TRUE  )

wrdc.gaw.dif.agr$station = wrdc.gaw.dif.agr$Group.1
wrdc.gaw.dif.agr$Group.1 = NULL
wrdc.gaw.dif.agr$year = NULL
wrdc.gaw.dif.agr$DATE = NULL
wrdc.gaw.dif.agr$F.JAN = NULL
wrdc.gaw.dif.agr$F.FEB = NULL
wrdc.gaw.dif.agr$F.MAR = NULL
wrdc.gaw.dif.agr$F.APR = NULL
wrdc.gaw.dif.agr$F.MAY = NULL
wrdc.gaw.dif.agr$F.JUN = NULL
wrdc.gaw.dif.agr$F.JUL = NULL
wrdc.gaw.dif.agr$F.AUG = NULL
wrdc.gaw.dif.agr$F.SEP = NULL
wrdc.gaw.dif.agr$F.OCT = NULL
wrdc.gaw.dif.agr$F.NOV = NULL
wrdc.gaw.dif.agr$F.DEC = NULL
wrdc.gaw.dif.agr$db = "wrdc.gaw"

d.wrdc.gaw.dif.agr=melt(wrdc.gaw.dif.agr,id.vars=c("station","db"))
d.wrdc.gaw.dif.agr$MO = d.wrdc.gaw.dif.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.wrdc.gaw.dif.agr$MO <- ifelse(d.wrdc.gaw.dif.agr$variable==month[m], m, d.wrdc.gaw.dif.agr$MO  )
}

######  ### wrdc.gaw.dir.agr

wrdc.gaw.dir$year = as.numeric(wrdc.gaw.dir$year )
wrdc.gaw.dir.agr.mean = aggregate ( . ~ year + station ,   data = wrdc.gaw.dir  , FUN=mean  , na.rm=TRUE  )
wrdc.gaw.dir.agr = aggregate ( wrdc.gaw.dir.agr.mean ,  by=list( wrdc.gaw.dir.agr.mean$station)   , FUN=mean  , na.rm=TRUE  )

wrdc.gaw.dir.agr$station = wrdc.gaw.dir.agr$Group.1
wrdc.gaw.dir.agr$Group.1 = NULL
wrdc.gaw.dir.agr$db = "wrdc.gaw"
wrdc.gaw.dir.agr$year = NULL
wrdc.gaw.dir.agr$DATE = NULL
wrdc.gaw.dir.agr$F.JAN = NULL
wrdc.gaw.dir.agr$F.FEB = NULL
wrdc.gaw.dir.agr$F.MAR = NULL
wrdc.gaw.dir.agr$F.APR = NULL
wrdc.gaw.dir.agr$F.MAY = NULL
wrdc.gaw.dir.agr$F.JUN = NULL
wrdc.gaw.dir.agr$F.JUL = NULL
wrdc.gaw.dir.agr$F.AUG = NULL
wrdc.gaw.dir.agr$F.SEP = NULL
wrdc.gaw.dir.agr$F.OCT = NULL
wrdc.gaw.dir.agr$F.NOV = NULL
wrdc.gaw.dir.agr$F.DEC = NULL


d.wrdc.gaw.dir.agr=melt(wrdc.gaw.dir.agr,id.vars=c("station","db"))
d.wrdc.gaw.dir.agr$MO = d.wrdc.gaw.dir.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.wrdc.gaw.dir.agr$MO <- ifelse(d.wrdc.gaw.dir.agr$variable==month[m], m, d.wrdc.gaw.dir.agr$MO  )
}

#### wrdc.gaw.glo

wrdc.gaw.glo$year = as.numeric(wrdc.gaw.glo$year )
wrdc.gaw.glo.agr.mean = aggregate ( . ~ year + station ,   data = wrdc.gaw.glo  , FUN=mean  , na.rm=TRUE  )
wrdc.gaw.glo.agr = aggregate ( wrdc.gaw.glo.agr.mean ,  by=list( wrdc.gaw.glo.agr.mean$station)   , FUN=mean  , na.rm=TRUE  )
wrdc.gaw.glo.agr$station = wrdc.gaw.glo.agr$Group.1

wrdc.gaw.glo.agr$db = "wrdc.gaw"
wrdc.gaw.glo.agr$Group.1 = NULL
wrdc.gaw.glo.agr$year = NULL
wrdc.gaw.glo.agr$DATE = NULL
wrdc.gaw.glo.agr$F.JAN = NULL
wrdc.gaw.glo.agr$F.FEB = NULL
wrdc.gaw.glo.agr$F.MAR = NULL
wrdc.gaw.glo.agr$F.APR = NULL
wrdc.gaw.glo.agr$F.MAY = NULL
wrdc.gaw.glo.agr$F.JUN = NULL
wrdc.gaw.glo.agr$F.JUL = NULL
wrdc.gaw.glo.agr$F.AUG = NULL
wrdc.gaw.glo.agr$F.SEP = NULL
wrdc.gaw.glo.agr$F.OCT = NULL
wrdc.gaw.glo.agr$F.NOV = NULL
wrdc.gaw.glo.agr$F.DEC = NULL

d.wrdc.gaw.glo.agr=melt(wrdc.gaw.glo.agr,id.vars=c("station","db"))
d.wrdc.gaw.glo.agr$MO = d.wrdc.gaw.glo.agr$variable

month=c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC") 
for(m in c(1:12))  {
d.wrdc.gaw.glo.agr$MO <- ifelse(d.wrdc.gaw.glo.agr$variable==month[m], m, d.wrdc.gaw.glo.agr$MO  )
}


# data select 

###### nsrdb used to validate and controll the other data station 
###### nsrdb tmy3 used to validate and controll the other data station   inserire dopo

nsrdb$db ="nsrdb"

# import the radiation modelled 
radModel = read.table ("/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/validation/extract/Hrad_model.txt" , header=TRUE)

d=melt(radModel,id.vars=c("X","Y","IDstat","db"))
d$month=as.numeric(gsub("\\D", "", d$variable))
d$type=gsub("[0-9]","",d$variable)
d2=cast(d,X+Y+IDstat+db+month~type)

# d2 is the radiation modelled to be crossed with the other data 

# start to merge the modelled radiation with the observation 

rad.nsrdb  = merge (d2 , nsrdb , by.x = c("IDstat","month","db") , by.y = c("CODE","MO","db") )
rad.nsrdb$AVDIRH = rad.nsrdb$AVDIR
rad.nsrdb$AVDIFH = rad.nsrdb$AVDIF

rad.nsrdbHH = subset (rad.nsrdb , rad.nsrdb$bCA_m >= 0   )

# prepare the rad.wrdc.gaw.dif

rad.wrdc.gaw.dir  = merge (d2 , d.wrdc.gaw.dir.agr  , by.x = c("IDstat","month","db") , by.y = c("station","MO","db") )
colnames(rad.wrdc.gaw.dir)[13] <- "AVDIR"
rad.wrdc.gaw.dif  = merge (d2 , d.wrdc.gaw.dif.agr  , by.x = c("IDstat","month","db") , by.y = c("station","MO","db") )
colnames(rad.wrdc.gaw.dif)[13] <- "AVDIF"
rad.wrdc.gaw.glo  = merge (d2 , d.wrdc.gaw.glo.agr  , by.x = c("IDstat","month","db") , by.y = c("station","MO","db") )
colnames(rad.wrdc.gaw.glo)[13] <- "AVGLO"

# chreate the dir horizontal 
rad.wrdc.gaw.dirH =  merge (rad.wrdc.gaw.glo , rad.wrdc.gaw.dif  , by.x = c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m", "dT_m","variable"  ) , by.y =  c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m", "dT_m","variable"))
rad.wrdc.gaw.dirH$AVDIRH =  (rad.wrdc.gaw.dirH$AVGLO   -  rad.wrdc.gaw.dirH$AVDIF)*3.6
rad.wrdc.gaw.dirHH = subset ( rad.wrdc.gaw.dirH , rad.wrdc.gaw.dirH$bCA_m >= 0 )

rad.wrdc.gaw.dif = subset ( rad.wrdc.gaw.dif , dCA_m >= 0)
rad.wrdc.gaw.dif$AVDIFH =   rad.wrdc.gaw.dif$AVDIF * 3.6 

# plot(rad.wrdc.gaw.dirH$AVDIRH ,  rad.wrdc.gaw.dirH$bCA_m)

# prepare the rad.wrdc.dif

rad.wrdc.dif  = merge (d2 , d.wrdc.dif.agr  , by.x = c("IDstat","month","db") , by.y = c("station","MO","db") )
colnames(rad.wrdc.dif)[13] <- "AVDIF"
rad.wrdc.glo  = merge (d2 , d.wrdc.glo.agr  , by.x = c("IDstat","month","db") , by.y = c("station","MO","db") )
colnames(rad.wrdc.glo)[13] <- "AVGLO"

rad.wrdc.dif = subset ( rad.wrdc.dif , dCA_m >= 0)
rad.wrdc.dif$AVDIFH =   rad.wrdc.dif$AVDIF * 3.6 

# dir horizontal preparation 

rad.wrdc.dirH =  merge (rad.wrdc.glo , rad.wrdc.dif  , by.x = c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m", "dT_m","variable"  ) , by.y =  c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m", "dT_m","variable"))
rad.wrdc.dirH$AVDIRH =  (rad.wrdc.dirH$AVGLO   -  rad.wrdc.dirH$AVDIF)*3.6
rad.wrdc.dirHH = subset ( rad.wrdc.dirH , rad.wrdc.dirH$bCA_m >= 0 )

# plot( rad.wrdc.dirH$AVDIRH ,  rad.wrdc.dirH$bCA_m )

# prepare the geba

rad.geba.dif  = merge (d2 , d.geba.dif.agr  , by.x = c("IDstat","month","db") , by.y = c("STAT","MO","db") )
colnames(rad.geba.dif)[13] <- "AVDIF"
rad.geba.dir  = merge (d2 , d.geba.dir.agr  , by.x = c("IDstat","month","db") , by.y = c("STAT","MO","db") )
colnames(rad.geba.dir)[13] <- "AVDIR"
rad.geba.glo  = merge (d2 , d.geba.glo.agr  , by.x = c("IDstat","month","db") , by.y = c("STAT","MO","db") )
colnames(rad.geba.glo)[13] <- "AVGLO"

rad.geba.dif = subset ( rad.geba.dif , dCA_m >= 0)
rad.geba.dif$AVDIFH =   rad.geba.dif$AVDIF * 36 

rad.geba.dirH =  merge (rad.geba.glo , rad.geba.dif  , by.x = c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m", "dT_m","variable"  ) , by.y =  c("IDstat","month","db","X","Y","bCA_m","bT_m","CL_m","dCA_m","dT_m","variable"))
rad.geba.dirH$AVDIRH =  (rad.geba.dirH$AVGLO   -  rad.geba.dirH$AVDIF)*36

# plot( rad.geba.dirH$AVDIRH ,  rad.geba.dirH$bCA_m )
# exlude sampling data in the sea
rad.geba.dirHH = subset ( rad.geba.dirH , rad.geba.dirH$bCA_m >= 0 )

l = list(rad.nsrdbHH  , rad.wrdc.gaw.dirHH , rad.wrdc.dirHH   , rad.geba.dirHH    )
rad.mod.obs.DIRHH =   droplevels (as.data.frame (rbindlist(l , fill=TRUE)) )

png('dirCA_all_month.png' , width = 1000, height = 1000 )

plot(   rad.nsrdbHH$AVDIRH ,  rad.nsrdbHH$bCA_m ,  pch=16 , cex=1 , xlab="Observations", ylab="Model Prediction - Linke - Cloud effect",  ylim=c(0,8000), xlim=c(0,12000), col="magenta") 
points( rad.wrdc.dirHH$AVDIRH ,  rad.wrdc.dirHH$bCA_m ,  pch=16 , cex=1  , col="green" )
points( rad.geba.dirHH$AVDIRH ,  rad.geba.dirHH$bCA_m ,  pch=16 , cex=1 , col="blue")
points( rad.wrdc.gaw.dirHH$AVDIRH ,  rad.wrdc.gaw.dirHH$bCA_m  ,  pch=16 , cex=.5 , col="red")

abline (lm(  (subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$bCA_m   ~    (subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$AVDIRH ) , col='red' ,   lwd = 3 )
abline ( 0 , 1 ,    lwd = 3 )

dev.off()

png('dirT_all_month.png' , width = 1000, height = 1000 )

plot(   rad.nsrdbHH$AVDIRH ,  rad.nsrdbHH$bT_m ,  pch=16 , cex=1 , xlab="Observations", ylab="Model Prediction - Linke",  ylim=c(0,8000), xlim=c(0,12000), col="magenta") 
points( rad.wrdc.dirHH$AVDIRH ,  rad.wrdc.dirHH$bT_m ,  pch=16 , cex=1  , col="green" )
points( rad.geba.dirHH$AVDIRH ,  rad.geba.dirHH$bT_m ,  pch=16 , cex=1 , col="blue")
points( rad.wrdc.gaw.dirHH$AVDIRH ,  rad.wrdc.gaw.dirHH$bT_m  ,  pch=16 , cex=1 , col="red")

abline (lm(  (subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$bT_m   ~    (subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$AVDIRH ) , col='red' ,  lwd = 3 )
abline ( 0 , 1 ,  lwd = 3 )

dev.off()

# plot the diffuse all the observation 

l = list(rad.nsrdbHH  , rad.wrdc.gaw.dif , rad.wrdc.dif   , rad.geba.dif    )
rad.mod.obs.DIFHH =   droplevels (as.data.frame (rbindlist(l , fill=TRUE)) )

png('difCA_all_month.png' , width = 1000, height = 1000 )

plot(   rad.nsrdbHH$AVDIFH ,  rad.nsrdbHH$dCA_m ,  pch=16 , cex=1 , xlab="Observations", ylab="Model Prediction - Linke - Cloud effect",  ylim=c(0,2000), xlim=c(0,6000), col="magenta")
points( rad.wrdc.dirHH$AVDIFH ,  rad.wrdc.dirHH$dCA_m ,  pch=16 , cex=1  , col="green" )
points( rad.geba.dirHH$AVDIFH ,  rad.geba.dirHH$dCA_m ,  pch=16 , cex=1 , col="blue")
points( rad.wrdc.gaw.dirHH$AVDIFH ,  rad.wrdc.gaw.dirHH$bCA_m  ,  pch=16 , cex=.5 , col="red")

abline( lm((subset( rad.mod.obs.DIFHH ,  AVDIRH >= 0 ))$dCA_m   ~    (subset( rad.mod.obs.DIFHH ,  AVDIRH >= 0 ))$AVDIFH ) , col='red' ,   lwd = 3 )
abline( 0 , 1 ,    lwd = 3 )

dev.off()

png('difT_all_month.png' , width = 1000, height = 1000 )

plot(   rad.nsrdbHH$AVDIFH ,  rad.nsrdbHH$dT_m ,  pch=16 , cex=1 , xlab="Observations", ylab="Model Prediction - Linke",  ylim=c(0,2000), xlim=c(0,6000), col="magenta")
points( rad.wrdc.dirHH$AVDIFH ,  rad.wrdc.dirHH$dT_m ,  pch=16 , cex=1  , col="green" )
points( rad.geba.dirHH$AVDIFH ,  rad.geba.dirHH$dT_m ,  pch=16 , cex=1 , col="blue")
points( rad.wrdc.gaw.dirHH$AVDIFH ,  rad.wrdc.gaw.dirHH$dT_m  ,  pch=16 , cex=1 , col="red")

abline (lm(  (subset( rad.mod.obs.DIFHH ,  AVDIFH >= 0 ))$dT_m   ~    (subset( rad.mod.obs.DIFHH ,  AVDIFH >= 0 ))$AVDIFH ) , col='red' ,  lwd = 3 )
abline ( 0 , 1 ,  lwd = 3 )

dev.off()

# 

#   subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 )  = 18103 observation

png('dirCA.png' , width = 1000, height = 1000 )
xyplot ( bCA_m~AVDIRH  | as.factor(month) , data=subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ) , xlab="Observations", pch=16 , cex=.3 ,   ylab="Model Prediction - Linke - Cloud effect" , xlab.top="Beam (Direct) Solar Radiation" ,  groups = db , auto.key = TRUE  ,  ylim=c(-1:12000) , xlim=c(-1:14000)  )+layer(panel.abline(0,1))+layer(panel.abline(lm(y~x),col="red")   )
dev.off()

png('dirT.png' , width = 1000, height = 1000 )
xyplot ( bT_m~AVDIRH  | as.factor(month) , data=subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ) , xlab="Observations", pch=16 , cex=.3 ,   ylab="Model Prediction - Linke" , xlab.top="Beam (Direct) Solar Radiation" ,  groups = db , auto.key = TRUE  ,  ylim=c(-1:10000) , xlim=c(-1:14000)  )+layer(panel.abline(0,1))+layer(panel.abline(lm(y~x),col="red")   )
dev.off()

png('dirT.png' , width = 1000, height = 1000 )
xyplot ( bT_m ~ AVDIRH  | as.factor(month) , data=subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ) , xlab="Observations", pch=16 , cex=.3 ,   ylab="Model Prediction - Linke" , xlab.top="Beam (Direct) Solar Radiation" ,  groups = db , auto.key = TRUE  ,  ylim=c(-1:10000) , xlim=c(-1:14000)  )+layer(panel.abline(0,1))+layer(panel.abline(lm(y~x),col="red")   )
dev.off()

coef= as.data.frame ((subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$AVDIRH   / (subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$bT_m)
colnames(coef)[1] <- "MODvsOBS"
coef$CL=(subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$CL
coef$month=(subset( rad.mod.obs.DIRHH ,  AVDIRH >= 0 ))$month
is.na(coef) <- do.call(cbind,lapply(coef, is.infinite))
coef=coef[complete.cases(coef),]


xyplot ( MODvsOBS ~ CL  ,   data=coef  , pch=16 , cex=.3 ,   ylab="Observed / Modeleled Clear Sky",    xlab="Cloud"  , xlab.top="Month" ,  groups = month , auto.key = TRUE  ,ylim =c(0,10) )



# plot the diffuse 

# plot(   rad.nsrdbHH$AVDIFH ,  rad.nsrdbHH$dCA_m ,  pch=16 , cex=.5  , xlim=c(1,4000)  , ylim=c(0,4000) )
# points(rad.wrdc.gaw.dif$AVDIFH ,  rad.wrdc.gaw.dif$dCA_m  ,  pch=16 , cex=.5 , col="green")
# points( rad.wrdc.dif$AVDIFH ,  rad.wrdc.dif$dCA_m ,  pch=16 , cex=.5  , col="yellow" )
# points( rad.geba.dif$AVDIFH ,  rad.geba.dif$dCA_m ,  pch=16 , cex=.5 , col="red")



png('difT.png' , width = 1000, height = 1000 )
xyplot ( dT_m~AVDIFH  | as.factor(month) , data=rad.mod.obs.DIFHH , xlab="Observations", pch=16 , cex=.3 ,   ylab="Model Prediction - Linke" , xlab.top="Beam (Direct) Solar Radiation" ,  groups = db , auto.key = TRUE  ,  ylim=c(0,2000) , xlim=c(0,6000)  )+layer(panel.abline(0,1))+layer(panel.abline(lm(y~x),col="red")   )
dev.off()


png('difCA.png' , width = 1000, height = 1000 )
xyplot ( dCA_m~AVDIFH  | as.factor(month) , data=rad.mod.obs.DIFHH , xlab="Observations", pch=16 , cex=.3 ,   ylab="Model Prediction - Linke - Aerosol effect" , xlab.top="Beam (Direct) Solar Radiation" ,  groups = db , auto.key = TRUE  ,  ylim=c(0,2000) , xlim=c(0,6000)  )+layer(panel.abline(0,1))+layer(panel.abline(lm(y~x),col="red")   )
dev.off()

# merge difh and dirh 
DIFH.DIRH  =  merge (  rad.mod.obs.DIFHH ,  rad.mod.obs.DIRHH  , by.x = c("IDstat","month","db","X","Y"  ) , by.y =  c("IDstat","month","db","X","Y"))

png('dif_vs_dir_observation.png' , width = 1000, height = 1000 )
xyplot ( AVDIFH.x ~ AVDIRH.y ,  data=DIFH.DIRH  ,   groups = db ,  auto.key = TRUE  ,  pch=16 , cex=.6  , xlab="DIRECT SOLAR RADIATION" ,  ylab="DIFFUSE  SOLAR RADIATION"  )
dev.off()

png('dif_vs_dir_observation_month.png' , width = 1000, height = 1000 )
xyplot ( AVDIFH.x ~ AVDIRH.y ,  data=DIFH.DIRH  ,   groups = month ,  auto.key = TRUE  ,  pch=16 , cex=.6  , xlab="DIRECT SOLAR RADIATION" ,  ylab="DIFFUSE  SOLAR RADIATION"  )
dev.off()


png('dif_vs_dir_modelled_month.png', width = 1000, height = 1000)
xyplot (  dT_m.x ~ bT_m.x  ,  data=DIFH.DIRH  ,   groups = month ,  auto.key = TRUE  ,  pch=16 , cex=.6  , xlab="DIRECT SOLAR RADIATION" ,  ylab="DIFFUSE SOLAR RADIATION"  )
dev.off()


exit()


for (m in 1:12 ) {
radiation.nsrdb$res.beamT   = residuals(lm(subset(radiation.nsrdb , month == m )$bT_m   ~ subset (radiation.nsrdb , month == m )$AVDIF))
radiation.nsrdb$res.beamCA  = residuals(lm(subset(radiation.nsrdb , month == m )$bCA_m  ~ subset (radiation.nsrdb , month == m )$AVDIF))
radiation.nsrdb$res.diffT   = residuals(lm(subset(radiation.nsrdb , month == m )$dT_m   ~ subset (radiation.nsrdb , month == m )$AVDIR))
radiation.nsrdb$res.diffCA  = residuals(lm(subset(radiation.nsrdb , month == m )$dCA_m  ~ subset (radiation.nsrdb , month == m )$AVDIR))
}


# plotting  glob observed versus clear sky modelled , at montly level 

