
# bash /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc06_plot_dsm_dtm.R.sh 


# ME07_Snyder NH09_Finkelman MT05_05Lorang ID09_Lloyd  OR07_MalheurNF ILC09_ClearCrk

INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/equi/
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/equi_crop
MERIT=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA

# for var in dsm dtm ; do 
# ID09_Lloyd 
# gdal_translate  -srcwin 0 0  150 217      $INDIR/ID09_Lloyd_${var}.tif   $OUTDIR/ID09_Lloyd_${var}_a.tif 
# gdal_translate  -srcwin 150  0 128   217  $INDIR/ID09_Lloyd_${var}.tif   $OUTDIR/ID09_Lloyd_${var}_b.tif 

# pkgetmask -min -1  -max 9999  -i     $OUTDIR/ID09_Lloyd_${var}_a.tif   -o   $OUTDIR/ID09_Lloyd_${var}_a_msk.tif 
# pkgetmask -min -1  -max 9999  -i     $OUTDIR/ID09_Lloyd_${var}_b.tif   -o   $OUTDIR/ID09_Lloyd_${var}_b_msk.tif 

# geo_string=$( oft-bb $OUTDIR/ID09_Lloyd_${var}_a_msk.tif 1   | grep BB | awk '{ print $6-2,$7-2 ,$8-$6+3,$9-$7+3}' )
# pksetmask -m   $OUTDIR/ID09_Lloyd_${var}_a_msk.tif -msknodata  -9999 -nodata -9999 -i     $OUTDIR/ID09_Lloyd_${var}_a.tif -o     $OUTDIR/ID09_Lloyd_${var}_a_msk.tif 
# gdal_translate -srcwin   $geo_string   $OUTDIR/ID09_Lloyd_${var}_a_msk.tif   $OUTDIR/ID09_Lloyd_${var}_a.tif 
# rm -f    $OUTDIR/ID09_Lloyd_${var}_a_msk.tif 

# geo_string=$( oft-bb $OUTDIR/ID09_Lloyd_${var}_b_msk.tif 1   | grep BB | awk '{ print $6-2,$7-2 ,$8-$6+3,$9-$7+3}' )
# pksetmask -m   $OUTDIR/ID09_Lloyd_${var}_b_msk.tif -msknodata  -9999  -nodata -9999 -i     $OUTDIR/ID09_Lloyd_${var}_b.tif -o     $OUTDIR/ID09_Lloyd_${var}_b_msk.tif 
# gdal_translate -srcwin   $geo_string   $OUTDIR/ID09_Lloyd_${var}_b_msk.tif   $OUTDIR/ID09_Lloyd_${var}_b.tif 
# rm -f $OUTDIR/ID09_Lloyd_${var}_b_msk.tif 
# done 
# for var in a b; do 
# gdal_translate -projwin  $( getCorners4Gtranslate   $OUTDIR/ID09_Lloyd_dsm_${var}.tif  )  $MERIT/all_NA_tif.vrt    $OUTDIR/ID09_Lloyd_MERIT_crop.tif 
# gdaldem slope  -p   $OUTDIR/ID09_Lloyd_MERIT_crop.tif     $OUTDIR/ID09_Lloyd_MERIT_crop_slope.tif 

# gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -A   $OUTDIR/ID09_Lloyd_MERIT_crop_slope.tif -B $OUTDIR/ID09_Lloyd_dsm_${var}.tif  --calc="( B.astype(float) - A.astype(float) )" --outfile=$OUTDIR/ID09_Lloyd_dsm_${var}_correct.tif
# pksetmask -m   $OUTDIR/ID09_Lloyd_dsm_${var}.tif -msknodata -9999 -nodata -9999   -i  $OUTDIR/ID09_Lloyd_MERIT_crop.tif -o  $OUTDIR/ID09_Lloyd_mrt_${var}.tif 
# rm -f $OUTDIR/ID09_Lloyd_MERIT_crop.tif 

# gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326  -s_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $OUTDIR/ID09_Lloyd_mrt_${var}.tif   $OUTDIR/ID09_Lloyd_mrt_${var}_wgs84.tif    -tr 0.0008333333 0.0008333333  -overwrite 
# done



