#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_dif_normalized_stats.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_dif_normalized_stats.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc02_derivative_stats.sh 

# sbatch /home/fas/sbsc/ga254/scripts/NED_MERIT/sc02_dif_normalized_stats_4neg-pos_bias.R.sh
# module load Apps/R/3.0.3  
# module load Apps/R/3.1.1-generic

gdal
module load R/3.4.4-foss-2018a-X11-20180131

cd /project/fas/sbsc/ga254/dataproces/NED_MERIT

#   NA_072_048.tif  
#   NA_072_018.tif 

# create the stat file for the _dif_neg_norm.tif calculate the standard deviation without consider the 0

# cat <( echo elevation aspect-cosine aspect-sine eastness northness slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 1 bash -c $' 
# pksetmask -m $1/tiles/NA_072_048_dif_neg_norm.tif -msknodata -9999 -nodata 0   -i $1/tiles/NA_072_048_dif_neg_norm.tif  -o $1/tiles/NA_072_048_dif_neg_norm_msk.tif &>/dev/null
# pksetmask -m $1/tiles/NA_072_048_dif_pos_norm.tif -msknodata -9999 -nodata 0   -i $1/tiles/NA_072_048_dif_pos_norm.tif  -o $1/tiles/NA_072_048_dif_pos_norm_msk.tif &>/dev/null
# echo $1 $( pkinfo   -nodata 0 -stats -i $1/tiles/NA_072_048_dif_neg_norm_msk.tif)  $( pkinfo -nodata 0 -stats -i $1/tiles/NA_072_048_dif_pos_norm_msk.tif) ; rm  $1/tiles/NA_072_048_dif_neg_norm_msk.tif $1/tiles/NA_072_048_dif_pos_norm_msk.tif 
#  ' _   ) >  txt/NA_072_048_dif_norm_stats_pos-neg.txt 


# cat <( echo elevation aspect-cosine aspect-sine eastness northness slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 1 bash -c $' 
# pksetmask -m $1/tiles/NA_072_018_dif_neg_norm.tif -msknodata -9999 -nodata 0   -i $1/tiles/NA_072_018_dif_neg_norm.tif  -o $1/tiles/NA_072_018_dif_neg_norm_msk.tif &>/dev/null
# pksetmask -m $1/tiles/NA_072_018_dif_neg_norm.tif -msknodata -9999 -nodata 0   -i $1/tiles/NA_072_018_dif_pos_norm.tif  -o $1/tiles/NA_072_018_dif_pos_norm_msk.tif &>/dev/null
# echo $1 $( pkinfo   -nodata 0 -stats -i $1/tiles/NA_072_018_dif_neg_norm_msk.tif)  $( pkinfo -nodata 0 -stats -i $1/tiles/NA_072_018_dif_pos_norm_msk.tif) ; rm  $1/tiles/NA_072_018_dif_neg_norm_msk.tif   $1/tiles/NA_072_018_dif_pos_norm_msk.tif 
#  ' _   ) >  txt/NA_072_018_dif_norm_stats_pos-neg.txt 

R  --vanilla --no-readline   -q  <<'EOF'
library(ggplot2) 
library(rgdal)
library(raster)
library(gridExtra)   
  
rm(list = ls()) 

e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 ) 

elev_M = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_066_048.tif") 
elev_M = crop   (elev_M , e)

elev_M

elev_N = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_066_048.tif") 
elev_N = crop   (elev_N , e)

elev_N

#  MERIT minus NED  ... positive values are due to not pefect correction of the tree hight 
# elev_dif = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/elevation/tiles/NA_066_048_dif.tif")  
# merit - ned 

elev_dif = elev_N - elev_M

for ( dir in c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspectcosine","aspectsine","eastness","northness")) { 
     raster  <- raster(paste0( dir,"/tiles/","/NA_066_048_dif_norm.tif") ) 
     raster = crop (raster , e)
     raster[raster == -9999 ] <- NA
     value=raster@data@values
     assign(paste0(dir) , raster  )
     assign(paste0("val.",dir) , value  )
}

  dat = data.frame(val.elevation)
  dat$val.roughness = val.roughness
  dat$val.tri = val.tri
  dat$val.tpi = val.tpi 
  dat$val.vrm = val.vrm
  dat$val.cti = val.cti
  dat$val.spi = val.spi
  dat$val.slope = val.slope
  dat$val.pcurv = val.pcurv
  dat$val.tcurv = val.tcurv
  dat$val.dx = val.dx
  dat$val.dy = val.dy
  dat$val.dxx = val.dxx 
  dat$val.dyy = val.dyy
  dat$val.dxy = val.dxy 
  dat$val.convergence = val.convergence
  dat$val.aspectcosine =  val.aspectcosine
  dat$val.aspectsine = val.aspectsine 
  dat$val.eastness =  val.eastness
  dat$val.northness = val.northness

names(dat)=c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspect-cosine","aspect-sine","eastness","northness")


   mean.dat  =  sapply(dat, mean) 
sd.less.dat  =  sapply(dat, function(dat) sd(dat[dat<0])) 
sd.more.dat  =  sapply(dat, function(dat) sd(dat[dat>0])) 

dat.plot =  as.data.frame(as.numeric (mean.dat  ))
dat.plot$sd.less = as.numeric (sd.less.dat  )
dat.plot$sd.more = as.numeric (sd.more.dat  )
dat.plot$ID = as.numeric(seq(1,20)) 
colnames (dat.plot)  = c("mean","sd.less","sd.more","ID") 


