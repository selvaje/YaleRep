#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_equi_warp_wgs84_continue_90M_250M_vrtcreation250.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_equi_warp_wgs84_continue_90M_250M_vrtcreation250.sh.%J.err
#SBATCH --mem-per-cpu=10000

# intensity exposition range variance elongation azimuth extend width 

# for TOPO in geom dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness eastness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do for RESN in 250 ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_equi_warp_wgs84_continue_90M_250M_vrtcreation250.sh ; done ; done 

# sbatch  --export=TOPO=dx,RESN=0.10 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_equi_warp_wgs84_continue_90M_250M_vrtcreation250.sh
# sbatch  --export=TOPO=dx,RESN=250  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_equi_warp_wgs84_continue_90M_250M_vrtcreation250.sh

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

if [ $RESN = "0.10" ] ; then export RES="0.00083333333333333333333333333" ; fi 
if [ $RESN = "250" ]  ; then export RES="0.00208333333333333333333333333" ; fi 
if [ $RESN = "1.00" ] ; then export RES="0.00833333333333333333333333333" ; fi 

export RESN
if [  $TOPO = geom ] ; then NODATA=0 ; else   NODATA="-9999" ;   fi


if [ $RESN = "250" ] ; then    
gdalbuildvrt -overwrite -srcnodata $NODATA -vrtnodata $NODATA $RAM/${TOPO}_250Mbilinear_MERIT.vrt $SCRATCH/$TOPO/tiles_EUASAFOC/${TOPO}_${RESN}M_MERIT_*.tif  $SCRATCH/$TOPO/tiles_EUASAF/${TOPO}_${RESN}M_MERIT_*.tif $SCRATCH/$TOPO/tiles_NASA/${TOPO}_${RESN}M_MERIT_*.tif $SCRATCH/$TOPO/tiles/${TOPO}_AN_*_$RESN.tif 
gdal_translate --config GDAL_CACHEMAX 4000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata $NODATA -co BIGTIFF=YES $RAM/${TOPO}_250Mbilinear_MERIT.vrt  $MERIT/final250m/${TOPO}_250Mbilinear_MERIT.tif
rm -f $RAM/${TOPO}_250Mbilinear_MERIT.vrt 
fi 

# pkinfo  -nodata $NODATA -mm -i $MERIT/final250m/${TOPO}_250Mbilinear_MERIT.tif > $MERIT/final250m/${TOPO}_250Mbilinear_MERIT_mm.txt 

if [  $TOPO = geom ] ; then MASK="0.5" ; else   MASK="-9998" ;   fi
pkgetmask -min $MASK  -max 9999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Byte -i $MERIT/final250m/${TOPO}_250Mbilinear_MERIT.tif -o $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_msk.tif


# Byte     0   255 SCALE=1 ; fi 
if [ $TOPO = geom ] ; then OT=Byte    ; MULT=1 ; NODATA=0 ; SCALE=1 ; fi                             # -min 0 -max 10          OK

# UInt16   0   65,535 
if [ $TOPO = aspect ] ; then OT=UInt16  ; MULT=100    ; NODATA=65535  ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi    # -min 0      -max 360    OK
if [ $TOPO = spi  ]   ; then OT=UInt16  ; MULT=0.1    ; NODATA=65535  ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi    # -min 9.76709e-06 -max 565981   OK
if [ $TOPO = vrm ]    ; then OT=UInt16  ; MULT=100000 ; NODATA=65535  ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi    # -min -2.97452e-08 -max 0.516682 OK

# Int16  -32,768  32,767 
if [ $TOPO = aspect-cosine ] ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -1        -max 1     OK
if [ $TOPO = aspect-sine ]   ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -1         -max 1     OK
if [ $TOPO = convergence ]   ; then OT=Int16 ; MULT=100   ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -99.9968   -max 99.9134  OK
if [ $TOPO = cti ]           ; then OT=Int16 ; MULT=1000  ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -7.29337   -max 19.8719  OK
if [ $TOPO = dev-magnitude ] ; then OT=Int16 ; MULT=10    ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -424.413   -max 1713.44  OK
if [ $TOPO = dev-scale ]     ; then OT=Int16 ; MULT=1     ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 1          -max 1999   OK
if [ $TOPO = dx ]            ; then OT=Int16 ; MULT=1000  ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -8.02223   -max 8.1319  OK
if [ $TOPO = dxx ]           ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.167993  -max 0.162343 OK
if [ $TOPO = dxy ]           ; then OT=Int16 ; MULT=100000; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.0403883 -max 0.0424977 OK
if [ $TOPO = dy ]            ; then OT=Int16 ; MULT=1000  ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -8.01632   -max 8.7637  OK
if [ $TOPO = dyy ]           ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.0786815 -max 0.162356 OK
if [ $TOPO = eastness ]     ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.971806  -max 0.975874 OK
if [ $TOPO = elev-stdev ]    ; then OT=Int16 ; MULT=10    ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 0          -max 847.221  OK
if [ $TOPO = northness ]     ; then OT=Int16 ; MULT=10000 ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.965886  -max 0.982116 OK
if [ $TOPO = pcurv ]         ; then OT=Int16 ; MULT=100000; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.0671902 -max 0.0295959 OK
if [ $TOPO = rough-magnitude ];then OT=Int16 ; MULT=100   ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 1.90916e-05 -max 49.724  OK
if [ $TOPO = rough-scale ]   ; then OT=Int16 ; MULT=1     ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 1           -max 1999   OK
if [ $TOPO = roughness ]     ; then OT=Int16 ; MULT=10    ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 0           -max 1793.76  OK
if [ $TOPO = slope ]         ; then OT=Int16 ; MULT=100   ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 0           -max 80.1772  OK
if [ $TOPO = tcurv ]         ; then OT=Int16 ; MULT=100000; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -0.0948295  -max 0.0476475 OK
if [ $TOPO = tpi ]           ; then OT=Int16 ; MULT=10    ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min -925.032    -max 823.632  OK
if [ $TOPO = tri ]           ; then OT=Int16 ; MULT=10    ; NODATA=-32768 ; SCALE=$(awk -v MULT=$MULT 'BEGIN {print 1/MULT}') ; fi # -min 0           -max 1076.05  OK


