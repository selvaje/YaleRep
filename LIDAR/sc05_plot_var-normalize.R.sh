
# module load Apps/R/3.3.2-generic

# install.packge("rgdal")
# install.packge("raster")
# install.packge("ggplot2")

# source("/gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc05_plot_var-normalize.R.sh")

library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)

LIDAR="/project/fas/sbsc/ga254/dataproces/LIDAR/"

for ( dir  in c("azimuth","convergence","dx","dxx","dxy","dy","dyy","elongation","exposition","extend","intensity","pcurv","range","roughness","slope","spi","tci","tcurv","tpi","tri","variance","vrm","width")) {
	raster  <- raster(paste0(LIDAR,"/",dir,"/","dsm_wgs84_crop_e.tiff"))
	assign(paste0(dir,"_dsm") , raster  )
	raster  <- raster(paste0(LIDAR,"/",dir,"/","dtm_wgs84_crop_e.tiff"))
	assign(paste0(dir,"_dtm") , raster  )
	raster  <- raster(paste0(LIDAR,"/",dir,"/","mrt_wgs84_crop_e.tiff"))
	assign(paste0(dir,"_mrt") , raster  )
}


# elevation 

elevation_dsm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/input/SC14_CZO/dsm_wgs84_crop_e.tiff"  ) 
elevation_dtm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/input/SC14_CZO/dtm_wgs84_crop_e.tiff"  ) 
elevation_mrt   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/input/SC14_CZO/merit.tiff"  ) 


for ( dir  in c("azimuth","convergence","dx","dxx","dxy","dy","dyy","elongation","exposition","extend","intensity","pcurv","range","roughness","slope","spi","tci","tcurv","tpi","tri","variance","vrm","width","elevation")) {

a  = as.data.frame( getValues(get(paste0(dir,"_dsm"))))
names(a)[1]  <-  "dsm"
a$dtm  =  getValues(get(paste0(dir,"_dtm")))
a$mrt  =  getValues(get(paste0(dir,"_mrt")))

a$dtm.mrt = ( a$dtm -  a$mrt ) / ( a$dtm +  a$mrt )
a$dsm.mrt = ( a$dsm -  a$mrt ) / ( a$dsm +  a$mrt )

a = na.exclude(a)

assign(paste0(dir,"_df") , a  )
}


postscript(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/dsm-dtm_vs_merit_plot-norm.ps") ,  paper="special" ,  horizo=F , width=8, height=12   )

for ( dir  in c("azimuth","convergence","dx","dxx","dxy","dy","dyy","elongation","exposition","extend","intensity","pcurv","range","roughness","slope","spi","tci","tcurv","tpi","tri","variance","vrm","width","elevation")) {
data_df = (get(paste0(dir,"_df")))



a =  ggplot ( data=data_df , aes(x=dtm.mrt , y=dsm.mrt  )) + geom_point(alpha=1, col='blue', size=0.05) +                xlab("") + ylab("") +
geom_smooth(  data=data_df , aes(x=dtm.mrt , y=dsm.mrt) ,   method='lm',formula=y~x ,color='black'   ,size=0.2  , se= FALSE ) + xlab("") + ylab("") +
labs(title = dir ) +
theme(plot.title=element_text(size=rel(0.8)) ,
      axis.text.x=element_text(size=rel(0.6)) ,  
      axis.text.y=element_text(size=rel(0.6))
) 

assign(paste0(dir,"_plt") , a  )
}

grid.arrange(azimuth_plt,convergence_plt,dx_plt,dxx_plt,dxy_plt,dy_plt,dyy_plt,elongation_plt,exposition_plt,extend_plt,intensity_plt,pcurv_plt,range_plt,roughness_plt,slope_plt,spi_plt,tci_plt,tcurv_plt,tpi_plt,tri_plt,variance_plt,vrm_plt,width_plt,elevation_plt , nrow=6, ncol=4 ) 

dev.off()



# for density plot 
# ggplot(data=a , aes(x=mrt , y=dsm)) +  	geom_point(alpha=0.1, col='blue', size=2) + 	geom_density2d() + 	stat_density2d(aes(fill = ..level..), geom = "polygon") +         aes(x=mrt , y=dtm) + 	geom_point(alpha=0.1, col='red', size=2) + 	geom_density2d() + 	stat_density2d(aes(fill = ..level..), geom = "polygon") + 	xlab('MERIT (m)') + 	ylab('LiDAR DSM (m)') + 	theme_bw()

