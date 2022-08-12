#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%A_%a.err
#SBATCH --job-name=sc05_downloadPoint_RFmodel_mlr3spatial.sh
#SBATCH --mem=40G
#SBATCH --array=1-41
## array=1-41

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc05_downloadPoint_RFmodel_mlr3spatial.sh

#  x 2 15 
#  y 4 15                                                                                                              remove the first row that includes only see area
# for x in $(seq 2 2 14 )  ; do for y in $(seq 4 2 14 ) ; do echo $x $(expr $x + 2 ) $y $(expr $y + 2 ) ; done ; done  | awk '{ if (NR>1) print  }'  >   $ONCHO/vector/tile_list.txt  
# 

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO
cd $ONCHO/vector

### SLURM_ARRAY_TASK_ID=

geo_string=$(head  -n  $SLURM_ARRAY_TASK_ID $ONCHO/vector/tile_list.txt   | tail  -1 )
export xmin=$( echo $geo_string | awk '{  print $1 }' ) 
export xmax=$( echo $geo_string | awk '{  print $2 }' ) 
export ymin=$( echo $geo_string | awk '{  print $3 }' ) 
export ymax=$( echo $geo_string | awk '{  print $4 }' ) 

echo geo_string  =  $xmin  $xmax $ymin $ymax
echo prediction_${xmin}_${ymin}.tif


if [ $SLURM_ARRAY_TASK_ID -eq 1  ] ; then

rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/data.RData
rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/allVar.mod.rf.txt
rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/importance_allVar.txt
rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_*_*.tif
rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/*.tif.aux.xml

module purge
module load miniconda/4.10.3
conda activate gdx_env
source  /gpfs/loomis/project/sbsc/ga254/conda_envs/gdx_env/lib/python3.1/venv/scripts/common/activate

python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_download.py NigeriaHabitatSites.gpkg ab6e7398-23cc-4aea-8a2c-a03e185de9e7 /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/NigeriaHabitatSites.gpkg

# python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_download.py "22_5.4_nga_lit_extr.csv"  eb20cbd8-46ee-42ad-901d-3af214ef651a /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/22_5.4_nga_lit_extr.csv 

python - <<EOF
import pandas as pd
df = pd.read_csv (r'22_5.4_nga_lit_extr.csv')
df = pd.DataFrame(df,  columns= ['lat','lon'] )
df = df.dropna()
df.to_csv('22_5.4_nga_lit_extr_lat_lon.txt', sep=' ')
EOF

grep -v "-" $ONCHO/vector/22_5.4_nga_lit_extr_lat_lon.txt > $ONCHO/vector/22_5.4_nga_lit_extr_lat_lon_clean.txt  # to remove "square area"

conda  deactivate
module purge
source ~/bin/gdal3

rm -f $ONCHO/vector/NigeriaHabitatSites.csv
ogr2ogr -overwrite  $ONCHO/vector/NigeriaHabitatSites.csv $ONCHO/vector/NigeriaHabitatSites.gpkg

echo "x y pa" > $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
### combine bibliography data and field work data
awk -F "," '{ gsub("\"","") ; if (NR>1) print $2 , $1 , int($4) }' $ONCHO/vector/NigeriaHabitatSites.csv >> $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
awk        '{ if (NR>1) print $3 , $2 , 1 }'         $ONCHO/vector/22_5.4_nga_lit_extr_lat_lon_clean.txt >> $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt

awk -F "," '{ if (NR>1) print $2 , $1 }'           $ONCHO/vector/NigeriaHabitatSites.csv                 >  $ONCHO/vector/NigeriaHabitatSites_x_y.txt
awk        '{ if (NR>1) print $3 , $2 }'           $ONCHO/vector/22_5.4_nga_lit_extr_lat_lon_clean.txt  >>  $ONCHO/vector/NigeriaHabitatSites_x_y.txt

rm -f $ONCHO/vector/pred_*.txt 

for var in geomorpho90m hydrography90m ; do 

gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif.vrt $(ls $ONCHO/input/$var/*.tif | grep -v -e _acc -e _msk)
BB=$(ls $ONCHO/input/$var/*.tif | grep -v -e _acc -e _msk  | wc -l )

for var1 in $( ls $ONCHO/input/$var/*.tif  | grep -v -e _acc -e _msk )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}.txt
echo "" >> $ONCHO/vector/pred_${var}.txt
gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}.txt

done 

for var in chelsa soilgrids soiltemp ; do 

gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif.vrt $(ls $ONCHO/input/$var/*_r.tif | grep -v -e _acc -e _msk)
BB=$(ls $ONCHO/input/$var/*_r.tif | grep -v -e _acc -e _msk  | wc -l )

for var1 in $( ls $ONCHO/input/$var/*_r.tif  | grep -v -e _acc -e _msk )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}.txt
echo "" >> $ONCHO/vector/pred_${var}.txt
gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}.txt
done 

var=soilgrids
gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif_acc.vrt $(ls $ONCHO/input/$var/*.tif | grep -e _acc | grep -v _r.tif  )
BB=$(ls $ONCHO/input/$var/*.tif | grep -e _acc | grep -v _r.tif | wc -l )

for var1 in $( ls $ONCHO/input/$var/*.tif  | grep -e _acc | grep -v _r.tif )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}_acc.txt
echo "" >> $ONCHO/vector/pred_${var}_acc.txt
gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif_acc.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}_acc.txt

paste -d " " $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt $ONCHO/vector/pred_*.txt |  sed  's,  , ,g' > $ONCHO/vector/x_y_pa_predictors.txt
awk '{ print $1="", $2="", $0  }' $ONCHO/vector/x_y_pa_predictors.txt |  sed  's,    ,,g'  > $ONCHO/vector/x_y_pa_predictors4R.txt

module purge
source ~/bin/gdal3
source ~/bin/pktools

rm -rf $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg
pkascii2ogr -n "PA" -ot "Real Real Integer"   -a_srs EPSG:4326 -of GPKG   -i $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt  -o $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg
##### gdal_rasterize  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte -a_nodata 255   -a "PA" -tr 0.000833333333333 0.000833333333333  -te 2 4 15 15  -a_srs EPSG:4326 $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg  $ONCHO/vector/NigeriaHabitatSites_x_y_pa.tif


module load R/4.1.0-foss-2020b

# # # see http://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/CompareRandomForestPackages.html
# # # R  --vanilla --no-readline   -q  <<'EOF'  this is not working with ranger 

# first RF for sorting the most important variables

Rscript --vanilla  -e '
library(ranger)
library(psych)

table = read.table("x_y_pa_predictors4R.txt", header = TRUE, sep = " ")
table$geom = as.factor(table$geom)

des.table = describe(table)

write.table(des.table, "stat_allVar.txt", quote = FALSE  )

mod.rf = ranger( pa ~ . , table ,   probability = TRUE  ,  classification=TRUE ,   importance="permutation")
print(mod.rf)

print(mod.rf$oob_error)

imp=as.data.frame(importance(mod.rf))
imp.s = imp[order(imp$"importance(mod.rf)",decreasing=TRUE), , drop = FALSE]

write.table(imp.s, "importance_allVar.txt", quote = FALSE  )
s.mod.rf = capture.output(mod.rf)
write.table(s.mod.rf, "allVar.mod.rf.txt", quote = FALSE , row.names = FALSE )
'

# 

IMPN=20
rm -f $ONCHO/vector/x_y_pa_*_tmp.txt
for COLNAME in  $(awk -v IMPN=$IMPN  '{if (NR>1 && NR<=IMPN) print $1  }' $ONCHO/vector/importance_allVar.txt) ; do
awk  -v COLNAME=$COLNAME ' { if (NR==1){ for (col=1;col<=NF;col++) { if ($col==COLNAME) {colprint=col; print $colprint}}} else {print $colprint }}' $ONCHO/vector/x_y_pa_predictors4R.txt  > $ONCHO/vector/x_y_pa_${COLNAME}_tmp.txt
done 

for COLNAME in  $(awk -v IMPN=$IMPN '{if (NR>1 && NR<=IMPN) print $1  }' $ONCHO/vector/importance_allVar.txt) ; do
    echo $COLNAME $(gdalinfo $ONCHO/input/*/$COLNAME.tif | grep "NoData"  | awk -F =  '{ print $2  }' )
done > $ONCHO/vector/NoData_predictors4R_select.txt

paste -d " " <(awk '{print $3}' $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt) $ONCHO/vector/x_y_pa_*_tmp.txt > $ONCHO/vector/x_y_pa_predictors4R_select.txt
rm -f $ONCHO/vector/x_y_pa_*_tmp.txt


#### module load GCCcore/11.2.0 to install rgdal
#### options(menu.graphics=FALSE) for no gui 
echo "#######################################################"
echo "############### SECOND RF #############################"
echo "#######################################################"

#### https://mlr3spatial.mlr-org.com/articles/mlr3spatial.html

# training RF and save the model for make the prediction later on 

Rscript --vanilla  -e '
library("mlr3")
library("mlr3spatial")
library("mlr3learners")
library("ranger")
library("stars")
library("terra")
library("future")

