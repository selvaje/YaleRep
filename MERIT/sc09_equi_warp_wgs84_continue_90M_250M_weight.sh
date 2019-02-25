#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 12  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_equi_warp_wgs84_continue_90M_250M_weight.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_equi_warp_wgs84_continue_90M_250M_weight.sh.%J.err
#SBATCH --mem-per-cpu=2000

ulimit -c 0

# warp equi7 to wgs84 for 90m and 250m, save intermediate tif in scratch then cp to project by getting the mean in case of overalliping 

# for TOPO in dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness easthness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do for RESN in 90  250  ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_weight.sh ; done ; done 

# sbatch  --export=TOPO=dx,RESN=90 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_weight.sh
# sbatch  --export=TOPO=dx,RESN=250  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_90M_250M_weight.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

P=$SLURM_CPUS_PER_TASK
export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export EQUI_AD=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids_adjust
export EQUI_EN=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids_enlarge
export RAM=/dev/shm

export RESN=$RESN
export TOPO=$TOPO
P=4

if [ $RESN = "90" ]  ;  then export RES="0.00083333333333333333333333333" ; export ERES="0.10" ;  fi 
if [ $RESN = "250" ]  ; then export RES="0.00208333333333333333333333333" ; export ERES="0.25" ;  fi  
if [ $RESN = "1.00" ] ; then export RES="0.00833333333333333333333333333" ; export ERES="1.00" ;  fi     # check this resulution in case running the 1km 

if [ $TOPO != "geom" ]  ; then 


# parte inferiore migrata al sc09_equi_warp_wgs84_continue_90M_250M_weight.sh 
# if a tile is covered only by one zone than cp else make the weighted mean of the 2 rasters.  
#  n35e040

######################################################
######    EU and AS ##################################
######################################################

ls   /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/$TOPO/tiles/${TOPO}_{AS,EU}_*_${RESN}.tif  | xargs -n 1 -P $P  bash -c $'

file=$1 
filenametopo=$(basename $file _${RESN}.tif )
filename=${filenametopo: -7} 

gdalbuildvrt -srcnodata -9999 -vrtnodata -9999   -overwrite  -separate -a_srs EPSG:4326   $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  $(ls   $SCRATCH/$TOPO/tiles/${TOPO}_{EU,AS}_${filename}_${RESN}.tif 2>/dev/null  ) 
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_srs EPSG:4326 -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $SCRATCH/${TOPO}/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start weighted mean 

gdalbuildvrt -srcnodata -9999 -vrtnodata -9999  -a_srs EPSG:4326 -overwrite  -tr ${RES} ${RES} -separate -te $( getCorners4Gwarp $RAM/${TOPO}_CT_${filename}_${RESN}.vrt ) $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $(ls   $SCRATCH/$TOPO/tiles/${TOPO}_{EU,AS}_${filename}_${RESN}.tif 2>/dev/null  )  $EQUI_AD/EUAS/GEOG/EQUI7_V13_EUAS_GEOG_WEIGHT_KM${ERES}.tif

gdal_translate -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_nodata -9999 $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 


source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $RAM loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 

g.list rast -p 

g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.1,EU.1   # band 1 EUROPE 
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.2,AS.2   # band 2 ASIA
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.3,WH.3

echo weighted mean 
 
r.mapcalc "WEIGHT = (((EU.1 *  WH.3) + (AS.2 * (100 - WH.3 ))) /100) " 
# r.mapcalc "WEIGHT = if (WH.3 == 100 , EU.1) + if((WH.3 < 100 && WH.3 > 0) , (((EU.1 *  WH.3) + (AS.2 * (100 - WH.3 ))) /100)) + if(WH.3 == 0 , AS.2) " 

r.patch  input=WEIGHT,AS.2,EU.1   output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Float32  format=GTiff nodata=-9999  input=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill  output=$SCRATCH/${TOPO}/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif

rm -r -f $RAM/loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt
fi
' _ 

######################################################
############### overlay EU and AS to AF    ###########
######################################################

