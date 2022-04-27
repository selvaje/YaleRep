#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_downloadPoint_RFmodel.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_downloadPoint_RFmodel.sh.%J.err
#SBATCH --job-name=sc05_downloadPoint_RFmodel.sh
#SBATCH --mem=200G

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc05_downloadPoint_RFmodel_rasterRF.sh

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO
cd $ONCHO/vector

module purge
module load miniconda/4.10.3
conda activate gdx_env

python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_download.py NigeriaHabitatSites.gpkg ab6e7398-23cc-4aea-8a2c-a03e185de9e7 /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/vector/NigeriaHabitatSites.gpkg

conda  deactivate

source ~/bin/gdal3

rm $ONCHO/vector/NigeriaHabitatSites.csv
ogr2ogr -overwrite  $ONCHO/vector/NigeriaHabitatSites.csv $ONCHO/vector/NigeriaHabitatSites.gpkg

echo "x y pa" > $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
awk -F "," '{ gsub("\"","") ; if (NR>1) print $2 , $1 , int($4) }' $ONCHO/vector/NigeriaHabitatSites.csv >> $ONCHO/vector/NigeriaHabitatSites_x_y_pa.txt
awk -F "," '{ if (NR>1) print $2 , $1 }'           $ONCHO/vector/NigeriaHabitatSites.csv >  $ONCHO/vector/NigeriaHabitatSites_x_y.txt

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
module load R/4.1.0-foss-2020b
## see http://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/CompareRandomForestPackages.html
# R  --vanilla --no-readline   -q  <<'EOF'  this is not working with ranger 

Rscript --vanilla  -e '
library(randomForest)
table = read.table("x_y_pa_predictors4R.txt", header = TRUE, sep = " ")
table$geom = as.factor(table$geom)

mod.rf = randomForest( pa ~ . , table , importance=TRUE)
print(mod.rf)
imp=as.data.frame(importance(mod.rf))
imp.s = imp[order(imp$"%IncMSE",decreasing=TRUE), , drop = FALSE]

write.table(imp.s, "importance_allVar.txt", quote = FALSE  )
s.mod.rf = capture.output(mod.rf)
write.table(s.mod.rf, "allVar.mod.rf.txt", quote = FALSE , row.names = FALSE )
'

IMPN=17
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


Rscript --vanilla  -e '
library(raster)
library(randomForest)
table = read.table("x_y_pa_predictors4R_select.txt", header = TRUE, sep = " ")
NoData = read.table("NoData_predictors4R_select.txt", header = FALSE, sep = " ")

mod.rf = randomForest(pa ~ ., table ,  keep.forest=TRUE, importance=TRUE) 
print(mod.rf)   
imp=as.data.frame(importance(mod.rf))  
imp.s = imp[order(imp$"%IncMSE",decreasing=TRUE), , drop = FALSE] 

write.table(imp.s, "importance_selVar.txt", quote = FALSE  )
s.mod.rf = capture.output(mod.rf)
write.table(s.mod.rf, "selVar.mod.rf.txt", quote = FALSE , row.names = FALSE )

print ("start the prediction")


for (var in names(table)[-1] ) {
print(var)
raster  = raster (Sys.glob(paste0("../input/*/",var,".tif")))
RNoData = NoData[NoData$V1 == var , 2 ]
NAvalue(raster) = RNoData
assign(paste0(var) , raster )
}
rm(raster)

env = get(names(table)[2])

for (var in names(table)[-1:-2] ) {
env = stack(env,get(var))
}

env

pred.rf.resp  <- raster::predict(env,mod.rf) 
pred.rf.resp
writeRaster(pred.rf.resp,"selVar_mod_rf.tif","GTiff", overwrite=TRUE)
save.image("data.Rdata")
'

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 selVar_mod_rf.tif  selVar_mod_rfC.tif
