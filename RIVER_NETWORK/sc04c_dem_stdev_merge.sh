#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01c_dem_stdev_merge.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01c_dem_stdev_merge.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


# for RADIUS in 11 21 31 41 51  61 71 81 91 101 111 121 131 141 151 161 171 ; do  sbatch -d $( echo afterany$( qmys | grep sc01b_dem_stdev_tile_R  | awk '{ printf (":%i", $1)  }' ))     --export=RADIUS=$RADIUS -J sc01c_dem_stdev_merge_R${RADIUS}.sh  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc01c_dem_stdev_merge.sh  ; done 


DIR=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev
OUTDIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev
RAM=/dev/shm
cleanram 

gdalbuildvrt -overwrite  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t.vrt     $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t?.tif      $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t??.tif   

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot UInt32  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t.vrt   $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_stdev$RADIUS.tif

rm -f $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t.vrt 

gdal_edit.py  -a_srs EPSG:4326  -a_ullr  $( getCorners4Gtranslate /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd_LandEnlarge.tif  )  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_stdev$RADIUS.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot UInt32 -m /project/fas/sbsc/ga254/dataproces/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSK.tif  -msknodata 0  -nodata 65535  -i    $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_stdev$RADIUS.tif -o  $DIR/stdev$RADIUS/be75_grd_LandEnlarge_stdev$RADIUS.tif 

sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