# for var in dsm dtm ; do 
# OR07_MalheurNF 
# gdal_translate  -srcwin 0 0  237 108      $INDIR/OR07_MalheurNF_${var}.tif   $OUTDIR/OR07_MalheurNF_${var}_a.tif 
# gdal_translate  -srcwin 0 109 237 152     $INDIR/OR07_MalheurNF_${var}.tif   $OUTDIR/OR07_MalheurNF_${var}_b.tif 

# pkgetmask -min -1  -max 9999  -i     $OUTDIR/OR07_MalheurNF_${var}_a.tif   -o   $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif 
# pkgetmask -min -1  -max 9999  -i     $OUTDIR/OR07_MalheurNF_${var}_b.tif   -o   $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif 

# geo_string=$( oft-bb $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif 1   | grep BB | awk '{ print $6-2,$7-2 ,$8-$6+3,$9-$7+3}' )
# pksetmask -m   $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif -msknodata  -9999 -nodata -9999 -i     $OUTDIR/OR07_MalheurNF_${var}_a.tif -o     $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif 
# gdal_translate -srcwin   $geo_string   $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif   $OUTDIR/OR07_MalheurNF_${var}_a.tif 
# rm -f    $OUTDIR/OR07_MalheurNF_${var}_a_msk.tif 

# geo_string=$( oft-bb $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif 1   | grep BB | awk '{ print $6-2,$7-2 ,$8-$6+3,$9-$7+3}' )
# pksetmask -m   $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif -msknodata  -9999 -nodata -9999 -i     $OUTDIR/OR07_MalheurNF_${var}_b.tif -o     $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif 
# gdal_translate -srcwin   $geo_string   $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif   $OUTDIR/OR07_MalheurNF_${var}_b.tif 
# rm -f $OUTDIR/OR07_MalheurNF_${var}_b_msk.tif 
# done 

# for var in a b; do 
# gdal_translate -projwin  $( getCorners4Gtranslate   $OUTDIR/OR07_MalheurNF_dsm_${var}.tif  )  $MERIT/all_NA_tif.vrt    $OUTDIR/OR07_MalheurNF_MERIT_crop.tif 
# gdaldem slope -p  $OUTDIR/OR07_MalheurNF_MERIT_crop.tif     $OUTDIR/OR07_MalheurNF_MERIT_crop_slope.tif 

# gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $OUTDIR/OR07_MalheurNF_MERIT_crop_slope.tif -B $OUTDIR/OR07_MalheurNF_dsm_${var}.tif --calc="(B.astype(float) - A.astype(float))" --outfile=$OUTDIR/OR07_MalheurNF_dsm_${var}_correct.tif
# pksetmask -m   $OUTDIR/OR07_MalheurNF_dsm_${var}.tif -msknodata -9999 -nodata -9999   -i  $OUTDIR/OR07_MalheurNF_MERIT_crop.tif -o  $OUTDIR/OR07_MalheurNF_mrt_${var}.tif 
# rm -f $OUTDIR/OR07_MalheurNF_MERIT_crop.tif 
# gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9  -t_srs EPSG:4326  -s_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $OUTDIR/OR07_MalheurNF_mrt_${var}.tif   $OUTDIR/OR07_MalheurNF_mrt_${var}_wgs84.tif  -tr 0.0008333333 0.0008333333  -overwrite 
# done




module load Apps/R/3.3.2-generic

R --vanilla --no-readline -q  <<'EOF'
library(rgdal)
library(raster)
library(ggplot2)
library("gridExtra")
library("png")
library("grid")


