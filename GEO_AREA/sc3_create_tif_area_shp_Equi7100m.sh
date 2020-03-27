#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6  -N 1  
#SBATCH --array=1-70
#SBATCH -t 4:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc3_create_tif_area_shp_Equi7100m.sh%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc3_create_tif_area_shp_Equi7100m.sh%A_%a.out
#SBATCH --job-name=sc3_create_tif_area_shp_Equi7100m.sh
#SBATCH --mem-per-cpu=4000

# converte una striscia shp in determinata projection e calcola l'area e riproduce la colonna n volte. 
 
#     SR-ORG:28: lambert azimutha equal area
#     SR-ORG:6842: MODIS Sinusoidal
#     SR-ORG:6965: MODIS Sinusoidal
#     SR-ORG:6974: MODIS Sinusoidal  # according to Adam this is the modis projection


# create a tif whith one column 
# una colonna di numeri 

### sbatch /gpfs/loomis/home.grace/sbsc/ga254/scripts/GEO_AREA/sc3_create_tif_area_shp_Equi7100m.sh

  
source ~/bin/gdal
source ~/bin/pktools 

export OUT=/gpfs/loomis/project/sbsc/ga254/dataproces/GEO_AREA/area_tif/equi7100m
export  IN=/gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO/elv_equi7/EU
# SLURM_ARRAY_TASK_ID=1
export file=$(ls /gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO/elv_equi7/EU/*.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )
export filename=$(basename $file .tif) 

xllcorner=$( getCorners4Gtranslate $file  | awk '{  print int ($1) }' )
yllcorner=$( getCorners4Gtranslate $file  | awk '{  print int ($4) }' )

echo "ncols        1000"                           > $OUT/$filename.asc
echo "nrows        6000"                          >> $OUT/$filename.asc
echo "xllcorner    $xllcorner"                    >> $OUT/$filename.asc
echo "yllcorner    $yllcorner"                    >> $OUT/$filename.asc
echo "cellsize     100"                           >> $OUT/$filename.asc

awk ' BEGIN {  
for (row=1 ; row<=6000 ; row++)  { 
     for (col=1 ; col<=1000 ; col++) { 
         printf ("%i " ,  col+(row-1)*6000  ) } ; printf ("\n")  }}' >> $OUT/$filename.asc

gdal_translate --config GDAL_CACHEMAX 10000  -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -a_srs /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/EU/PROJ/EQUI7_V13_EU_PROJ_TILE_T6.prj  $OUT/$filename.asc  $OUT/${filename}-IDcol_A.tif 

## shift 
echo B 1 C 2 D 3 F 4 G 5 | xargs -n 2 -P 6 bash -c $'
LET=$1
N=$2
gdal_translate --config GDAL_CACHEMAX 3000  -a_ullr $( getCorners4Gtranslate $OUT/${filename}-IDcol_A.tif   | awk -v N=$N  \'{ print $1+(100000*N) , $2 , $3 + (100000*N) , $4   }\' ) -ot UInt32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -a_srs /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/EU/PROJ/EQUI7_V13_EU_PROJ_TILE_T6.prj  $OUT/${filename}-IDcol_A.tif  $OUT/${filename}-IDcol_$LET.tif 
' _ 


# transform to shp and calculate the area

echo A B C D F G  | xargs -n 1 -P 6 bash -c $' 

pos=$1
rm  -f  $OUT/${filename}-IDcol_${pos}_shp.{shp,dbf,prj,shx}
gdal_polygonize.py -f  "ESRI Shapefile" $OUT/${filename}-IDcol_${pos}.tif $OUT/${filename}-IDcol_${pos}_shp.shp


##  change projection and calculate the area

prj=6965
rm  -f $OUT/${filename}-IDcol_${pos}_shp_proj$prj.*
echo change proj wgs84 to $prj
ogr2ogr -t_srs $OUT/../../prj/$prj.prj $OUT/${filename}-IDcol_${pos}_shp_proj$prj.shp   $OUT/${filename}-IDcol_${pos}_shp.shp 
~/scripts/general/addattr-area.py   $OUT/${filename}-IDcol_${pos}_shp_proj$prj.shp Area 
ogrinfo -al -geom=NO  $OUT/${filename}-IDcol_${pos}_shp_proj$prj.shp  | grep -e " DN " -e " Area " | awk  \'{if ($1=="DN") { printf("%s ", $4)} else {printf("%s\\n", $4) }}\' >  $OUT/${filename}-IDcol_${pos}_ID_area.txt

pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  -ot Float32  -code  $OUT/${filename}-IDcol_${pos}_ID_area.txt     -i  $OUT/${filename}-IDcol_${pos}.tif  -o $OUT/${filename}_${pos}_area.tif 
rm -f $OUT/${filename}-IDcol_${pos}_ID_area.txt $OUT/${filename}-IDcol_${pos}_shp_proj$prj.* 
' _ 

gdalbuildvrt $OUT/${filename}_area.vrt $OUT/${filename}_A_area.tif $OUT/${filename}_B_area.tif  $OUT/${filename}_C_area.tif  $OUT/${filename}_D_area.tif $OUT/${filename}_F_area.tif $OUT/${filename}_G_area.tif 
gdal_translate --config GDAL_CACHEMAX 10000  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES $OUT/${filename}_area.vrt $OUT/${filename}_area.tif 

exit 