ls   /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/$TOPO/tiles/${TOPO}_AF_*_${RESN}.tif  | xargs -n 1 -P $P  bash -c $'

file=$1 
filenametopo=$(basename $file _${RESN}.tif )
filename=${filenametopo: -7} 
                                                                                              
gdalbuildvrt  -srcnodata -9999 -vrtnodata -9999  -overwrite  -separate -a_srs EPSG:4326   $RAM/${TOPO}_CT_${filename}_${RESN}.vrt \
                      $(ls $SCRATCH/$TOPO/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_AF_${filename}_${RESN}.tif 2>/dev/null)
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_srs EPSG:4326 -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $SCRATCH/${TOPO}/tiles_EUASAF/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start weighted mean 

gdalbuildvrt -srcnodata -9999 -vrtnodata -9999  -a_srs EPSG:4326 -overwrite   -tr ${RES} ${RES} -separate -te $( getCorners4Gwarp $RAM/${TOPO}_CT_${filename}_${RESN}.vrt ) \
$RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $(ls $SCRATCH/$TOPO/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_AF_${filename}_${RESN}.tif 2>/dev/null )  $EQUI_AD/EUASAF/GEOG/EQUI7_V13_EUASAF_GEOG_WEIGHT_KM${ERES}.tif

gdal_translate -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_nodata -9999 $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 


source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $RAM loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 

g.list rast -p 

g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.1,EU.1   # band 1 EUROPE 
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.2,AS.2   # band 2 ASIA
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.3,WH.3

if [ -f  $RAM/loc_${TOPO}_CT_${filename}_${RESN}/PERMANENT/cellhd/WH.3 ] ; then
                                                                                    # weighted function 
r.mapcalc "WEIGHT =  (((EU.1 *  WH.3) + (AS.2 * (100 - WH.3 ))) /100) " 
r.patch  input=WEIGHT,AS.2,EU.1   output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill
else
r.patch  input=AS.2,EU.1   output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill
fi

r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Float32  format=GTiff nodata=-9999  input=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill  output=$SCRATCH/${TOPO}/tiles_EUASAF/${TOPO}_${RESN}M_MERIT_${filename}.tif

rm -r -f $RAM/loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt
fi
' _ 

######################################################
############ EUASAF with OC  #########################
######################################################

cat  <( for file in  $SCRATCH/$TOPO/tiles/${TOPO}_OC_*_${RESN}.tif  ; do filename=$(basename $file _250.tif) ; echo ${filename: -7}  ; done )   <(  for file in  $SCRATCH/$TOPO/tiles_EUAS/${TOPO}_${RESN}M_MERIT_*.tif ; do filename=$(basename $file .tif  )   ; echo ${filename: -7}  ; done ) | sort | uniq  | xargs -n 1 -P $P  bash -c $' 

filename=$1 
                                                                                              
gdalbuildvrt  -srcnodata -9999 -vrtnodata -9999   -overwrite  -separate -a_srs EPSG:4326   $RAM/${TOPO}_CT_${filename}_${RESN}.vrt \
                      $(ls $SCRATCH/$TOPO/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_OC_${filename}_${RESN}.tif 2>/dev/null)
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_srs EPSG:4326 -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $SCRATCH/${TOPO}/tiles_EUASAFOC/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start weighted mean 

gdalbuildvrt -srcnodata -9999 -vrtnodata -9999 -a_srs EPSG:4326 -overwrite   -tr ${RES} ${RES} -separate -te $( getCorners4Gwarp $RAM/${TOPO}_CT_${filename}_${RESN}.vrt ) \
$RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $(ls $SCRATCH/$TOPO/tiles_EUAS/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_OC_${filename}_${RESN}.tif 2>/dev/null )  $EQUI_AD/EUASAFOC/GEOG/EQUI7_V13_EUASAFOC_GEOG_WEIGHT_KM${ERES}.tif

gdal_translate -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_nodata -9999 $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 


source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $RAM loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 

g.list rast -p 

g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.1,EU.1   # band 1 EUROPE 
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.2,AS.2   # band 2 ASIA
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.3,WH.3