oft-calc -ot $OT -um $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_msk.tif $MERIT/final250m/${TOPO}_250Mbilinear_MERIT.tif $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT.tif <<EOF
1
#1 $MULT *
EOF

pksetmask -ot $OT -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co BIGTIFF=YES -m $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_msk.tif -msknodata 0 -nodata $NODATA -i $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT.tif -o $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif 

pkinfo -nodata $NODATA   -mm -i $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif > $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int_mm.txt 

# start to prepare a cloud-optimized GeoTIFF  as described at https://github.com/Envirometrix/LandGISmaps#cloud-optimized-geotiff 

gdaladdo -clean  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif # usefull in case of re-run  clean interna and external overview 
rm -f $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr.nrs  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr.avg
gdaladdo --config GDAL_CACHEMAX 8000 --config COMPRESS_OVERVIEW LZW -r average -ro  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif 8  # external overview for assesment 
gdal_edit.py -a_ullr  $( getCorners4Gtranslate   $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif    ) -a_srs EPSG:4326 $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr
mv $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr.avg 

gdaladdo --config GDAL_CACHEMAX 8000 --config COMPRESS_OVERVIEW LZW -r nearest  -ro  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif 8  # external overview for assesment 
gdal_edit.py -a_ullr  $( getCorners4Gtranslate   $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif    ) -a_srs EPSG:4326 $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr
mv $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr  $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif.ovr.nrs 

# Pay attention that I have inserted  also the -co BIGTIFF=YES -co TILED=YES 
# Anyway very very awkward to have extend that are not rounded to the degree. User will complain if they have to crop the tif


gdal_translate -ot $OT -projwin  -180.00000 87.37000 179.99994 -62.00081 --config GDAL_CACHEMAX 8000    \
               -co BIGTIFF=YES  -co COMPRESS=LZW -co BLOCKYSIZE=512 -co  BLOCKXSIZE=512 -co COPY_SRC_OVERVIEWS=YES -mo CO=YES \
               --config GDAL_TIFF_OVR_BLOCKSIZE 512 -co TILED=YES -a_nodata $NODATA -a_srs EPSG:4326   \
               $SCRATCH/geohub250m/${TOPO}_250Mbilinear_MERIT_int.tif  $MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif

# create internal overview 

gdal_edit.py -a_ullr  -180.00000 87.37000 179.99994 -62.00081 \
              -mo "TIFFTAG_ARTIST=Giuseppe Amatulli (giuseppe.amatulli@gmail.com)" \
              -mo "TIFFTAG_DATETIME=2019" \
              -mo "TIFFTAG_IMAGEDESCRIPTION= ${TOPO} geomorphometry variable derived from MERIT-DEM - resolution 3 arc-seconds" \
              -mo "Offset=0" -mo "Scale=$SCALE" \
$MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif
gdaladdo --config GDAL_CACHEMAX 8000  -r nearest $MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif  2 4 8 16 32 64 128 


# to restore the pixel size to 0.002083333333333 and precise extent use the following  
# gdal_edit.py -a_ullr  -180.00000  87.370833333333333 180.0000000 -62.0000000  input.tif 

echo get statistic 
pkinfo -nodata $NODATA  -mm -i $MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0.tif  > $MERIT/geohub250m/dtm_${TOPO}_merit.dem_m_250m_s0..0cm_2018_v1.0_mm.txt 
pkinfo  -nodata $NODATA -mm -i $MERIT/final250m/${TOPO}_250Mbilinear_MERIT.tif > $MERIT/final250m/${TOPO}_250Mbilinear_MERIT_mm.txt 
