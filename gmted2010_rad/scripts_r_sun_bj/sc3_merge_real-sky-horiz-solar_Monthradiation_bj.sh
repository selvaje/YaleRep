# mosaic the tile and create a stak layer 
# needs to be impruved with the data type; now keep as floting. 
# reflect in caso di slope=0 reflectance 0 quindi non calcolata 
# for DIR in  beam  diff  glob  ; do bash  /mnt/data2/scratch/GMTED2010/scripts/sc3_merge_real-sky-horiz-solar_Monthradiation.sh  $DIR ; done 

# for DIR in  beam  diff  glob   ; do  qsub -v DIR=$DIR /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_rad/scripts_r_sun_bj/sc3_merge_real-sky-horiz-solar_Monthradiation_bj.sh  ; done

#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=16gb
#PBS -l walltime=4:00:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr


# load moduels 

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
# module load Tools/PKTOOLS/2.4.2   # exclued to load the pktools from the $HOME/bin
module load Libraries/OSGEO/1.10.0
module load Libraries/GSL
module load Libraries/ARMADILLO


export DIR=${DIR}
export INDIR=/lustre0/scratch/ga254/dem_bj/SOLAR/radiation/${DIR}_rad
export OUTDIR=/lustre0/scratch/ga254/dem_bj/SOLAR/radiation/${DIR}_rad/


seq 1 12 | xargs -n 1  -P  12 bash -c $' 
month=$1

rm -f  $OUTDIR/${DIR}_Hrad_month${month}.tif  
gdal_merge.py -ul_lr -172 75  -66  23.5  -co BIGTIFF=YES  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    $INDIR/${DIR}_Hrad_month${month}_?_?.tif  -o  /tmp/${DIR}_Hrad_month${month}.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    /tmp/${DIR}_Hrad_month${month}.tif    $OUTDIR/${DIR}_Hrad_month${month}.tif 
rm -f /tmp/${DIR}_Hrad_month${month}.tif 

rm -f  $OUTDIR/${DIR}_HradC_month${month}.tif  
gdal_merge.py -ul_lr -172 75  -66  23.5  -co BIGTIFF=YES  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    $INDIR/${DIR}_HradC_month${month}_?_?.tif  -o  /tmp/${DIR}_HradC_month${month}.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    /tmp/${DIR}_HradC_month${month}.tif    $OUTDIR/${DIR}_HradC_month${month}.tif 
rm -f /tmp/${DIR}_HradC_month${month}.tif 

rm -f  $OUTDIR/${DIR}_HradA_month${month}.tif  
gdal_merge.py -ul_lr -172 75  -66  23.5  -co BIGTIFF=YES  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    $INDIR/${DIR}_HradA_month${month}_?_?.tif  -o  /tmp/${DIR}_HradA_month${month}.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    /tmp/${DIR}_HradA_month${month}.tif    $OUTDIR/${DIR}_HradA_month${month}.tif 
rm -f /tmp/${DIR}_HradA_month${month}.tif 


rm -f  $OUTDIR/${DIR}_HradA2_month${month}.tif  
gdal_merge.py -ul_lr -172 75  -66  23.5  -co BIGTIFF=YES  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    $INDIR/${DIR}_HradA2_month${month}_?_?.tif  -o  /tmp/${DIR}_HradA2_month${month}.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    /tmp/${DIR}_HradA2_month${month}.tif    $OUTDIR/${DIR}_HradA2_month${month}.tif 
rm -f /tmp/${DIR}_HradA2_month${month}.tif 



rm -f  $OUTDIR/${DIR}_HradCA_month${month}.tif  
gdal_merge.py -ul_lr -172 75  -66  23.5  -co BIGTIFF=YES  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    $INDIR/${DIR}_HradCA_month${month}_?_?.tif  -o  /tmp/${DIR}_HradCA_month${month}.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  -ot Int16    /tmp/${DIR}_HradCA_month${month}.tif    $OUTDIR/${DIR}_HradCA_month${month}.tif 
rm -f /tmp/${DIR}_HradCA_month${month}.tif 


' _ 

rm -f $OUTDIR/${DIR}_Hrad_months.tif 
gdal_merge.py  -separate  -co  COMPRESS=LZW -co ZLEVEL=9 -co BIGTIFF=YES -ot Int16  $OUTDIR/${DIR}_Hrad_month[1-9].tif  $OUTDIR/${DIR}_Hrad_month1[0-2].tif   -o  $OUTDIR/${DIR}_Hrad_months.tif

gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  $OUTDIR/${DIR}_Hrad_months.tif $OUTDIR/${DIR}_Hrad_months2.tif 
mv $OUTDIR/${DIR}_Hrad_months2.tif  $OUTDIR/${DIR}_Hrad_months.tif 

rm -f $OUTDIR/${DIR}_HradC_months.tif 
gdal_merge.py  -separate  -co  COMPRESS=LZW -co ZLEVEL=9 -co BIGTIFF=YES -ot Int16  $OUTDIR/${DIR}_HradC_month[1-9].tif  $OUTDIR/${DIR}_HradC_month1[0-2].tif   -o  $OUTDIR/${DIR}_HradC_months.tif

gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  $OUTDIR/${DIR}_HradC_months.tif $OUTDIR/${DIR}_HradC_months2.tif 
mv $OUTDIR/${DIR}_HradC_months2.tif  $OUTDIR/${DIR}_HradC_months.tif 

rm -f $OUTDIR/${DIR}_HradA_months.tif 
gdal_merge.py  -separate  -co  COMPRESS=LZW -co ZLEVEL=9 -co BIGTIFF=YES -ot Int16  $OUTDIR/${DIR}_HradA_month[1-9].tif  $OUTDIR/${DIR}_HradA_month1[0-2].tif   -o  $OUTDIR/${DIR}_HradA_months.tif

rm -f $OUTDIR/${DIR}_HradA2_months.tif 
gdal_merge.py  -separate  -co  COMPRESS=LZW -co ZLEVEL=9 -co BIGTIFF=YES -ot Int16  $OUTDIR/${DIR}_HradA2_month[1-9].tif  $OUTDIR/${DIR}_HradA2_month1[0-2].tif   -o  $OUTDIR/${DIR}_HradA2_months.tif

gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  $OUTDIR/${DIR}_HradA_months.tif $OUTDIR/${DIR}_HradA_months2.tif 
mv $OUTDIR/${DIR}_HradA_months2.tif  $OUTDIR/${DIR}_HradA_months.tif 

rm -f $OUTDIR/${DIR}_HradCA_months.tif 
gdal_merge.py  -separate  -co  COMPRESS=LZW -co ZLEVEL=9 -co BIGTIFF=YES -ot Int16  $OUTDIR/${DIR}_HradCA_month[1-9].tif  $OUTDIR/${DIR}_HradCA_month1[0-2].tif   -o  $OUTDIR/${DIR}_HradCA_months.tif

gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9  $OUTDIR/${DIR}_HradCA_months.tif $OUTDIR/${DIR}_HradCA_months2.tif 
mv $OUTDIR/${DIR}_HradCA_months2.tif  $OUTDIR/${DIR}_HradCA_months.tif 
