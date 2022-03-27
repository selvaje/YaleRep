#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 10 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_occurence_resampling_90m.sh.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_occurence_resampling_90m.sh.err
#SBATCH --mail-user=email

#  with --cpus-per-task flag will always result in all your CPUs allocated on the same compute node
# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/GSW/sc01_occurence_resampling_90m.sh

# Size is 40000, 40000
# pixel size GWS  0.000250000000000 
#
# 
# 504 file 

export OCC=/project/fas/sbsc/ga254/dataproces/GSW/input/occurrence
export RAM=/dev/shm

cleanram 

ls $OCC/occurrence_*_*.tif    | xargs -n 1  -P 10 bash -c $'  
file=$1
filename=$(basename $file .tif )
gdalbuildvrt -overwrite -te  $(getCorners4Gwarp  $file  | awk \'{  print $1 - 1 , $2 - 1 , $3 + 1 , $4 + 1   }\'  )  $RAM/$filename.vrt $OCC/occurrence_*_*.tif
gdalwarp -overwrite -srcnodata 255 -dstnodata 255 -of GTiff -overwrite -te  $(getCorners4Gwarp  $file) -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.00083333333333333333333 0.00083333333333333333333 -r bilinear $RAM/$filename.vrt  $RAM/$filename.tif 
gdalwarp -overwrite -co COMPRESS=DEFLATE -co ZLEVEL=9   -of GTiff -srcnodata 0 -dstalpha  $RAM/$filename.tif  $RAM/${filename}_tr.tif  
rm -f  $RAM/$filename.vrt 
' _ 


echo start to merege the 90 file 

gdalbuildvrt -overwrite  -te -180 -60 180 84     $RAM/occurrence_90.vrt    $RAM/occurrence_*_*{N,S}.tif 
gdal_translate -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/occurrence_90.vrt   $OCC/../occurrence_90m.tif

rm   $RAM/occurrence_*_*{N,S}.tif 

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 0.1  -max 120    -data 1 -nodata  0  -i  $OCC/../occurrence_90m.tif -o  $OCC/../occurrence_90m_mksk0-1.tif
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -min -1  -max 120     -data 0 -nodata  255  -i  $OCC/../occurrence_90m.tif -o  $OCC/../occurrence_90m_mksk0-255.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m  $OCC/../occurrence_90m.tif  -msknodata  255  -nodata 255   -i $OCC/../occurrence_90m_mksk0-1.tif  -o  $OCC/../occurrence_90m_mksk0-1-255.tif  # da controllare il 255 non appare.

gdalbuildvrt -overwrite  -te -180 -60 180 84     $RAM/occurrence_90.vrt    $RAM/occurrence_*_*{N,S}_tr.tif  
gdal_translate -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/occurrence_90.vrt   $OCC/../occurrence_90m_tr.tif

cleanram 
