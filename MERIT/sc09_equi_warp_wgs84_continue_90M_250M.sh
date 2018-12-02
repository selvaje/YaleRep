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

# for TOPO in dev-magnitute dev-scale rough-magnitute rough-scale elev-stdev aspect aspect-sine aspect-cosine northness easthness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do for RESN in 90 250  ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M.sh ; done ; done 

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


if [ $TOPO != "geom" ]  ; then 

for CT in  AF AN AS EU NA OC SA ; do 
export CT 
if [ ! -f $MERIT/$TOPO/tiles/all_${CT}_tif.vrt ] ; then gdalbuildvrt  -overwrite   -srcnodata -99999  -vrtnodata -9999    $MERIT/$TOPO/tiles/all_${CT}_tif.vrt   $MERIT/$TOPO/tiles/${TOPO}_100M_MERIT_${CT}_???_???.tif ; fi 

# warp each single equi7 tile to wgs84 

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


# cp to final dir  or get mean of the overlapping tiles 
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


###############  geom  ###########################

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
if [ $MAX = "-9999"  ] ; then 
rm -f $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif 
else 
mv $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif  $SCRATCH/$TOPO/tiles/${TOPO}_${CT}_${filename}_${RESN}.tif ; rm -f  $RAM/${TOPO}_${CT}_${filename}_msk_${RESN}.tif
fi 
' _ 
done 


# cp to final dir  or get mean of the overlapping tiles 
ls  $MERIT/input_tif/*_dem.tif    | xargs -n 1 -P $P  bash -c $'
file=$1 
filename=$(basename $file _dem.tif)

gdalbuildvrt  -overwrite  -separate  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $SCRATCH/$TOPO/tiles/${TOPO}_??_${filename}_${RESN}.tif
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt     | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $MERIT/${TOPO}/tiles/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start statporfile
pkstatprofile -a_nodata 0 -of GTiff  -f max -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -i $RAM/${TOPO}_CT_${filename}_${RESN}.vrt -o $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif
gdal_translate -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif   $MERIT/$TOPO/tiles/${TOPO}_${RESN}M_MERIT_${filename}.tif  
rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $SCRATCH/$TOPO/tiles/${filename}_E7_tmp_${RESN}.tif
fi 

' _ 

rm -f   $SCRATCH/$TOPO/tiles/*_E7_tmp_${RESN}.tif

fi 

rm -f  $SCRATCH/$TOPO/tiles/${TOPO}_??_*_${RESN}.tif