if [ -f  $RAM/loc_${TOPO}_CT_${filename}_${RESN}/PERMANENT/cellhd/WH.3 ] ; then
                                                                                    # weighted function 
r.mapcalc "WEIGHT =  (((EU.1 *  WH.3) + (AS.2 * (100 - WH.3 ))) /100)  " 
r.patch  input=WEIGHT,AS.2,EU.1   output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill
else
r.patch  input=AS.2,EU.1   output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill
fi
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Float32  format=GTiff nodata=-9999  input=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill  output=$SCRATCH/${TOPO}/tiles_EUASAFOC/${TOPO}_${RESN}M_MERIT_${filename}.tif

rm -r -f $RAM/loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt
fi
' _ 

######################################################
############ NA SA ###################################
######################################################

ls   /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/$TOPO/tiles/${TOPO}_{NA,SA}_*_${RESN}.tif | sort | uniq   | xargs -n 1 -P $P  bash -c $'

file=$1 
filenametopo=$(basename $file _${RESN}.tif )
filename=${filenametopo: -7} 
                                                                                              
gdalbuildvrt  -srcnodata -9999 -vrtnodata -9999   -overwrite  -separate -a_srs EPSG:4326   $RAM/${TOPO}_CT_${filename}_${RESN}.vrt \
                      $(ls $SCRATCH/$TOPO/tiles_NASA/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_{NA,SA}_${filename}_${RESN}.tif 2>/dev/null)
BAND=$(pkinfo -nb -i  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt  | awk \'{ print $2 }\' ) 

if [ $BAND -eq 1 ] ; then 
gdal_translate -a_srs EPSG:4326 -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt $SCRATCH/${TOPO}/tiles_NASA/${TOPO}_${RESN}M_MERIT_${filename}.tif ;  rm -f $RAM/${TOPO}_CT_${filename}_${RESN}.vrt 
else 
echo start weighted mean 

gdalbuildvrt -srcnodata -9999 -vrtnodata -9999    -a_srs EPSG:4326 -overwrite -allow_projection_difference  -tr ${RES} ${RES} -separate -te $( getCorners4Gwarp $RAM/${TOPO}_CT_${filename}_${RESN}.vrt ) \
$RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $(ls $SCRATCH/$TOPO/tiles_NASA/${TOPO}_${RESN}M_MERIT_${filename}.tif $SCRATCH/$TOPO/tiles/${TOPO}_{NA,SA}_${filename}_${RESN}.tif 2>/dev/null )  $EQUI_AD/NASA/GEOG/EQUI7_V13_NASA_GEOG_WEIGHT_KM${ERES}.tif

gdal_translate -ot Float32 -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.vrt $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $RAM loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif 

g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.1,NA.1   # band 1 north america 
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.2,SA.2   # band 2 south america
g.rename raster=${TOPO}_CT_${filename}_${RESN}_WEIGHT.3,WH.3

if [ -f  $RAM/loc_${TOPO}_CT_${filename}_${RESN}/PERMANENT/cellhd/WH.3 ] ; then
                                                                                    # weighted function 
r.mapcalc "WEIGHT =  (((NA.1 *  WH.3) + (SA.2 * (100 - WH.3 ))) / 100.0) "
r.patch  input=WEIGHT,NA.1,SA.2    output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill

else
r.patch  input=SA.2,NA.1  output=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill

fi

r.out.gdal -f --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND" type=Float32  format=GTiff nodata=-9999  input=${TOPO}_CT_${filename}_${RESN}_WEIGHT_fill  output=$SCRATCH/${TOPO}/tiles_NASA/${TOPO}_${RESN}M_MERIT_${filename}.tif

rm -r -f $RAM/loc_${TOPO}_CT_${filename}_${RESN} $RAM/${TOPO}_CT_${filename}_${RESN}_WEIGHT.tif  $RAM/${TOPO}_CT_${filename}_${RESN}.vrt
fi
' _ 
 

fi # close the if geom 

exit 

