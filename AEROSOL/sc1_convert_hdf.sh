# data downleded from 
# wget -r ftp://ladsweb.nascom.nasa.gov/allData/51/MYD08_M3/  ; wget -r ftp://ladsweb.nascom.nasa.gov/allData/51/MOD08_M3/ 

# for file  in  /lustre0/scratch/ga254/dem_bj/AEROSOL/ladsweb.nascom.nasa.gov/allData/51/M?D08_M3/*/*/*.hdf  ; do qsub -v file=$file  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/AEROSOL/sc1_convert_hdf.sh  ; done 

# this are the data usefull. Now condisidering only Corrected_Optical_Depth_Land_Mean_Mean 

#  SUBDATASET_44_NAME=HDF4_EOS:EOS_GRID:"MOD08_M3.A2002244.051.2010309214319.hdf":mod08:Corrected_Optical_Depth_Land_Mean_Mean
#  SUBDATASET_44_DESC=[3x180x360] Corrected_Optical_Depth_Land_Mean_Mean mod08 (16-bit integer)
#  SUBDATASET_45_NAME=HDF4_EOS:EOS_GRID:"MOD08_M3.A2002244.051.2010309214319.hdf":mod08:Corrected_Optical_Depth_Land_Mean_Std
#  SUBDATASET_45_DESC=[3x180x360] Corrected_Optical_Depth_Land_Mean_Std mod08 (16-bit integer)
#  SUBDATASET_46_NAME=HDF4_EOS:EOS_GRID:"MOD08_M3.A2002244.051.2010309214319.hdf":mod08:Corrected_Optical_Depth_Land_Mean_Min
#  SUBDATASET_46_DESC=[3x180x360] Corrected_Optical_Depth_Land_Mean_Min mod08 (16-bit integer)
#  SUBDATASET_47_NAME=HDF4_EOS:EOS_GRID:"MOD08_M3.A2002244.051.2010309214319.hdf":mod08:Corrected_Optical_Depth_Land_Mean_Max
#  SUBDATASET_47_DESC=[3x180x360] Corrected_Optical_Depth_Land_Mean_Max mod08 (16-bit integer)
#  SUBDATASET_48_NAME=HDF4_EOS:EOS_GRID:"MOD08_M3.A2002244.051.2010309214319.hdf":mod08:Corrected_Optical_Depth_Land_Std_Deviation_Mean

# Corrected aerosol optical depth (Land) at 0.47, 0.55, and 0.66 microns: Mean of Daily Mean
# (0.466, 0.553, 0.644 and 2.119 μm, representing MODIS channels 3, 4, 1 and 7, respectively)


#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=1gb
#PBS -l walltime=0:02:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Libraries/OSGEO/1.10.0

# file=$1

INDIR=/lustre0/scratch/ga254/dem_bj/AEROSOL/tif

filename=`basename $file .hdf`
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9  'HDF4_EOS:EOS_GRID:''"'$file'"'':mod08:Corrected_Optical_Depth_Land_Mean_Mean'  $INDIR/$filename.tif 
rm -f  $INDIR/$filename.tif.aux.xml



