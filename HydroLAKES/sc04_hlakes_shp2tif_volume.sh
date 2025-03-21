#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc04_hlakes_shp2tif_volume.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc04_hlakes_shp2tif_volume.sh.%J.err
#SBATCH --job-name=sc04_hlakes_shp2tif_volume.sh
#SBATCH --mem-per-cpu=20000M
#SBATCH --array=1-1148  ### there are 1148 teils
####SBATCH --array=440-441

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/HydroLAKES/sc04_hlakes_shp2tif_volume.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc04_hlakes_shp2tif_volume.sh

module purge
source ~/bin/gdal
#source ~/bin/pktools
source ~/bin/grass

#DIR=/home/jaime/Data/hydroLAKES/HydroLAKES_polys_v10_shp
export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

#export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

export TEILID=$SLURM_ARRAY_TASK_ID
# 440 441


### create each the teil and extract extent
#ogr2ogr -sql "SELECT * FROM Grid_Teil WHERE id=\'${ID}\'"  $DIR/shp/teil_${ID}_${YEAR}.shp $DIR/Grid_Teil.shp
#ogr2ogr -sql "SELECT * FROM all_tif_shp WHERE teil_id=${TEILID}"  /home/jaime/Data/hydroLAKES/teil_441.shp /home/jaime/Data/temp/all_tif_shp.shp

ogr2ogr -sql "SELECT * FROM all_tif_shp WHERE teil_id=${TEILID}"  $DIR/shp/teil_${TEILID}.shp $DIR/all_tif_shp.shp

#EXTENSION=$( ogrinfo /home/jaime/Data/hydroLAKES/teil_441.shp  -so -al | grep Extent | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' )

EXTENSION=$( ogrinfo $DIR/shp/teil_${TEILID}.shp  -so -al | grep Extent | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' )

echo rasterizing!!!

gdal_rasterize  -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4326 -te $EXTENSION -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -a VolArea -l HydroLAKES_polys_v10 $DIR/HydroLAKES_polys_v10_shp/HydroLAKES_polys_v10.shp $DIR/tmp/teil_${TEILID}.tif

echo running GRASS GIS

### In GRASS GIS create the raster with the cell area
grass76 -f -text -c $DIR/tmp/teil_${TEILID}.tif  -e  $DIR/grassdb/loc_${TEILID}

grass76 -f $DIR/grassdb/loc_${TEILID}/PERMANENT --exec r.external.out   directory=$DIR/tmp   format="GTiff" option="COMPRESS=DEFLATE,ZLEVEL=9"
grass76 -f $DIR/grassdb/loc_${TEILID}/PERMANENT --exec r.cell.area  output=Area_tmp_${TEILID}.tif  units=km2
grass76 -f $DIR/grassdb/loc_${TEILID}/PERMANENT --exec r.external.out -r -p


echo Multiplying

### (TotalVolumLake/TotalAreaLake) *  area_cell
gdal_calc.py --co COMPRESS=DEFLATE --co ZLEVEL=9 --type=Float32 --NoDataValue=-9999 --calc="A*B" -A $DIR/tmp/Area_tmp_${TEILID}.tif -B $DIR/tmp/teil_${TEILID}.tif --outfile=$DIR/tif/final_${TEILID}.tif --overwrite

echo Deleting temporal files

rm $DIR/shp/teil_${TEILID}.*
rm $DIR/tmp/Area_tmp_${TEILID}.tif
rm $DIR/tmp/teil_${TEILID}.tif
#rm $DIR/grassdb/loc_${TEILID}

exit
