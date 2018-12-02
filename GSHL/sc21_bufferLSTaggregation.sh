#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc21_bufferLSTaggregation.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_bufferLSTaggregation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_bufferLSTaggregation.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc21_bufferLSTaggregation.sh

LST=/project/fas/sbsc/ga254/dataproces/MYOD11A2_celsiusmean
INDIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad
OUTDIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst
RAM=/dev/shm


# source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh  $OUTDIR/grassdb loc_buffer  $INDIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9.tif 

# r.buffer -z input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9  output=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf distances=3,6,9,12,15,18,21  units=kilometers 
# r.clump -d  --overwrite    input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf       output=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump

# r.colors -r map=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf
# r.colors -r map=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump

# r.out.gdal --overwrite nodata=0 -c -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff  input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf  output=$OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf.tif 
# r.out.gdal --overwrite nodata=0 -c -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff  input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump  output=$OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump.tif 
# rm -f $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf.tif.aux.xml  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump.tif.aux.xml

gdal_translate  -projwin  $(getCorners4Gtranslate $INDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.tif) $LST/LST_MOYDmax_Day_spline_month7.tif $RAM/LST_MOYDmax_Day_spline_month7.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $RAM/LST_MOYDmax_Day_spline_month7.tif  -msknodata  -9999  -nodata 0 -i $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump.tif  -o $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif

oft-stat -mm -um  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif  -i $RAM/LST_MOYDmax_Day_spline_month7.tif -o  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7.txt


awk 'BEGIN {print 0 ,-9999} { print $1 ,$3  }' $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7.txt >  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7min.txt
awk 'BEGIN {print 0 ,-9999}{ print $1, $4  }' $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7.txt > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7max.txt
awk 'BEGIN {print 0 ,-9999}{ print $1, $5  }' $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7.txt > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7mean.txt
awk 'BEGIN {print 0 ,-9999}{ print $1, $6  }' $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7.txt > $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7stdev.txt

pkreclass  -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -code  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7min.txt -i   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif  -o $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7min.tif 
pkreclass -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -code  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7max.txt -i   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif  -o $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7max.tif 
pkreclass -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -code  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7mean.txt -i   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif  -o $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7mean.tif 
pkreclass -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -code  $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7stdev.txt -i   $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_lstmsk.tif  -o $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7stdev.tif 

gdal_edit.py -a_nodata -9999 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7min.tif 
gdal_edit.py -a_nodata -9999 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7max.tif 
gdal_edit.py -a_nodata -9999 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7mean.tif 
gdal_edit.py -a_nodata -9999 $OUTDIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin9_buf_clump_LST_MOYDmax_Day_spline_month7stdev.tif 

rm  $RAM/LST_MOYDmax_Day_spline_month7.tif
