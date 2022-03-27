#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_animation_addcostline.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_animation_addcostline.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc20_animation_addcostline.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc20_animation_addcostline.R.sh

module load Apps/R/3.3.2-generic

export DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure/median_10KM

# correction to have in value in percentage
# cd  /lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/final/percent 

# for file in geom*_10KMperc_GMTEDmd.tif ; do 
# oft-calc -ot Float32  $file  $(basename $file .tif )_p.tif  <<EOF
# 1
# #1 0.0001 *
# EOF
# done

# multiply for 1000 to have larger number if not the was geting a white png 

# for var in pcurv tcurv dyy dxx ; do 
# cd  /lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/final/${var}
# oft-calc -ot Float32   ${var}_10KMmd_GMTEDmd.tif ${var}_10KMmd_GMTEDmd_p.tif   <<EOF                                                                            
# 1
# #1 1000 *
# EOF
# oft-calc -ot Float32   ${var}_10KMsd_GMTEDmd.tif ${var}_10KMsd_GMTEDmd_p.tif  <<EOF
# 1
# #1 1000 *
# EOF
# done 


# non usati per figure
# intensity exposition range variance elongation azimuth extend width  

echo count majority  stdev altitude eastness northness aspectcosine aspectsine dx dxx dxy dy dyy pcurv roughness slope  tcurv  tpi  tri vrm tci spi convergence | xargs -n 1 -P 8 bash -c $' 

export file=$DIR/${1}_10KMmedian_MERIT.tif
export filename=$(basename $file .tif)

if  [ $1 = "count" ]    ; then  export file=$DIR/geom_10KMcount_MERIT.tif ; export filename=$(basename $file .tif) ; fi 
if  [ $1 = "majority" ] ; then  export file=$DIR/geom_10KMmajority_MERIT.tif ; export filename=$(basename $file .tif) ; fi 

