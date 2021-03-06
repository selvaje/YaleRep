# for file in `ls /lustre0/scratch/ga254/dem_bj/GMTED2010/tiles/mi75_grd_tif/?_?.tif` ; do qsub  -v file=$file /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc1_masksea.sh  $file   ; done 
# for file in `ls /lustre0/scratch/ga254/dem_bj/GMTED2010/tiles/mi75_grd_tif/?_?.tif` ; do bash  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc1_masksea.sh  $file   ; done 

# ls /lustre0/scratch/ga254/dem_bj/GMTED2010/tiles/mi75_grd_tif/?_?.tif | xargs -n 1 -P 1 bash  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc1_masksea.sh 






#PBS -S /bin/bash 
#PBS -q fas_devel
#PBS -l walltime=00:20:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout/dem_var 
#PBS -e /lustre0/scratch/ga254/stderr/dem_var

file=$1
OUTDIR=/lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif

filename=`basename $file .tif`
pkgetmask -co COMPRESS=LZW -co ZLEVEL=9  -ot Byte -min -900  -max 1  -nodata  0 -data 1 -i  $file  -o  $OUTDIR/$filename.tif
oft-clump -i       -um $OUTDIR/$filename.tif  -o      -um $OUTDIR/clump_$filename.tif   -um $OUTDIR/$filename.tif


# run manualy this line 
#
# gdalbuildvrt  /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/out.vrt  /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/*.tif 
# gdal_translate  -ot Byte   -co COMPRESS=LZW -co ZLEVEL=9     /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/out.vrt /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/water_mask.tif 
# oft-clump  /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/water_mask.tif   /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/clump_water_mask.tif  
# cheak manuly with openev the value of the see and 
# pkgetmask -co COMPRESS=LZW -co ZLEVEL=9  -ot Byte -min ?  -max ?  -nodata  0 -data 1 -i  $file  -o   /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/clump_sea_mask.tif  /lustre0/scratch/ga254/dem_bj/GMTED2010/masksea/tif/ocean_mask.tif
#  
