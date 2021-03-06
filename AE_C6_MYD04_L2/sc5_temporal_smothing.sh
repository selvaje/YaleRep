
# for QQ  in NW NE SW SE ; do  qsub -v QQ=$QQ  /home/fas/sbsc/ga254/scripts/AE_C6_MYD04_L2/sc5_temporal_smothing.sh ; done 

# bash /home/fas/sbsc/ga254/scripts/AE_C6_MYD04_L2/sc5_temporal_smothing.sh $NW

# to prepare the dataset for testing 
# ls mean???.tif | xargs -n 1 -P 50 bash -c  $'    gdal_translate  -srcwin 2100 300 400 400 $1 ../$1  ' _ 



#PBS -S /bin/bash
#PBS -q fas_normal
#PBS -l walltime=6:00:00
#PBS -l nodes=1:ppn=8
#PBS -V
#PBS -o /scratch/fas/sbsc/ga254/stdout
#PBS -e /scratch/fas/sbsc/ga254/stderr

echo temporal interpolation 


export INDIR=/scratch/fas/sbsc/ga254/dataproces/AE_C6_MYD04_L2/integration/tif
export OUTDIR=/scratch/fas/sbsc/ga254/dataproces/AE_C6_MYD04_L2/temp_smoth
export OUTDIR_1km=/scratch/fas/sbsc/ga254/dataproces/AE_C6_MYD04_L2/temp_smoth_1km

export $QQ
# export QQ=NW

if [ $QQ = "NW"  ] ; then geostring="-180 +90 0 0" ; fi 
if [ $QQ = "NE"  ] ; then geostring="0 +90 180 0"  ; fi 
if [ $QQ = "SW"  ] ; then geostring="-180 0 0 -90" ; fi 
if [ $QQ = "SE"  ] ; then geostring="0 0 180 -90"  ; fi 

rm -f -separate $OUTDIR/output${QQ}.vrt    /tmp/output${QQ}.tif   $OUTDIR/smoth_mean_alldays${QQ}.tif  

gdalbuildvrt  -overwrite   -separate $OUTDIR/output${QQ}.vrt    $INDIR/mean???.tif   
gdal_translate -projwin   $geostring   -co COMPRESS=LZW -co ZLEVEL=9      $OUTDIR/output${QQ}.vrt   /tmp/output${QQ}.tif
pkfilter -ot  Float32 -f smooth  -interp cspline_periodic   -dz 31   -i    /tmp/output${QQ}.tif   -o    $OUTDIR/smoth_mean_alldays${QQ}.tif 

# rm -f  /tmp/output${QQ}.tif 

echo start band resampling 

seq 1 365 | xargs -n 1 -P 8  bash -c $' 

BAND=$1
gdal_translate  -b $BAND -co COMPRESS=LZW -co ZLEVEL=9    $OUTDIR/smoth_mean_alldays${QQ}.tif   $OUTDIR/smoth_mean_alldays${QQ}_band$BAND.tif 

' _ 

exit 


