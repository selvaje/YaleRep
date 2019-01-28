#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_equi_warp_wgs84_continue_90M_250M.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_equi_warp_wgs84_continue_90M_250M.sh.%J.err
#SBATCH --mem-per-cpu=2000

# warp equi7 to wgs84 for 90m and 250m, save intermediate tif in scratch then cp to project by getting the mean in case of overalliping 

# for TOPO in dev-magnitude dev-scale rough-magnitude rough-scale geom elev-stdev aspect aspect-sine aspect-cosine northness easthness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do for RESN in 90  250  ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M.sh ; done ; done 

# sbatch  --export=TOPO=dx,RESN=0.10 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M.sh
# sbatch  --export=TOPO=dx,RESN=0.25 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

P=$SLURM_CPUS_PER_TASK
export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm
export TOPO=$TOPO

if [ $RESN = "90" ]  ;  then export RES="0.00083333333333333333333333333" ; export ERES="0.10" ;  fi 
if [ $RESN = "250" ]  ; then export RES="0.00208333333333333333333333333" ; export ERES="0.25" ;  fi  
if [ $RESN = "1.00" ] ; then export RES="0.00833333333333333333333333333" ; export ERES="1.00" ;  fi     # check this resulution in case running the 1km 

export RESN
echo $RESN


if [ $TOPO != "geom" ]  ; then 

for CT in  AF AN AS EU NA OC SA ; do 
export CT 
if [ ! -f $MERIT/$TOPO/tiles/all_${CT}_tif.vrt ] ; then gdalbuildvrt  -overwrite   -srcnodata -99999  -vrtnodata -9999    $MERIT/$TOPO/tiles/all_${CT}_tif.vrt   $MERIT/$TOPO/tiles/${TOPO}_100M_MERIT_${CT}_???_???.tif ; fi 

# gdalwarp  by bilenear  each  single equi7 tile to wgs84; check if a tile is empty due to the ZONE.shp.mask 

for file in $(cat $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_TILEMERIT.txt)  ; do echo $MERIT/input_tif/$file ; done  | xargs -n 1 -P $P bash -c $'
file=$1 
filename=$(basename $file _dem.tif)
geostring=$(getCorners4Gwarp $file)

if [ $TOPO = "aspect" ] || [ $TOPO = "rough-scale" ] || [ $TOPO = "dev-scale" ]  ; then ALG=near ; else ALG=bilinear ; fi 

gdalwarp  --config GDAL_CACHEMAX 1500 -overwrite -wm 1500   -overwrite -overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -r $ALG -srcnodata -9999 -dstnodata -9999 -tr ${RES} ${RES} -te $geostring  -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $MERIT/$TOPO/tiles/all_${CT}_tif.vrt $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM${ERES}.tif  -msknodata 0 -nodata -9999 -i $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif  -o $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif
rm -f $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif

MAX=$(pkstat -max -i $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif  | awk \'{ print $2 }\'  )
if [ $MAX = "-9999"  ] ; then 
rm -f $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif 
else 
mv $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif  $SCRATCH/$TOPO/tiles/${TOPO}_${CT}_${filename}_${RESN}.tif ; rm -f  $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif
fi 
' _ 
done 


# if a tile is covered only by one zone than cp else make the mean of the 2 or 3 rasters.  
ls  $MERIT/input_tif/*_dem.tif    | xargs -n 1 -P $P  bash -c $'
file=$1 
filename=$(basename $file _dem.tif)

gdalbuildvrt  -overwrite  -separate  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $SCRATCH/$TOPO/tiles/${TOPO}_??_${filename}_${RESN}.tif
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt     | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $MERIT/${TOPO}/tiles/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start statporfile


if [ $TOPO = "aspect" ] || [ $TOPO = "rough-scale" ] || [ $TOPO = "dev-scale" ]  ; then ALG=max ; else ALG=mean ; fi 
pkstatprofile  -nodata -9999 -of GTiff -f $ALG  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -i $RAM/${TOPO}_CT_${filename}_${RESN}.vrt -o $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif
gdal_translate -a_nodata -9999    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif   $MERIT/$TOPO/tiles/${TOPO}_${RESN}M_MERIT_${filename}.tif  
rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif
fi 

' _ 

rm -f   $SCRATCH/$TOPO/tiles/*_E7_tmp_${RESN}.tif

fi 


# ###############  geom  ###########################

# gdalwarp by near  each single equi7 tile to wgs84; check if a tile is empty due to the ZONE.shp.mask 

if [  $TOPO = "geom" ]  ; then 

for CT in  AF AN AS EU NA OC SA ; do 
export CT 
if [ ! -f $MERIT/$TOPO/tiles/all_${CT}_tif.vrt ] ; then gdalbuildvrt  -srcnodata 0 -vrtnodata 0  -overwrite    $MERIT/$TOPO/tiles/all_${CT}_tif.vrt   $MERIT/$TOPO/tiles/${TOPO}_100M_MERIT_${CT}_???_???.tif ; fi 

# warp each single equi7 tile to wgs84 

for file in $(cat $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_TILEMERIT.txt)  ; do echo $MERIT/input_tif/$file ; done  | xargs -n 1 -P $P bash -c $'
file=$1 
filename=$(basename $file _dem.tif)
geostring=$(getCorners4Gwarp $file)

gdalwarp  --config GDAL_CACHEMAX 1500 -overwrite -wm 1500   -overwrite -overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -r near -srcnodata 0  -dstnodata 0 -tr ${RES} ${RES} -te $geostring  -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $MERIT/$TOPO/tiles/all_${CT}_tif.vrt $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM${ERES}.tif  -msknodata 0 -nodata 0 -i $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif  -o $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif
rm -f $RAM/${TOPO}_${CT}_${filename}_${RESN}.tif

MAX=$(pkstat -max -i $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif  | awk \'{ print $2 }\'  )
if [ $MAX = "0"  ] ; then 
rm -f $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif 
else 
mv $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif  $SCRATCH/$TOPO/tiles/${TOPO}_${CT}_${filename}_${RESN}.tif ; rm -f  $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif
fi 
' _ 
done 


# if a tile is covered only by one zone than cp else make the random selection between raster 1 or raster 2 ( or in case raster  rasters)
ls  $MERIT/input_tif/*_dem.tif    | xargs -n 1 -P $P  bash -c $'
file=$1 
filename=$(basename $file _dem.tif)
filenameG=$(basename $file _dem.tif)

gdalbuildvrt  -overwrite  -separate  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $SCRATCH/$TOPO/tiles/${TOPO}_??_${filename}_${RESN}.tif
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt     | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $MERIT/${TOPO}/tiles/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 

echo start grass selection for ${TOPO}_CT_${filename}_${RESN} 

# random raster creation to select in a random way on of the band 

gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $RAM/${TOPO}_CT_${filename}_${RESN}.tif 
rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
# cp   $RAM/${TOPO}_CT_${filename}_${RESN}.tif  $MERIT/${TOPO}/tiles/${TOPO}_${RESN}M_MERIT_${filename}_more1band.tif

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $RAM loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}.tif   

if [ $BAND -eq 2 ] ; then
r.surf.random -i output=random  min=1  max=2 --overwrite 
r.mapcalc "random_null = if( isnull(${TOPO}_CT_${filenameG}_${RESN}.1) ||  isnull(${TOPO}_CT_${filenameG}_${RESN}.2), null(), random )"    --o 
r.mapcalc " ${TOPO}_CT_${filenameG}_${RESN}_sel  = if( random_null  == 1 , ${TOPO}_CT_${filenameG}_${RESN}.1 , ${TOPO}_CT_${filenameG}_${RESN}.2)"  --o 
r.patch  input=${TOPO}_CT_${filenameG}_${RESN}_sel,${TOPO}_CT_${filenameG}_${RESN}.1,${TOPO}_CT_${filenameG}_${RESN}.2 output=${TOPO}_CT_${filenameG}_${RESN} --o
fi

if [ $BAND -eq 3 ] ; then 

# for the area with 3 overlapping 
r.surf.random -i output=random3  min=1  max=3 --overwrite 
r.mapcalc "random_null3 = if( isnull(${TOPO}_CT_${filenameG}_${RESN}.1) || isnull(${TOPO}_CT_${filenameG}_${RESN}.2) || isnull(${TOPO}_CT_${filenameG}_${RESN}.3), null(), random3)"   --o 
r.mapcalc "${TOPO}_CT_${filenameG}_${RESN}_sel3  = if( random_null3  < 2, ${TOPO}_CT_${filenameG}_${RESN}.1 , ${TOPO}_CT_${filenameG}_${RESN}.2,${TOPO}_CT_${filenameG}_${RESN}.3 )"  --o

# for the area with 2 overlapping 
r.surf.random -i output=random2  min=1  max=2 --overwrite 

r.mapcalc "random_null2a = if( isnull(${TOPO}_CT_${filenameG}_${RESN}.1) || isnull(${TOPO}_CT_${filenameG}_${RESN}.2),null(), random2)"   --o 
r.mapcalc "random_null2b = if( isnull(${TOPO}_CT_${filenameG}_${RESN}.3) || isnull(${TOPO}_CT_${filenameG}_${RESN}.2),null(), random2)"   --o 
r.mapcalc "random_null2c = if( isnull(${TOPO}_CT_${filenameG}_${RESN}.3) || isnull(${TOPO}_CT_${filenameG}_${RESN}.1),null(), random2)"   --o 

r.mapcalc "${TOPO}_CT_${filenameG}_${RESN}_sel2a  = if( random_null2a  == 1 , ${TOPO}_CT_${filenameG}_${RESN}.1, ${TOPO}_CT_${filenameG}_${RESN}.2 )"   --o
r.mapcalc "${TOPO}_CT_${filenameG}_${RESN}_sel2b  = if( random_null2b  == 1 , ${TOPO}_CT_${filenameG}_${RESN}.3, ${TOPO}_CT_${filenameG}_${RESN}.2 )"  --o
r.mapcalc "${TOPO}_CT_${filenameG}_${RESN}_sel2c  = if( random_null2c  == 1 , ${TOPO}_CT_${filenameG}_${RESN}.3, ${TOPO}_CT_${filenameG}_${RESN}.1 )"    --o
 
r.patch input=${TOPO}_CT_${filenameG}_${RESN}_sel3,${TOPO}_CT_${filenameG}_${RESN}_sel2a,${TOPO}_CT_${filenameG}_${RESN}_sel2b,${TOPO}_CT_${filenameG}_${RESN}_sel2c,${TOPO}_CT_${filenameG}_${RESN}.1,${TOPO}_CT_${filenameG}_${RESN}.2,${TOPO}_CT_${filenameG}_${RESN}.3 output=${TOPO}_CT_${filenameG}_${RESN} --o
fi

r.out.gdal -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Byte format=GTiff nodata=0 input=${TOPO}_CT_${filenameG}_${RESN} output=$MERIT/$TOPO/tiles/${TOPO}_${RESN}M_MERIT_${filenameG}.tif  --o
rm -f $RAM/${TOPO}_CT_${filenameG}_${RESN}.vrt  
rm -r $RAM/loc_${TOPO}_CT_${filenameG}_${RESN}
fi
' _ 



fi # fi del geom

# rm -f  $SCRATCH/$TOPO/tiles/${TOPO}_??_*_${RESN}.tif
