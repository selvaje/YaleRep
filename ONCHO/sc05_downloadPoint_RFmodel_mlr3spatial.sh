#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_downloadPoint_RFmodel_mlr3spatial.sh.%J.err
#SBATCH --job-name=sc05_downloadPoint_RFmodel_mlr3spatial.sh
#SBATCH --mem=400G

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc05_downloadPoint_RFmodel_mlr3spatial.sh

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO
cd $ONCHO/vector

# module purge
# module load miniconda/4.10.3
# conda activate gdx_env

# python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_download.py NigeriaHabitatSites.gpkg ab6e7398-23cc-4aea-8a2c-a03e185de9e7 /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/NigeriaHabitatSites.gpkg

# conda  deactivate

# source ~/bin/gdal3

# rm $ONCHO/vector/NigeriaHabitatSites.csv
# ogr2ogr -overwrite  $ONCHO/vector/NigeriaHabitatSites.csv $ONCHO/vector/NigeriaHabitatSites.gpkg

# echo "x y pa" > $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
# awk -F "," '{ gsub("\"","") ; if (NR>1) print $2 , $1 , int($4) }' $ONCHO/vector/NigeriaHabitatSites.csv >> $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
# awk -F "," '{ if (NR>1) print $2 , $1 }'           $ONCHO/vector/NigeriaHabitatSites.csv >  $ONCHO/vector/NigeriaHabitatSites_x_y.txt

# for var in geomorpho90m hydrography90m ; do 

# gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif.vrt $(ls $ONCHO/input/$var/*.tif | grep -v -e _acc -e _msk)
# BB=$(ls $ONCHO/input/$var/*.tif | grep -v -e _acc -e _msk  | wc -l )

# for var1 in $( ls $ONCHO/input/$var/*.tif  | grep -v -e _acc -e _msk )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}.txt
# echo "" >> $ONCHO/vector/pred_${var}.txt
# gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}.txt

# done 

# for var in chelsa soilgrids soiltemp ; do 

# gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif.vrt $(ls $ONCHO/input/$var/*_r.tif | grep -v -e _acc -e _msk)
# BB=$(ls $ONCHO/input/$var/*_r.tif | grep -v -e _acc -e _msk  | wc -l )

# for var1 in $( ls $ONCHO/input/$var/*_r.tif  | grep -v -e _acc -e _msk )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}.txt
# echo "" >> $ONCHO/vector/pred_${var}.txt
# gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}.txt
# done 

# var=soilgrids
# gdalbuildvrt -separate  -overwrite $ONCHO/input/$var/all_tif_acc.vrt $(ls $ONCHO/input/$var/*.tif | grep -e _acc | grep -v _r.tif  )
# BB=$(ls $ONCHO/input/$var/*.tif | grep -e _acc | grep -v _r.tif | wc -l )

# for var1 in $( ls $ONCHO/input/$var/*.tif  | grep -e _acc | grep -v _r.tif )  ; do echo -n $(basename  $var1 .tif)" " ; done > $ONCHO/vector/pred_${var}_acc.txt
# echo "" >> $ONCHO/vector/pred_${var}_acc.txt
# gdallocationinfo -geoloc -wgs84 -valonly $ONCHO/input/$var/all_tif_acc.vrt < $ONCHO/vector/NigeriaHabitatSites_x_y.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' >> $ONCHO/vector/pred_${var}_acc.txt

# paste -d " " $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt $ONCHO/vector/pred_*.txt |  sed  's,  , ,g' > $ONCHO/vector/x_y_pa_predictors.txt
# awk '{ print $1="", $2="", $0  }' $ONCHO/vector/x_y_pa_predictors.txt |  sed  's,    ,,g'  > $ONCHO/vector/x_y_pa_predictors4R.txt

module purge
source ~/bin/gdal3
source ~/bin/pktools

rm -rf $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg
pkascii2ogr -n "PA" -ot "Real Real Integer"   -a_srs EPSG:4326 -of GPKG   -i $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt  -o $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg
gdal_rasterize  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte -a_nodata 255   -a "PA" -tr 0.000833333333333 0.000833333333333  -te 2 4 15 15  -a_srs EPSG:4326 $ONCHO/vector/NigeriaHabitatSites_x_y_pa.gpkg  $ONCHO/vector/NigeriaHabitatSites_x_y_pa.tif