pdf( "/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/sc02_dif_normalized_stats_4neg-pos.pdf" , width=7, height=2 )

ggplot() +
  geom_line(data = dat.plot , aes(x=ID , y = mean), color = "blue") +
  geom_point(data = dat.plot , aes(x=ID , y = mean), color = "blue" , size = 2  ) +
  geom_errorbar(data = dat.plot, aes(x=ID , ymin=mean, ymax=mean+sd.more), width=0.2 , color = "orange" ) +
  geom_errorbar(data = dat.plot, aes(x=ID , ymin=mean-sd.less, ymax=mean), width=0.2 , color = "orange" ) +
  theme(panel.border = element_blank(), panel.grid.minor = element_blank()) +
  theme(panel.background = element_rect(fill = 'white', colour = 'black')) +
  theme(panel.grid.major.x = element_blank())  +
  theme(panel.grid.major.y = element_line(colour = "grey", size=0.2 ))  +
  theme(axis.text.x = element_text(angle=45 , hjust=1,  size=10 , color="black" )) +
  theme(axis.text.y = element_text( size=10 , color="black")) +
  theme(axis.title.x=element_text(size=10 , vjust=1 )) +
  theme(axis.title.y=element_text(size=10 , hjust=2 , vjust=2 )) +
  theme(plot.margin = unit(c(0.2,1,0,1), "cm")) +
  coord_cartesian(ylim = c(-0.2, 0.2)) + 
  scale_x_discrete(limits=seq(1,20),breaks=seq(1,20),labels=c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspect-cosine","aspect-sine","eastness","northness")) +
  labs(x = "Geomorphometric variables" , y = "Normalised difference" ) 

dev.off()



########### end plot normalize  #####################

########### start  plot bias  #####################

for ( dir in c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspectcosine","aspectsine","eastness","northness")) { 
     raster  <- raster(paste0( dir,"/tiles/","/NA_066_048_bias_msk.tif") ) 
     raster = crop (raster , e)
     raster[raster == -9999 ] <- NA
     value=raster@data@values
     assign(paste0(dir) , raster  )
     assign(paste0("val.",dir) , value  )
}

  dat = data.frame(val.elevation)
  dat$val.roughness = val.roughness
  dat$val.tri = val.tri
  dat$val.tpi = val.tpi 
  dat$val.vrm = val.vrm
  dat$val.cti = val.cti
  dat$val.spi = val.spi
  dat$val.slope = val.slope
  dat$val.pcurv = val.pcurv
  dat$val.tcurv = val.tcurv
  dat$val.dx = val.dx
  dat$val.dy = val.dy
  dat$val.dxx = val.dxx 
  dat$val.dyy = val.dyy
  dat$val.dxy = val.dxy 
  dat$val.convergence = val.convergence
  dat$val.aspectcosine =  val.aspectcosine
  dat$val.aspectsine = val.aspectsine 
  dat$val.eastness =  val.eastness
  dat$val.northness = val.northness

names(dat)=c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspect-cosine","aspect-sine","eastness","northness")

   mean.dat  =  sapply(dat, mean) 
sd.less.dat  =  sapply(dat, function(dat) sd(dat[dat<0])) 
sd.more.dat  =  sapply(dat, function(dat) sd(dat[dat>0])) 

dat.plot =  as.data.frame(as.numeric (mean.dat  ))
dat.plot$sd.less = as.numeric (sd.less.dat  )
dat.plot$sd.more = as.numeric (sd.more.dat  )
dat.plot$ID = as.numeric(seq(1,20)) 
colnames (dat.plot)  = c("mean","sd.less","sd.more","ID") 

sd.less.dat
summary(elevation)

pdf("/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/sc02_dif_normalized_stats_4bias.pdf" , width=7, height=2 )


ggplot() +
  geom_line(data = dat.plot , aes(x=ID , y = mean), color = "blue") +
  geom_point(data = dat.plot , aes(x=ID , y = mean), color = "blue" , size = 2  ) +
  geom_errorbar(data = dat.plot, aes(x=ID , ymin=mean, ymax=mean+sd.more), width=0.2 , color = "orange" ) +
  geom_errorbar(data = dat.plot, aes(x=ID , ymin=mean-sd.less, ymax=mean), width=0.2 , color = "orange" ) +
  theme(panel.border = element_blank(), panel.grid.minor = element_blank()) +
  theme(panel.background = element_rect(fill = 'white', colour = 'black')) +
  theme(panel.grid.major.x = element_blank())  +
  theme(panel.grid.major.y = element_line(colour = "grey", size=0.2 ))  +
  theme(axis.text.x = element_text(angle=45 , hjust=1,  size=10 , color="black" )) +
  theme(axis.text.y = element_text( size=10 , color="black")) +
  theme(axis.title.x=element_text(size=10 , vjust=1 )) +
  theme(axis.title.y=element_text(size=10 , hjust=2 , vjust=2 )) +
  theme(plot.margin = unit(c(0.2,1,0,1), "cm")) +
  coord_cartesian(ylim = c(-42, 42)) + 
  scale_x_discrete(limits=seq(1,20),breaks=seq(1,20),labels=c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspect-cosine","aspect-sine","eastness","northness")) +
  labs(x = "Geomorphometric variables" , y = "Bias difference (%)")

dev.off()

EOF
