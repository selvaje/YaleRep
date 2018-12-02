#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_flow1k_vs_grwl_cortable.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_flow1k_vs_grwl_cortable.sh.%A.%a.err
#SBATCH --job-name=sc21_flow1k_vs_grwl_grwlarea.sh
#SBATCH --mem-per-cpu=10000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc21_flow1k_vs_grwl_cortable.sh



   DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO
 GRWL=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL
AREAK=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/area_1km
 ARC1=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/1arc-sec-Area_prj6965
 


# gdalbuildvrt  -srcnodata 0  -vrtnodata 0      $AREAK/gwrl_area1km.vrt   $AREAK/*.tif 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND    $AREAK/gwrl_area1km.vrt   $AREAK/gwrl_area1km.tif

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate  $DIR/global_prediction/map_pred_NO3_mask.tif  )  $AREAK/gwrl_area1km.tif $GRWL/gwrl_area1km_crop.tif 

# pksetmask -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/global_prediction/map_pred_NO3_mask.tif -msknodata -1 -nodata -1 -i $GRWL/gwrl_area1km_crop.tif   -o  $GRWL/gwrl_area1km_crop_msk.tif 
# gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 80000 -of XYZ   $GRWL/gwrl_area1km_crop_msk.tif   $GRWL/gwrl_area1km_crop_msk.txt 
# awk ' { if($3 >= 0 ) print $3  }'  $GRWL/gwrl_area1km_crop_msk.txt   >  $GRWL/gwrl_area1km_crop_msk_clean.txt
# rm $GRWL/../gwrl_area1km_crop_msk.tif $GRWL/../gwrl_area1km_crop_msk.txt 

# paste /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/FLO1K/FLO1K.ts.1960.2015.qav_mean_clean.txt  $GRWL/gwrl_area1km_crop_msk_clean.txt > $GRWL/flow_gwrl.txt 
#  awk '{  if ($1 != 0 ) { if ($2 != 0) { print }  } }' $GRWL/flow_gwrl.txt   > $GRWL/flow_gwrl_no0.txt 


module load Apps/R/3.3.2-generic

R --vanilla --no-readline   -q  <<EOF

library(ggplot2)
table=read.table("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/flow_gwrl_no0.txt")
colnames(table)[1] = "Q"  # FLO1K
colnames(table)[2] = "W"  # GRWL 


# lm = lm(  log(table$W) ~  log(table$Q)) 

# y <- log(table$W) 
# x <- log(table$Q)

# mod <- nls(y ~ exp(a + b * x), start = list(a = 0, b = 0))
#  geom_smooth(method = "lm", se = FALSE , color = "black" , formula=y ~ exp(a + b * x^2)  )  +

lm = lm(  x ~ y) 
df <- data.frame(x = x, y = y,
  d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
p <- ggplot( data = df   , aes(x = x , y = y)) + 
    geom_point(aes(x, y, col = d), size = 0.4) +
    scale_color_identity() +
    labs(x = "log(Q-FLO1K) (m3/s)")  + 
    labs(y = "log(SA-GRWL) (m)")  + 
    theme_bw()
# print(p)
ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/Q_FLO1K_vs_SA_GRWL.png")

EOF