module load R/4.1.0-foss-2020b
## see http://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/CompareRandomForestPackages.html
# R  --vanilla --no-readline   -q  <<'EOF'  this is not working with ranger 

# Rscript --vanilla  -e '
# library(ranger)

# table = read.table("x_y_pa_predictors4R.txt", header = TRUE, sep = " ")
# table$geom = as.factor(table$geom)

# mod.rf = ranger( pa ~ . , table ,  importance="impurity")
# print(mod.rf)
# imp=as.data.frame(importance(mod.rf))
# imp.s = imp[order(imp$"importance(mod.rf)",decreasing=TRUE), , drop = FALSE]

# write.table(imp.s, "importance_allVar.txt", quote = FALSE  )
# s.mod.rf = capture.output(mod.rf)
# write.table(s.mod.rf, "allVar.mod.rf.txt", quote = FALSE , row.names = FALSE )
# ' 


# IMPN=20
# rm -f $ONCHO/vector/x_y_pa_*_tmp.txt
# for COLNAME in  $(awk -v IMPN=$IMPN  '{if (NR>1 && NR<=IMPN) print $1  }' $ONCHO/vector/importance_allVar.txt) ; do
# awk  -v COLNAME=$COLNAME ' { if (NR==1){ for (col=1;col<=NF;col++) { if ($col==COLNAME) {colprint=col; print $colprint}}} else {print $colprint }}' $ONCHO/vector/x_y_pa_predictors4R.txt  > $ONCHO/vector/x_y_pa_${COLNAME}_tmp.txt
# done 

# for COLNAME in  $(awk -v IMPN=$IMPN '{if (NR>1 && NR<=IMPN) print $1  }' $ONCHO/vector/importance_allVar.txt) ; do
#     echo $COLNAME $(gdalinfo $ONCHO/input/*/$COLNAME.tif | grep "NoData"  | awk -F =  '{ print $2  }' )
# done > $ONCHO/vector/NoData_predictors4R_select.txt

# paste -d " " <(awk '{print $3}' $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt) $ONCHO/vector/x_y_pa_*_tmp.txt > $ONCHO/vector/x_y_pa_predictors4R_select.txt
# rm -f $ONCHO/vector/x_y_pa_*_tmp.txt


#### module load GCCcore/11.2.0 to install rgdal
#### options(menu.graphics=FALSE) for no gui 
echo "#######################################################"
echo "############### SECOND RF #############################"
echo "#######################################################"

#### https://mlr3spatial.mlr-org.com/articles/mlr3spatial.html


Rscript --vanilla  -e '
library("mlr3")
library("mlr3spatial")
library("mlr3learners")
library("ranger")
library("stars")
library("terra")
library("future")

table = read.table("x_y_pa_predictors4R_select.txt", header = TRUE, sep = " ")

backend = as_data_backend(table)
task = as_task_regr(backend, target = "pa")
learner = lrn("regr.ranger")    ### https://mlr3extralearners.mlr-org.com/articles/learners/list_learners.html 
learner$parallel_predict = TRUE  

#### training ml 
learner$train(task)    #### define respose variable 
print(learner)

print ("start the prediction")

for (var in names(table)[-1] ) {
print(var)
raster  = stars::read_stars (Sys.glob(paste0("../input/*/",var,".tif")  ) )
print(raster)
assign(paste0(var) , raster )
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

env=rast(stack)
env 
extent  <- ext( 10, 14, 10, 14 )
env_crop = crop (env, extent)
env_crop_table = as.data.table(env_crop)

colnames(env_crop_table) = task$feature_names

str(env_crop_table)

env_crop_table_pred = predict(learner, env_crop_table)

env_crop$pred = env_crop_table_pred
terra::writeRaster (env_crop$pred , "/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_largeM.tif"   , gdal=c("COMPRESS=DEFLATE","ZLEVEL=9"), overwrite=TRUE , datatype="Float32")

save.image("data.Rdata")

'