export min=$(gdalinfo -mm $file   | grep "Comp" | awk \'{ gsub ("[=,]"," ") ; print $3   }\')
export max=$(gdalinfo -mm $file   | grep "Comp" | awk \'{ gsub ("[=,]"," ") ; print $4   }\')


R --vanilla --no-readline   -q  <<'EOF'

# 
# source ("/gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc20_animation_addcostline.R.sh")
.libPaths( c( .libPaths(), "/home/fas/sbsc/ga254/R/x86_64-unknown-linux-gnu-library/3.0") )

library(rgdal)
library(raster)
library(lattice)
library(rasterVis)

file = Sys.getenv(c("file"))
filename = Sys.getenv(c("filename"))
max = as.numeric(Sys.getenv(c("max")))
min = as.numeric(Sys.getenv(c("min")))

rmr=function(x){
## function to truly delete raster and temporary files associated with them
if(class(x)=="RasterLayer"&grepl("^/tmp",x@file@name)&fromDisk(x)==T){
file.remove(x@file@name,sub("grd","gri",x@file@name))
rm(x)
}
}

path = "/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure"

pdf(paste(path,"/pdf/",filename,".pdf",sep=""),width=16 , height=8 )

paste(filename)

day001=raster(paste(file,sep=""))

ext <- as.vector(extent(day001))
print ("load shapefile")

coast=shapefile("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure/shp/globe_clip.shp" ,  useC=FALSE )

# coast=crop(coast, extent(ext)) 
 
n=100

print("Print original  min and max")
min ; max 

if ( filename == "stdev_10KMmedian_MERIT") { max=20 ; min=0 ; des="Standard deviation - Median"  } 
if ( filename == "altitude_10KMmedian_MERIT") { max=7000 ; min=0 ; des="Elevation - Median"  } 

if ( filename == "slope_10KMmedian_MERIT") { max=15 ; min=min ; des="Slope - Median"  } 
if ( filename == "slope_10KMstdev_MERIT") { max=max ; min=min ; des="Slope - Standard deviation"  }     
if ( filename == "aspectcosine_10KMmedian_MERIT") { max=0.6 ; min=-0.6 ; des="Aspect Cosine - Median"  }
if ( filename == "aspectcosine_10KMstdev_MERIT") { max=max ; min=min ; des="Aspect Cosine - Standard deviation"}
if ( filename == "aspectsine_10KMmedian_MERIT") { max=0.6 ; min=-0.6 ; des="Aspect Sine - Median"  }
if ( filename == "aspectsine_10KMstdev_MERIT") { max=max ; min=min ; des="Aspect Sine - Standard deviation"  }  
if ( filename == "eastness_10KMmedian_MERIT") { max=+0.01 ; min=-0.01 ; des="Eastness - Median"  } 
if ( filename == "eastness_10KMstdev_MERIT") { max=max ; min=min ; des="Eastness - Standard deviation"  }
if ( filename == "northness_10KMmedian_MERIT") { max=0.01 ; min=-0.01 ; des="Northness - Median"  }
if ( filename == "northness_10KMstdev_MERIT") { max=max ; min=min ; des="Northness - Standard deviation"  }
#18
if ( filename == "dx_10KMmedian_MERIT")    { max=0.01 ; min=-0.01 ; des="First order partial derivative (E-W slope) - Median"}      
if ( filename == "dx_10KMstdev_MERIT")     { max=max ; min=min ; des="First order partial derivative (E-W slope) - Standard deviation"  }    
if ( filename == "dxx_10KMmedian_MERIT")   { max=0.00002 ; min=-0.00002 ; des="Second order partial derivative (E-W slope)  - Median"}   
if ( filename == "dxx_10KMstdev_MERIT")    { max=0.0001 ; min=-0.0001 ; des="Second order partial derivative - Standard deviation"} 
if ( filename == "dy_10KMmedian_MERIT")    { max=0.01 ; min=-0.01 ; des="First order partial derivative (N-S slope) - Median"}
if ( filename == "dy_10KMstdev_MERIT")     { max=max ; min=min ; des="First order partial derivative (N-S slope) - Standard deviation"}
if ( filename == "dyy_10KMmedian_MERIT")   { max=0.00002 ; min=-0.00002 ; des="Second order partial derivative (N-S slope) - Median"}       
if ( filename == "dyy_10KMstdev_MERIT")    { max=max  ; min=min ; des="Second order partial derivative - Standard deviation"}  
if ( filename == "dxy_10KMmedian_MERIT")   { max=0.000001  ; min=-0.000001 ; des="Second order partial derivative - Median"} 
if ( filename == "pcurv_10KMmedian_MERIT") { max=0.00001   ; min=-0.00001 ; des="Profile curvature - Median"}
if ( filename == "pcurv_10KMstdev_MERIT")  { max=max    ; min=min ; des="Profile curvature - Standard deviation"  } 
if ( filename == "tcurv_10KMmedian_MERIT") { max=0.00001  ; min=-0.00001 ; des="Tangential curvature - Median"  }   
if ( filename == "tcurv_10KMstdev_MERIT") { max=max ; min=min ; des="Tangential curvature - Standard deviation"  } 
# 31
if ( filename == "roughness_10KMmedian_MERIT") { max=50 ; min=min ; des="Roughness - Median"  }
if ( filename == "roughness_10KMstdev_MERIT") { max=max ; min=min ; des="Roughness - Standard deviation"  }
if ( filename == "tpi_10KMmedian_MERIT") { max=0.2 ; min=-0.2 ; des="Topographic Position Index - Median "  }
if ( filename == "tpi_10KMstdev_MERIT") { max=max ; min=min ; des="Topographic Position Index- Standard deviation"  }
if ( filename == "tri_10KMmedian_MERIT") { max=20 ; min=min ; des="Terrain Ruggedness Index - Median"  }
if ( filename == "tri_10KMstdev_MERIT") { max=max ; min=min ; des="Terrain Ruggedness Index - Standard deviation"  }
if ( filename == "vrm_10KMmedian_MERIT") { max=0.001 ; min=min ; des="Vector Ruggedness Measure - Median"  }
if ( filename == "vrm_10KMstdev_MERIT") { max=max ; min=min ; des="Vector Ruggedness Measure - Standard deviation"  }

if ( filename == "tci_10KMmedian_MERIT") { max=2 ; min=-2 ; des="Topographic Compound Index or Topographic Wetness Index - Median"  }
if ( filename == "spi_10KMmedian_MERIT") { max=0.005 ; min=min ; des="Stream power index - Median"  }
if ( filename == "convergence_10KMmedian_MERIT") { max=2 ; min=-2 ; des="Convergence - Median"  }

if ( filename == "geomflat_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Flat geomorphological landform - Percentage"  }
if ( filename == "geompeak_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Peak geomorphological landform - Percentage"  }
if ( filename == "geomridge_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Ridge geomorphological landform - Percentage"  }
if ( filename == "geomshoulder_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Shoulder geomorphological landform - Percentage"  }
if ( filename == "geomspur_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Spur geomorphological landform - Percentage"  }
if ( filename == "geomfootslope_10KMperc_GMTEDmd_p") { max=25 ; min=min ; des="Slope geomorphological landform - Percentage"  }
if ( filename == "geomhollow_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Hollow geomorphological landform - Percentage"  }
if ( filename == "geomslope_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Footslope geomorphological landform - Percentage"  }
if ( filename == "geomvalley_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Valley geomorphological landform - Percentage"  }
if ( filename == "geompit_10KMperc_GMTEDmd_p") { max=max ; min=min ; des="Pit geomorphological landform - Percentage"  }
if ( filename == "geom_10KMmajority_MERIT")         { max=max ; min=1 ; des="Majority of geomorphological landforms"  }
if ( filename == "geom_10KMcount_MERIT")       { max=max ; min=1 ; des="Count of geomorphological landforms"  }
if ( filename == "geom_10KMsha_MERIT")         { max=max ; min=min ; des="Shannon index of geomorphological landforms"  }  
if ( filename == "geom_10KMent_MERIT")         { max=max ; min=min ; des="Entropy index of geomorphological landforms"  }
if ( filename == "geom_10KMuni_MERIT")         { max=max ; min=min ; des="Uniformity index of geomorphological landforms"  }

print("Print after transformation   min and max")
min ; max 

at=seq(min,max,length=n)
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
 
cols=colR(n)

#  "#0000FF" "#000FEF" "#001EE0" "#002ED0" "#003DC1" "#004DB1" "#005CA2" "#006C92" "#007B83" "#008B73" "#009A64" "#00AA54" "#00B945" "#00C836" "#00D826" "#00E717" "#00F707" "#07FF00" "#17FF00" "#26FF00" "#36FF00" "#45FF00" "#55FF00" "#64FF00" "#73FF00" "#83FF00" "#92FF00" "#A2FF00" "#B1FF00" "#C1FF00" "#D0FF00" "#E0FF00" "#EFFF00" "#FFFE00" "#FFF900" "#FFF400" "#FFEE00" "#FFE900" "#FFE300" "#FFDE00" "#FFD800" "#FFD300" "#FFCD00" "#FFC800" "#FFC300" "#FFBD00" "#FFB800" "#FFB200" "#FFAD00" "#FFA700" "#FF9F00" "#FF9500" "#FF8B00" "#FF8200" "#FF7700" "#FF6D00" "#FF6300" "#FF5900" "#FF4F00" "#FF4500" "#FF3B00" "#FF3100" "#FF2700" "#FF1D00" "#FF1300" "#FF0900" "#FE0000" "#F90202" "#F40505" "#EE0707" "#E90A0A" "#E30C0C" "#DE0F0F" "#D81111" "#D31414" "#CD1616" "#C81919"  "#C21C1C" "#BD1E1E" "#B82121" "#B22323" "#AD2626" "#A72828" "#9F2828" "#952626" "#8B2323" "#812121" "#771E1E" "#6D1B1B" "#631919" "#591616" "#4F1414" "#451111" "#3B0F0F" "#310C0C" "#270A0A" "#1D0707" "#130505" "#090202" "#000000"

#   "0000FF,000FEF,001EE0,002ED0,003DC1,004DB1,005CA2,006C92,007B83,008B73,009A64,00AA54,00B945,00C836,00D826,00E717,00F707,07FF00,17FF00,26FF00,36FF00,45FF00,55FF00,64FF00,73FF00,83FF00,92FF00,A2FF00,B1FF00,C1FF00,D0FF00,E0FF00,EFFF00,FFFE00,FFF900,FFF400,FFEE00,FFE900,FFE300,FFDE00,FFD800,FFD300,FFCD00,FFC800,FFC300,FFBD00,FFB800,FFB200,FFAD00,FFA700,FF9F00,FF9500,FF8B00,FF8200,FF7700,FF6D00,FF6300,FF5900,FF4F00,FF4500,FF3B00,FF3100,FF2700,FF1D00,FF1300,FF0900,FE0000,F90202,F40505,EE0707,E90A0A,E30C0C,DE0F0F,D81111,D31414,CD1616,C81919,C21C1C,BD1E1E,B82121,B22323,AD2626,A72828,9F2828,952626,8B2323,812121,771E1E,6D1B1B,631919,591616,4F1414,451111,3B0F0F,310C0C,270A0A,1D0707,130505,090202,000000"

res=1e8 # res=1e4 for testing and res=1e6 for the final product
greg=list(ylim=c(-60,85),xlim=c(-180,180))

par(cex.axis=2, cex.lab=2, cex.main=4, cex.sub=2 )

day001[day001>max] <- max
day001[day001<min] <- min


lattice.options(
  layout.heights=list(bottom.padding=list(x=2), top.padding=list(x=2)),
  layout.widths=list(left.padding=list(x=4), right.padding=list(x=4))
)


print ( levelplot(day001,col.regions=colR(n),   scales=list(cex=1.5) ,   cuts=99,at=at,colorkey=list(space="bottom",adj=2 , labels=list( cex=1.5)), panel=panel.levelplot.raster, margin=F  , maxpixels=res,ylab="", xlab="" , main=list(paste(des,sep="") , cex=2 , space="left" ) ,useRaster=T ) + layer(sp.polygons(coast ,  fill="white" )  ) )

rmr(day001) # really  remove raster files, this will delete the temporary file
dev.off() 

EOF


convert -flatten   -units PixelsPerInch   -density 300  $DIR/../pdf/$filename.pdf   $DIR/../png/$filename.png


' _ 

exit 




# forms animation 

for file  in geo*_10KMperc_GMTEDmd_p.png   ; do composite -geometry +450+1120 \(  class.png -resize 142% \) $file class_$file ; done
# portati in locale su ~/Documents/yale_projects/presentation_nov_2015/gif , messo il pallino su ogni classe e fatto il gif
convert   -delay 500   -loop 0 class_geomflat_10KMperc_GMTEDmd_p.png  class_geompeak_10KMperc_GMTEDmd_p.png class_geomridge_10KMperc_GMTEDmd_p.png class_geomshoulder_10KMperc_GMTEDmd_p.png class_geomspur_10KMperc_GMTEDmd_p.png class_geomslope_10KMperc_GMTEDmd_p.png  class_geomhollow_10KMperc_GMTEDmd_p.png class_geomfootslope_10KMperc_GMTEDmd_p.png class_geomvalley_10KMperc_GMTEDmd_p.png class_geompit_10KMperc_GMTEDmd_p.png class_geom_10KMperc_GMTEDmd_p.gif

convert -delay 300 -loop 0 roughness_10KM*.png  tpi_10KM*.png   tri_10KM*.png  vrm_10KM*.png roughness.gif

convert   -delay 300   -loop 0   pcurv_10KM*.png tcurv_10KM*.png dx_10KM*.png dy_10KM*.png  curvature_300.gif 

convert   -delay 300   -loop 0 geom_10KMcount_GMTEDmd.png  geom_10KMent_GMTEDmd.png  geom_10KMmaj_GMTEDmd.png  geom_10KMsha_GMTEDmd.png  geom_10KMuni_GMTEDmd.png  geomorphic_entropy.gif 

convert   -delay 300   -loop 0  elevation_md_GMTED2010_md_km10.png elevation_range_GMTED2010_mxmi_km10.png  elevation_sd_GMTED2010_md_km10.png elevation_sd_GMTED2010_sd_km10.png elevation_psd_GMTED2010_sd_km10.png     elevation_cv_GMTED2010_mnsd_km10.png elevation_cv_GMTED2010_mnpsd_km10.png elevation_300.png


