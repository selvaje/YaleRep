#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00   # 4 hour max 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc23_reclass_array_lbasin_stream_intb.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc23_reclass_array_lbasin_stream_intb.sh.%A_%a.err
#SBATCH --job-name=sc23_reclass_array_lbasin_stream_intb.sh
#SBATCH --array=1-59 
#SBATCH --mem=20G

## sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc23_reclass_array_lbasin_stream_intb.sh
## sbatch  -d afterany:$( squeue -u $USER -o "%.9F %.80j"  | grep  sc22_build_dem_location_HandsTilesBASINS_StreamLbasin.sh   | awk '{ print $1  }' | uniq)   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc23_reclass_array_lbasin_stream_intb.sh

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export file=$SCMH/lbasin_tiles_intb2/lbasin_??${SLURM_ARRAY_TASK_ID}.tif
export filename=$(basename $file .tif  )

find  /tmp/     -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

source ~/bin/gdal3
source ~/bin/pktools


if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then
export lastmaxb=0
for filehist in  $SCMH/lbasin_tiles_intb2/lbasin_???_hist.txt   $SCMH/lbasin_tiles_intb2/lbasin_????_hist.txt    ; do 
export filenamehist=$(basename  $filehist  _hist.txt  )

awk -v lastmaxb=$lastmaxb '{ if ($1==0) { print $1 , 0  } else { lastmaxb=1+lastmaxb ; print $1 , lastmaxb }}' $filehist  >  $SCMH/lbasin_tiles_intb_reclass2/${filenamehist}_rec.txt
export lastmaxb=$(tail -1 $SCMH/lbasin_tiles_intb_reclass2/${filenamehist}_rec.txt  | awk '{ print $2  }')
done 

else
sleep 30
fi 

GDAL_CACHEMAX=15000 
pkreclass -ot UInt32 -code $SCMH/lbasin_tiles_intb_reclass2/${filename}_rec.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -i $file -o $SCMH/lbasin_tiles_intb_reclass2/$filename.tif  
gdal_edit.py  -a_nodata 0 -a_srs EPSG:4326  $SCMH/lbasin_tiles_intb_reclass2/$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate  $file ) $SCMH/lbasin_tiles_intb_reclass2/$filename.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/lbasin_tiles_intb_reclass2/$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate  $file ) $SCMH/lbasin_tiles_intb_reclass2/$filename.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/lbasin_tiles_intb_reclass2/$filename.tif

rm -f $SCMH/lbasin_tiles_intb_reclass2/${filename}_rec.txt 

if [   $SLURM_ARRAY_TASK_ID = 59  ] ; then
sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.10K %.4P %.80j %3D%2C%.8T %.9M  %.9l  %.S  %R" | grep sc23_reclass_array_lbasin_stream_intb.sh  | awk '{ print $1  }' | uniq ) /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc24_tiling20d_lbasin.sh
sleep 60
fi 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

