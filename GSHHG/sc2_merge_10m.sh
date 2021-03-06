# qsub /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/GSHHG/sc2_merge_10m.sh 

#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=1gb
#PBS -l walltime=10:00:00 
#PBS -l nodes=1:ppn=2
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr


module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Libraries/OSGEO/1.10.0


TIFIN=/lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_tif_1km


gdalbuildvrt  -overwrite -tr 0.0083333333333 0.0083333333333     $TIFIN/land_perc.vrt   $TIFIN/h??v??_1km.tif
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9    -ot Float32  $TIFIN/land_perc.vrt  $TIFIN/land_frequency_m10fltGSHHS_f_L1.tif

gdalbuildvrt  -overwrite -tr 0.0083333333333 0.0083333333333     $TIFIN/land_perc.vrt   $TIFIN/h??v??_1kmPerc.tif
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9    -ot Float32  $TIFIN/land_perc.vrt  $TIFIN/land_frequency_m10intGSHHS_f_L1.tif


# rm /lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_shp_clip/*  $TIFIN/land_perc.vrt $TIFIN/h??v??_1km.tif /lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_tif/*.tif

