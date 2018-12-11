#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_bioclim_equi7.sh.%A.%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_bioclim_equi7.sh.%A.%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_bioclim_equi7.sh
#SBATCH --array=1-2
#SBATCH --mem-per-cpu=5000 

# 1-420
# for VAR in tmin tmax prec ; do  sbatch   --export=VAR=$VAR  /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc02_bioclim_equi7.sh ; done 

export   DIR=/project/fas/sbsc/ga254/dataproces/CHELSA
export EQUI7=/project/fas/sbsc/ga254/dataproces/EQUI7
export RAM=/dev/shm

# file in  $EQUI7  from   https://github.com/TUW-GEO/Equi7Grid/tree/master/equi7grid/grids 


file=$(ls /gpfs/loomis/project/fas/sbsc/ga254/dataproces/CHELSA/$VAR/*.tif | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
filename=$( basename $file .tif)


echo $CT  $xmin $ymin $xmax $ymax
#  -te      xmin ymin xmax ymax 
#  -projwin ulx  uly  lrx  lry
# enlarge the tile 100 x  8 

if [ $VAR = tmin    ] ; then NODATA="-32767" ; fi 
if [ $VAR = tmax    ] ; then NODATA="-32767" ; fi 
if [ $VAR = prec    ] ; then NODATA="65535"  ; fi 

for CT in EU AF AN AS NA OC SA ; do
    gdalwarp -ot Int16  --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 4000   -wm 4000   -srcnodata $NODATA  -dstnodata -9999 -te $(getCorners4Gwarp $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE_KM1.00.tif ) -co COMPRESS=DEFLATE -co ZLEVEL=9  -s_srs "$EQUI7/grids/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj"      -t_srs "$EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj" -tr 1000 1000 -r bilinear  $DIR/$VAR/$filename.tif   $RAM/${filename}_${CT}.tif   -overwrite

pksetmask -ot Int16   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -m $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE_KM1.00.tif -msknodata 0 -nodata -9999 -i     $RAM/${filename}_${CT}.tif  -o  $DIR/${VAR}_equi7/${filename}_${CT}.tif
rm -f  $RAM/${filename}_${CT}.tif

done


