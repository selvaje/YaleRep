
# cd /lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/tif
# wget -i /lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/treecover2000.txt


# for file in /lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/tif/Hansen_GFC2013_treecover2000_*.tif ; do  qsub -v file=$file /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/GFC2013/sc1_aggregation_treecover.sh  ; done 

# for file in /lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/tif/Hansen_GFC2013_treecover2000_*.tif ; do  bash /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/GFC2013/sc1_aggregation_treecover.sh  $file  ; done 



#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=1gb
#PBS -l walltime=0:20:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr

# file=$1

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Libraries/OSGEO/1.10.0

filename=$(basename $file .tif)

INDIR=/lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/tif
OUTDIR=/lustre0/scratch/ga254/dem_bj/GFC2013/treecover2000/tif_1km

geo_string=$(getCorners4Gtranslate  $file)
ulx=$(echo $geo_string  | awk '{ print  sprintf("%.0f", $1 )}')  # round the number to rounded cordinates
uly=$(echo $geo_string  | awk '{ print  sprintf("%.0f", $2 )}')
lrx=$(echo $geo_string  | awk '{ print  sprintf("%.0f", $3 )}')
lry=$(echo $geo_string  | awk '{ print  sprintf("%.0f", $4 )}')


# soutest tile smoler
if [ ${filename:29:3} = '50S' ] ; then  ysize=25200 ; else ysize=36000 ; fi

gdal_translate -srcwin 0 0 36000 $ysize  -a_ullr  $ulx $uly $lrx $lry   -co COMPRESS=LZW -co ZLEVEL=9 $INDIR/$filename.tif  $OUTDIR/tmp_$filename.tif 

pkfilter    -co COMPRESS=LZW -ot  Float32    -dx 30 -dy 30   -f median  -d 30  -i  $OUTDIR/tmp_$filename.tif  -o  $OUTDIR/1km_tmp_$filename.tif  
gdal_calc.py  -A $OUTDIR/1km_tmp_$filename.tif     --calc="(A * 100 )" --co=COMPRESS=LZW  --co=ZLEVEL=9    --overwrite  --outfile  $OUTDIR/1km_tmp2_$filename.tif  
gdal_translate -ot UInt16  -co COMPRESS=LZW -co ZLEVEL=9 $OUTDIR/1km_tmp2_$filename.tif   $OUTDIR/1km_md_$filename.tif  

pkfilter    -co COMPRESS=LZW -ot  Float32    -dx 30 -dy 30   -f mean  -d 30  -i  $OUTDIR/tmp_$filename.tif  -o  $OUTDIR/1km_tmp_$filename.tif  
gdal_calc.py  -A $OUTDIR/1km_tmp_$filename.tif     --calc="(A * 100 )" --co=COMPRESS=LZW  --co=ZLEVEL=9    --overwrite  --outfile  $OUTDIR/1km_tmp2_$filename.tif  
gdal_translate -ot UInt16  -co COMPRESS=LZW -co ZLEVEL=9 $OUTDIR/1km_tmp2_$filename.tif   $OUTDIR/1km_mn_$filename.tif  
rm  $OUTDIR/tmp_$filename.tif    $OUTDIR/1km_tmp_$filename.tif   $OUTDIR/1km_tmp2_$filename.tif  



