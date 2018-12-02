
# module load Apps/R/3.3.2-generic

# install.packge("rgdal")
# install.packge("raster")
# install.packge("ggplot2")

# source("/gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc05_plot_var.R.sh")

library(rgdal)
library(raster)
library(ggplot2)
library("gridExtra")

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

cos_dsm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dsm_wgs84_crop_e_cos.tiff"  ) 
sin_dsm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dsm_wgs84_crop_e_sin.tiff"  ) 
Ew_dsm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dsm_wgs84_crop_e_Ew.tiff"  ) 
Nw_dsm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dsm_wgs84_crop_e_Nw.tiff"  ) 

cos_dtm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dtm_wgs84_crop_e_cos.tiff"  ) 
sin_dtm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dtm_wgs84_crop_e_sin.tiff"  ) 
Ew_dtm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dtm_wgs84_crop_e_Ew.tiff"  ) 
Nw_dtm   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dtm_wgs84_crop_e_Nw.tiff"  ) 

cos_mrt   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/mrt_wgs84_crop_e_cos.tiff"  ) 
sin_mrt   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/mrt_wgs84_crop_e_sin.tiff"  ) 
Ew_mrt   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/mrt_wgs84_crop_e_Ew.tiff"  ) 
Nw_mrt   =  raster ("/project/fas/sbsc/ga254/dataproces/LIDAR/aspect/mrt_wgs84_crop_e_Nw.tiff"  ) 


for ( dir  in c("azimuth","convergence","dx","dxx","dxy","dy","dyy","elongation","exposition","extend","intensity","pcurv","range","roughness","slope","spi","tci","tcurv","tpi","tri","variance","vrm","width","elevation","cos","sin","Ew","Nw")) {

a  = as.data.frame( getValues(get(paste0(dir,"_dsm"))))
names(a)[1]  <-  "dsm"
a$dtm  =  getValues(get(paste0(dir,"_dtm")))
a$mrt  =  getValues(get(paste0(dir,"_mrt")))

a = na.exclude(a)

assign(paste0(dir,"_df") , a  )
}

des="aa"     # to intilize 
letter="zz"  # to intilize 

