#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 168:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01b_dem_stdev_tile.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01b_dem_stdev_tile.%J.err
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


# for RADIUS in 11 21 31 41 51  61 71 81 91 101 111 121 131 141 151 161 171 ; do for TILE in $( seq 0 39 )  ; do sbatch   --export=RADIUS=$RADIUS,TILE=$TILE -J sc01b_dem_stdev_tile_R${RADIUS}T${TILES}.sh  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc01b_dem_stdev_tile.sh ; done  ; done 


DIR=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev
OUTDIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev
RAM=/dev/shm
cleanram

echo filter  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_R${RADIUS}t$TILE.tif

pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9  -nodata -9999 -dx $RADIUS  -dy $RADIUS -circ -f stdev  -ot UInt32  -i $DIR/be75_grd_LandEnlarge_leftright_t$TILE.tif     -o  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_R${RADIUS}t$TILE.tif

if [ $TILE -ne  0 ] &&  [ $TILE -ne 39   ] ; then  
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin  250 0 4370  69120  -ot UInt32   $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_R${RADIUS}t$TILE.tif   $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t$TILE.tif
fi 

if [ $TILE -eq 0 ]  ; then                      # 4370  − 1000 + 250 = 3620 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin  1000 0 3620 69120 -ot UInt32  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_R${RADIUS}t$TILE.tif   $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t$TILE.tif
fi 

if [ $TILE -eq 39 ]  ; then                       # 17480 − 1000  − 250 = 3120
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin 250 0 3120  69120 -ot UInt32  $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_R${RADIUS}t$TILE.tif   $OUTDIR/stdev$RADIUS/be75_grd_LandEnlarge_leftright_t$TILE.tif
fi 


sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


