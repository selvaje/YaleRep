#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 20  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_equi_warp_wgs84_continue_90M_250M_tilecreation90.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_equi_warp_wgs84_continue_90M_250M_tilecreation90.sh.%J.err


# intensity exposition range variance elongation azimuth extend width 

# for TOPO in geom dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness eastness dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do for RESN in 90 ; do sbatch --export=TOPO=$TOPO,RESN=$RESN    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_equi_warp_wgs84_continue_90M_250M_tilecreation90.sh ; done ; done 

# sbatch  --export=TOPO=dx,RESN=90 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_equi_warp_wgs84_continue_90M_250M_tilecreation90.sh


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
export RESN=$RESN

if [ $RESN = "90" ] ; then export RES="0.00083333333333333333333333333" ; fi 


find   $MERIT/input_tif/ -name "*_dem.tif"   | xargs -n 1 -P $P  bash -c $' 
TILE=$( basename $1 _dem.tif )

if [  $TOPO = geom ] ; then NODATA=0 ; else   NODATA="-9999" ;   fi

gdalbuildvrt  -srcnodata $NODATA  -vrtnodata $NODATA   -overwrite  -a_srs EPSG:4326   $RAM/${TOPO}_${TILE}.vrt  $(ls  $SCRATCH/$TOPO/tiles_EUASAFOC/${TOPO}_${RESN}M_MERIT_${TILE}.tif  $SCRATCH/$TOPO/tiles_EUASAF/${TOPO}_${RESN}M_MERIT_${TILE}.tif $SCRATCH/$TOPO/tiles_NASA/${TOPO}_${RESN}M_MERIT_${TILE}.tif $SCRATCH/$TOPO/tiles/${TOPO}_AN_${TILE}_$RESN.tif   2>/dev/null  ) 

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_nodata $NODATA   -a_srs EPSG:4326   $RAM/${TOPO}_${TILE}.vrt   $SCRATCH/gdrive90m/$TOPO/${TOPO}_$TILE.tif
gdal_edit.py  -mo "TIFFTAG_ARTIST=Giuseppe Amatulli (giuseppe.amatulli@gmail.com)" \
              -mo "TIFFTAG_DATETIME=2019" \
              -mo "TIFFTAG_IMAGEDESCRIPTION= ${TOPO} geomorphometry variable derived from MERIT-DEM - resolution 3 arc-seconds" \
               $SCRATCH/gdrive90m/$TOPO/${TOPO}_$TILE.tif

rm -f  $RAM/${TOPO}_${TILE}.vrt 
' _ 


exit 