for (zone  in c("ID09_Lloyd_","OR07_MalheurNF_") ) { 
for (var in c("a","b") ) { 
dtm   =  raster (paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/equi_crop/",zone,"dtm_",var,".tif"))
dsm   =  raster (paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/equi_crop/",zone,"dsm_",var,"_correct.tif"))
mrt   =  raster (paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/equi_crop/",zone,"mrt_",var,".tif"))

DEM      = as.data.frame( getValues(dsm))
names(DEM)[1]  <- "dsm"
DEM$dtm  = getValues(dtm)
DEM$mrt  = getValues(mrt)

coef_dtm = round(as.numeric (coefficients(lm ( DEM$mrt ~ DEM$dtm  ))), digits = 3 )
coef_dsm = round(as.numeric (coefficients(lm ( DEM$mrt ~ DEM$dsm  ))), digits = 3 )

max=(max(DEM$mrt,na.rm = TRUE))
min=(min(DEM$dtm,na.rm = TRUE))

if (var == "a" ){ 
plot = ggplot    ( data=DEM , aes(x=mrt , y=dsm  )) + geom_point(alpha=1, col='blue', size=0.03) +             
geom_point( data=DEM , aes(x=mrt , y=dtm) ,   alpha=1, col='red' , size=0.03) +                         
geom_smooth(  data=DEM , aes(x=mrt , y=dsm) ,   method='lm',formula=y~x ,col='black'  ,size=0.7  , se=FALSE ) + 
geom_smooth(  data=DEM , aes(x=mrt , y=dtm) ,   method='lm',formula=y~x ,col='brown'  ,size=0.7  , se=FALSE ) + 
xlab("MERIT DEM") + ylab("LiDAR DSM") +
annotate("text", label="LiDAR DTM", x=900, y=1800, vjust=1, hjust=1 , angle=90 , colour = "red") ) + 
theme(plot.title=element_text(size=rel(0.6) ,  hjust=0 ) ,
      axis.title.x = element_text(colour = "black") ,
      axis.title.y = element_text(colour = "blue") ,
      axis.text.x=element_text(size=rel(1.4),color='black') ,
      axis.text.y=element_text(size=rel(1.4),color='black')
)
} else {
plot = ggplot    ( data=DEM , aes(x=mrt , y=dsm  )) + geom_point(alpha=1, col='blue', size=0.03) +             
geom_point( data=DEM , aes(x=mrt , y=dtm) ,   alpha=1, col='red' , size=0.03) +                         
geom_smooth(  data=DEM , aes(x=mrt , y=dsm) ,   method='lm',formula=y~x ,col='black'  ,size=0.7  , se=FALSE ) + 
geom_smooth(  data=DEM , aes(x=mrt , y=dtm) ,   method='lm',formula=y~x ,col='brown'  ,size=0.7  , se=FALSE ) + 
xlab("MERIT DEM") + ylab("") +
theme(plot.title=element_text(size=rel(0.6) ,  hjust=0 ) ,
      axis.title.x = element_text(colour = "black") ,
      axis.title.y = element_text(colour = "black") ,
      axis.text.x=element_text(size=rel(1.4),color='black') ,
      axis.text.y=element_text(size=rel(1.4),color='black')
)
}





#  + annotate("text", x=max-100, y=min+200 , label=as.character(coef_dtm)[1]) + annotate("text", x=max, y=min+200 , label=as.character(coef_dtm)[2]) +
#     annotate("text", x=max-100, y=min+100 , label=as.character(coef_dsm)[1]) + annotate("text", x=max, y=min+100  , label=as.character(coef_dsm)[2]) 

print(coef_dtm )
print(coef_dsm )
print("asfdasdf" )

assign(paste0(zone,var,"_plt") , plot  )
}
}

satalite_a = rasterGrob ( readPNG ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/satalite_a.png"))
satalite_b = rasterGrob ( readPNG ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/satalite_b.png"))
pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/dsm-dtm_vs_merit_plot.pdf") , width=6, height=12   )
grid.arrange(satalite_a , ID09_Lloyd_a_plt,ID09_Lloyd_b_plt, satalite_b , OR07_MalheurNF_a_plt,OR07_MalheurNF_b_plt ,    layout_matrix =  rbind(c(1,1),c(2,3),c(4,4),c(5,6)))
dev.off()

EOF

gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress  -sOutputFile=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/dsm-dtm_vs_merit_plot_low.pdf /gpfs/loomis/project/fas/sbsc/ga254/dataproces/LIDAR/figure/dsm-dtm_vs_merit_plot.pdf
exit 