postscript(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/dsm-dtm_vs_merit_plot.ps") ,  paper="special" ,  horizo=F , width=9, height=12   )

for ( dir  in c("azimuth","convergence","dx","dxx","dxy","dy","dyy","elongation","exposition","extend","intensity","pcurv","range","roughness","slope","spi","tci","tcurv","tpi","tri","variance","vrm","width","elevation","cos","sin","Ew","Nw")) {
data_df = (get(paste0(dir,"_df")))

print (dir)

if(dir == "elevation" )  {  des="Elevation" ; letter="a)" }
if(dir == "slope" )      {  des="Slope"; letter="b)"      }

if(dir == "cos" )   {  des="Aspect Cosine";  letter="c)" } 
if(dir == "sin" )   {  des="Aspect Sine"  ;  letter="d)" }
if(dir == "Ew" )    {  des="Eastness"     ;  letter="e)" }
if(dir == "Nw" )    {  des="Northness"    ;  letter="f)" }

if(dir == "tpi" )          {  des="Topographic Position Index" ; letter="g)" }
if(dir == "tri" )          {  des="Terrain Roughness Index"   ;  letter="h)" }
if(dir == "vrm" )          {  des="Vector Ruggedness Measure" ;  letter="i)" }
if(dir == "roughness" )    {  des="Roughness"; letter="l)"  }

if(dir == "pcurv" )        {  des="Prodir curvature"     ; letter="m)" }
if(dir == "tcurv" )        {  des="Tangential curvature" ;  letter="n)" } 
if(dir == "convergence" )    {  des="Convergence" ; letter="o)" }

if(dir == "spi" )    {  des="Stream power index" ; letter="p)" }
if(dir == "tci" )    {  des="Topographic compound index" ; letter="q)" }

if(dir == "dx" )           {  des="1st partial derivative (E-W slope)" ; letter="r)" }
if(dir == "dxx" )          {  des="2nd partial derivative (E-W slope)" ; letter="s)"  }

if(dir == "dy" )           {  des="1st partial derivative (N-S slope)" ; letter="t)" } 
if(dir == "dyy" )          {  des="2nd partial derivative (N-S slope)" ; letter="u)" }
if(dir == "dxy" )          {  des="1st partial derivative" ; letter="w)" }


if(dir == "elongation" )    {  des="Elongation" ; letter="a)" }
if(dir == "azimut" )    {  des="Elongation azimut" ; letter="a)" }
if(dir == "exposition" )    {  des="Exposition" ; letter="a)" }
if(dir == "extend" )       {  des="Extend" ; letter="a)" }
if(dir == "range" )        {  des="Range" ; letter="a)" }
if(dir == "intensity" )    {  des="Intensity" ; letter="a)" }
if(dir == "width" )    {  des="Width" ; letter="a)" }
if(dir == "variance" )    {  des="Variance" ; letter="a)" }

print(des) 

a =  ggplot    ( data=data_df , aes(x=mrt , y=dsm  )) + geom_point(alpha=1, col='blue', size=0.03) +                xlab("") + ylab("") +
geom_point( data=data_df , aes(x=mrt , y=dtm) ,   alpha=1, col='red' , size=0.03) +                                 xlab("") + ylab("") +
geom_smooth(  data=data_df , aes(x=mrt , y=dsm) ,   method='lm',formula=y~x ,color='black'   ,size=0.3  , se= FALSE ) + xlab("") + ylab("") +
geom_smooth(  data=data_df , aes(x=mrt , y=dtm) ,   method='lm',formula=y~x ,color='orange'  ,size=0.3  , se= FALSE ) + xlab("") + ylab("") +
labs(title = paste(letter,des)  ) +
theme(plot.title=element_text(size=rel(0.6) ,  hjust=0 ) ,
      axis.text.x=element_text(size=rel(0.8)) ,  
      axis.text.y=element_text(size=rel(0.8))
) 

assign(paste0(dir,"_plt") , a  )
}

grid.arrange(elevation_plt,slope_plt,cos_plt,sin_plt,Ew_plt,Nw_plt,tpi_plt,tri_plt,vrm_plt,roughness_plt,pcurv_plt,tcurv_plt,convergence_plt,tci_plt,spi_plt,dx_plt,dxx_plt,dy_plt,dyy_plt,dxy_plt, nrow=5, ncol=4 ) 

dev.off()


# for density plot 
# ggplot(data=a , aes(x=mrt , y=dsm)) +  	geom_point(alpha=0.1, col='blue', size=2) + 	geom_density2d() + 	stat_density2d(aes(fill = ..level..), geom = "polygon") +         aes(x=mrt , y=dtm) + 	geom_point(alpha=0.1, col='red', size=2) + 	geom_density2d() + 	stat_density2d(aes(fill = ..level..), geom = "polygon") + 	xlab('MERIT (m)') + 	ylab('LiDAR DSM (m)') + 	theme_bw()



ggplot    ( data=elevation_df , aes(x=mrt , y=dsm  )) + geom_point(alpha=1, col='blue', size=0.03) +             
geom_point( data=elevation_df , aes(x=mrt , y=dtm) ,   alpha=1, col='red' , size=0.03) +                         
geom_smooth(  data=elevation_df , aes(x=mrt , y=dsm) ,   method='lm',formula=y~x ,color='black'   ,size=0.3  , se= FALSE ) + 
geom_smooth(  data=elevation_df , aes(x=mrt , y=dtm) ,   method='lm',formula=y~x ,color='orange'  ,size=0.3  , se= FALSE ) + 
theme(plot.title=element_text(size=rel(0.6) ,  hjust=0 ) ,
      axis.text.x=element_text(size=rel(0.8)) ,  
      axis.text.y=element_text(size=rel(0.8))
) 