table = read.table("x_y_pa_predictors4R_select.txt", header = TRUE, sep = " ")
table$pa = as.factor(table$pa)

backend = as_data_backend(table)    # this is just table for the lerner
task = as_task_classif(backend, target = "pa")
print(task)

learner = lrn("classif.ranger" , predict_type = "prob" )    ### https://mlr3extralearners.mlr-org.com/articles/learners/list_learners.html 
learner$parallel_predict = TRUE  

print(learner)

save.image("data1.RData")
'
else 
 sleep 1000
fi ### close the first array loop 

module purge
module load netCDF/4.7.4-gompi-2020b
source ~/bin/gdal3
module load R/4.1.0-foss-2020b

echo geo_string  =  $xmin  $xmax $ymin $ymax

### make the RF prediction 

Rscript --vanilla  -e   '
library("mlr3")
library("mlr3spatial")
library("mlr3learners")
library("ranger")
library("stars")
library("terra")
library("future")

xmin <- as.numeric(Sys.getenv("xmin"))
xmax <- as.numeric(Sys.getenv("xmax"))
ymin <- as.numeric(Sys.getenv("ymin"))
ymax <- as.numeric(Sys.getenv("ymax"))

xmin
xmax
ymin
ymax

load("data1.RData")

print ("define response variable")
#### training ml 
learner$train(task)    #### define response variable 
print(learner)

print ("start the prediction")
# bb = st_bbox ( c(xmin = xmin , xmax =  xmax , ymin =  ymin, ymax =  ymax  )  , crs = 4326 ) 

for (var in names(table)[-1] ) {
print(var)
raster  = stars::read_stars (Sys.glob(paste0("../input/*/",var,".tif")  ))
# raster_crop = raster[bb] 

print(raster)
assign(paste0(var) , raster)
}
rm (raster)
gc() ; gc()

print ("make stack layer")
stack = get(names(table)[2] )
stack

for (var in names(table)[-2:-1] ) {
print(var)
stack =  c(stack,get(var))
}

print ( c(xmin, xmax  , ymin , ymax) )

extent  <- terra::ext( xmin , xmax , ymin , ymax )
extent
env=crop(terra::rast(stack),extent)

print ("env  info")
env
print ("env  str")
str(env)
 
# rm (stack)
gc() ;  gc() ;  
print ("create the table")

env_table = as.data.table(env)
colnames(env_table) = task$feature_names

str(env_table)
save.image(paste0("data2_",xmin,"_",ymin,".RData"))
env_table_pred = predict(learner, env_table , predict_type = "prob" )
env$pred = env_table_pred
terra::writeRaster (env$pred, paste0("/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_",xmin,"_",ymin,".tif"), gdal=c("COMPRESS=DEFLATE","ZLEVEL=9"), overwrite=TRUE , datatype="Float32")
save.image(paste0("data3_",xmin,"_",ymin,".RData"))

'


if [ $SLURM_ARRAY_TASK_ID -eq 41  ] ; then
sleep 2000
module purge
source ~/bin/gdal3
source ~/bin/pktools

rm -f $ONCHO/prediction/prediction_all.* $ONCHO/prediction/prediction_all_1km.*
gdalbuildvrt  $ONCHO/prediction/prediction_all.vrt $ONCHO/prediction/prediction_[0-9]*_[0-9]*.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   $ONCHO/prediction/prediction_all.vrt  $ONCHO/prediction/prediction_all.tif 

pksetmask -m $ONCHO/input/hydrography90m/accumulation.tif -co COMPRESS=DEFLATE -co ZLEVEL=9 -msknodata -2147483648 -nodata -9999 -i $ONCHO/prediction/prediction_all.tif -o $ONCHO/prediction/prediction_all_msk.tif 

cd $ONCHO/prediction/
rm -f gdaltindex $ONCHO/prediction/all_tif_shp.*
gdaltindex $ONCHO/prediction/all_tif_shp.shp  prediction_[0-9]*_[0-9]*.tif

gdal_translate -tr 0.00833333333333 0.00833333333333 -r average -co COMPRESS=DEFLATE -co ZLEVEL=9 $ONCHO/prediction/prediction_all.tif $ONCHO/prediction/prediction_all_1km.tif
pksetmask -m  ../input/geomorpho90m/slope.tif  -co COMPRESS=DEFLATE -co ZLEVEL=9   -msknodata -9999 -nodata  -9999 -i $ONCHO/prediction/prediction_all_1km.tif -o   $ONCHO/prediction/prediction_all_1km_msk.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -scale 0.344 0.966 0.01 1 $ONCHO/prediction/prediction_all_1km_msk.tif $ONCHO/prediction/prediction_all_1km_msk_s.tif
fi
