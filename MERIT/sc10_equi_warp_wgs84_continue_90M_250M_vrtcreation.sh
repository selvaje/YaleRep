#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 8:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc09_equi_warp_wgs84_continue_90M_250M.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc09_equi_warp_wgs84_continue_90M_250M.sh.%J.err
#SBATCH --mem-per-cpu=8000

# intensity exposition range variance elongation azimuth extend width 

# for TOPO in deviation multirough stdev aspect dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm tci spi convergence ; do for RESN in 0.10 0.25 ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_vrtcreation.sh ; done ; done 

# sbatch  --export=TOPO=dx,RESN=0.10 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_vrtcreation.sh
# sbatch  --export=TOPO=dx,RESN=0.25 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_vrtcreation.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

P=$SLURM_CPUS_PER_TASK
export MERIT=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/MERIT
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/EQUI7/grids
export RAM=/dev/shm
export TOPO=$TOPO

if [ $RESN = "0.10" ] ; then export RES="0.00083333333333333333333333333" ; fi 
if [ $RESN = "0.25" ] ; then export RES="0.00208333333333333333333333333" ; fi 
if [ $RESN = "1.00" ] ; then export RES="0.00833333333333333333333333333" ; fi 

export RESN

if [ $TOPO != "aspect" ]   &&  [ $TOPO != "deviation" ] &&  [ $TOPO != "multirough" ]  ; then 

if [ $RESN = "1.00" ] ; then 
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999   $RAM/${TOPO}_1KMbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   -a_nodata -9999  $RAM/${TOPO}_1KMbilinear_MERIT.vrt   $MERIT/final1km/${TOPO}_1KMbilinear_MERIT.tif
rm -f $RAM/${TOPO}_1KMbilinear_MERIT.vrt 
fi 

if [ $RESN = "0.25" ] ; then 
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999   $RAM/${TOPO}_250Mbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999 -co BIGTIFF=YES       $RAM/${TOPO}_250Mbilinear_MERIT.vrt   $MERIT/final250m/${TOPO}_250Mbilinear_MERITf.tif
gdal_translate  --config GDAL_CACHEMAX 4000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co  BLOCKYSIZE=512 -co  BLOCKXSIZE=512 -co COPY_SRC_OVERVIEWS=YES -mo CO=YES -co TILED=YES -a_nodata 0 -ot Byte -scale $RAM/${TOPO}_250Mbilinear_MERIT.vrt $MERIT/final250m/${TOPO}_250Mbilinear_MERITb.tif
rm -f $RAM/${TOPO}_250Mbilinear_MERIT.vrt 
fi 

fi 

################################################################################################################################

if [ $TOPO = "aspect"   ] ; then 

for FUN in sin cos Ew Nw ; do

if [ $FUN  = "sin" ]  ; then   FUNN=aspect-sine  ; fi 
if [ $FUN  = "cos" ]  ; then   FUNN=apect-cosine ; fi 
if [ $FUN  = "Ew"  ]  ; then   FUNN=easteness    ; fi 
if [ $FUN  = "Nw"  ]  ; then   FUNN=northness    ; fi

if [ $RESN = "1.00" ] ; then
gdalbuildvrt  -overwrite -srcnodata -9999 -vrtnodata -9999 $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${FUN}_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999  $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt   $MERIT/final1km/${FUNN}_1KMbilinear_MERIT.tif
rm -f $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt
fi

if [ $RESN = "0.25" ] ; then
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999   $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${FUN}_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999 -co BIGTIFF=YES   $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt   $MERIT/final250m/${FUNN}_250Mbilinear_MERITf.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co  BLOCKYSIZE=512 -co  BLOCKXSIZE=512 -co COPY_SRC_OVERVIEWS=YES -mo CO=YES -co TILED=YES -a_nodata 0 -ot Byte -scale $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt $MERIT/final250m/${FUNN}_250Mbilinear_MERITb.tif
rm -f $RAM/${FUNN}_250Mbilinear_MERIT.vrt
fi 

done

fi 

############################# only aspect  ####################################### 

if [ $TOPO = "aspect"   ] ; then 

if [ $RESN = "1.00" ] ; then 
gdalbuildvrt  $RAM/${TOPO}_1KMbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999  $RAM/${TOPO}_1KMbilinear_MERIT.vrt   $MERIT/final1km/${TOPO}_1KMbilinear_MERIT.tif
rm -f $RAM/${TOPO}_1KMbilinear_MERIT.vrt 
fi 

if [ $RESN = "0.25" ] ; then 
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999   $RAM/${TOPO}_250Mbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999 -co BIGTIFF=YES       $RAM/${TOPO}_250Mbilinear_MERIT.vrt   $MERIT/final250m/${TOPO}_250Mbilinear_MERITf.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co  BLOCKYSIZE=512 -co  BLOCKXSIZE=512 -co COPY_SRC_OVERVIEWS=YES -mo CO=YES -co TILED=YES -a_nodata 0 -ot Byte -scale $RAM/${TOPO}_250Mbilinear_MERIT.vrt $MERIT/final250m/${TOPO}_250Mbilinear_MERITb.tif
rm -f $RAM/${TOPO}_250Mbilinear_MERIT.vrt 
fi 

fi


#########################################################################################################


if [ $TOPO = "deviation" ] || [ $TOPO = "multirough" ]  ; then 

for FUN in mag sca ; do

if [ $TOPO = "deviation" ]   ; then   TOPON=dev ; fi 
if [ $TOPO = "multirough" ]  ; then   TOPON=rough ; fi 
if [ $FUN  = "mag" ]  ; then   FUNN=magnitude ; fi 
if [ $FUN  = "sca" ]  ; then   FUNN=scale     ; fi 

if [ $RESN = "1.00" ] ; then 
gdalbuildvrt  $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${FUN}_${RESN}.tif
gdal_translate   --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999  $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt   $MERIT/final1km/${TOPON}-${FUNN}_1KMbilinear_MERIT.tif
rm -f $RAM/${TOPO}_${FUN}_1KMbilinear_MERIT.vrt $MERIT/$TOPO/tiles/???????_E7_${FUN}_${RESN}.tif
fi 

if [ $RESN = "0.25" ] ; then 
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999   $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt  $MERIT/$TOPO/tiles/???????_E7_${FUN}_${RESN}.tif
gdal_translate  --config GDAL_CACHEMAX 4000   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata -9999 -co BIGTIFF=YES       $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt   $MERIT/final250m/${TOPON}-${FUNN}_250Mbilinear_MERITf.tif
gdal_translate  --config GDAL_CACHEMAX 4000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co  BLOCKYSIZE=512 -co  BLOCKXSIZE=512 -co COPY_SRC_OVERVIEWS=YES -mo CO=YES -co TILED=YES -a_nodata 0 -ot Byte -scale $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt $MERIT/final250m/${TOPON}-${FUNN}_250Mbilinear_MERITb.tif
rm -f $RAM/${TOPO}_${FUN}_250Mbilinear_MERIT.vrt 
fi 


done
fi


