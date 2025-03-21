#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_extractNCFD.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_extractNCFD.sh.%J.err
#SBATCH --job-name=sc02_extractNCFD.sh
#SBATCH --array=1-27


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/LCESA/sc01_wget.sh



DIR=/home/GUESTS/$USER/ost4sem/exercise/KenyaGIS/Landsat
 
file=$(ls $DIR/stack_??.vrt  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
 
filename=$(basename $file .vrt)




####   read from IGB server 1

FILES=/home/marquez/Data/ESALC/*.nc   ### create a txt file with the list of these files




















export DIRLC=/home/marquez/Data/ESALC





for YEAR in 2016 2017 2018 ;
do
	gdalwarp -of Gtiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -ot Byte -t_srs EPSG:4326 NETCDF:$DIRLC/C3S-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.1.1.nc:lccs_class $DIRLC/ESALC_${YEAR}.tif
done



for YEAR in $(seq 2005 2015) ;
do
	gdalwarp -of Gtiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -ot Byte -t_srs EPSG:4326 NETCDF:$DIRLC/ESACCI-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.0.7cds.nc:lccs_class $DIRLC/ESALC_${YEAR}.tif
done

##############################################################################


echo 2016 2017 2018 | xargs -n 1 -P 3 bash -c #$'
YEAR=$1

gdalwarp -of Gtiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -ot Byte -a_nodata 0 -te -180.0 -56.0 180.0 84 -tr 0.0027777 0.0027777 -t_srs EPSG:4326 NETCDF:$DIRLC/C3S-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.1.1.nc:lccs_class $DIRLC/temp_ESALC_${YEAR}.tif

gdalwarp -of Gtiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -ot Byte -tr 0.0027777 0.0027777 -t_srs EPSG:4326 NETCDF:$DIRLC/C3S-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.1.1.nc:lccs_class $DIRLC/temp_ESALC_${YEAR}.tif

#pkreclass -i $DIRLC/temp_ESALC_${YEAR}.tif -o $DIRLC/ESALC_${YEAR}.tif -c 210 -r 0 -c 220 -r 0 -nodata 255 -ot Byte -co COMPRESS=LZW -co ZLEVEL=9
 ' _


 echo $(seq 2005 2015) | xargs -n 1 -P 10 bash -c $'
YEAR=$1

gdalwarp -of Gtiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES -ot Byte -te -180.0000000 -56.000810394 179.9999424 83.999167206 -tr 0.002083333 0.002083333 -t_srs EPSG:4326 NETCDF:$DIRLC/ESACCI-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.0.7cds.nc:lccs_class $DIRLC/temp_ESALC_${YEAR}.tif
#pkreclass -i $DIRLC/temp_ESALC_${YEAR}.tif -o $DIRLC/ESALC_${YEAR}.tif -c 210 -r 0 -c 220 -r 0 -nodata 255 -ot Byte -co COMPRESS=LZW -co ZLEVEL=9
 ' _

rm $INDIR/temp_*.tif