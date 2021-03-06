# qsub  /lustre/home/client/fas/sbsc/ga254/scripts/CLUSTER_STREAM/sc2_normalizeB.sh

#PBS -S /bin/bash
#PBS -q fas_devel
#PBS -l walltime=4:00:00
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /scratch/fas/sbsc/ga254/stdout 
#PBS -e /scratch/fas/sbsc/ga254/stderr

# non funziona con qsub ma si con bash or cp in the terminal
# per arditity index viene mantenuto il Int32 e poi passato a Int16 ...si perdono solo pochi pixel o meglio ci sono solo pochi pixel oltre il 32768

export INDIR=/lustre/scratch/client/fas/sbsc/sd566/global_wsheds/global_results_merged/filled_str_ord_maximum_max50x_lakes_manual_correction

export MSKDIR=/lustre/scratch/client/fas/sbsc/ga254/dataproces/CLUSTER_STREAM/mask
export NORDIR=/lustre/scratch/client/fas/sbsc/ga254/dataproces/CLUSTER_STREAM/normal 


### Topography

ls $INDIR/elevation/dem_avg.tif $INDIR/slope/slope_avg.tif  $INDIR/stream_topo/upcells_land.tif $INDIR/bioclim/avg/BIO_7.tif $INDIR/bioclim/avg/BIO_12.tif $INDIR/landuse/wavg/lu_1.tif $INDIR/landuse/wavg/lu_2.tif $INDIR/landuse/wavg/lu_3.tif $INDIR/landuse/wavg/lu_4.tif $INDIR/landuse/wavg/lu_5.tif $INDIR/landuse/wavg/lu_6.tif $INDIR/landuse/wavg/lu_7.tif $INDIR/landuse/wavg/lu_8.tif $INDIR/landuse/wavg/lu_9.tif $INDIR/landuse/wavg/lu_10.tif $INDIR/soil/wavg/soil_wavg_01.tif $INDIR/soil/wavg/soil_wavg_02.tif $INDIR/soil/wavg/soil_wavg_03.tif $INDIR/soil/wavg/soil_wavg_05.tif  | xargs -n 1 -P 8 bash -c $'    

file=$1 
filename=`basename $file .tif` 

gdalinfo -stats    $file  |  grep -e   STATISTICS_MEAN   -e STATISTICS_STDDEV      >     $NORDIR/stat/${filename}_msk.stat.txt  

mean=$(  awk -F "="  \'{ if (NR==1) print $2 }\'     $NORDIR/stat/${filename}_msk.stat.txt    )
stdev=$( awk -F "="  \'{ if (NR==2) print $2 }\'     $NORDIR/stat/${filename}_msk.stat.txt    )

echo start the normalization 

oft-calc -ot Int32  -um $MSKDIR/mask.tif    $file    $NORDIR/${filename}_norm_tmp.tif  >  /dev/null   <<EOF
1
#1 $mean - $stdev / 10000000 *
EOF

gdal_translate -co  BIGTIFF=YES    -co COMPRESS=LZW  -co ZLEVEL=9    $NORDIR/${filename}_norm_tmp.tif   $NORDIR/${filename}_norm.tif 
rm  $NORDIR/${filename}_norm_tmp.tif

' _ 

cd /lustre/scratch/client/fas/sbsc/ga254/dataproces/CLUSTER_STREAM/normal  

for file in *.tif   ; do gdal_edit.py -a_srs EPSG:4326  $file ; done

gdalbuildvrt -separate   -overwrite stack.vrt BIO_12_norm.tif  BIO_7_norm.tif dem_avg_norm.tif slope_avg_norm.tif lu_1_norm.tif lu_2_norm.tif lu_3_norm.tif lu_4_norm.tif lu_5_norm.tif lu_6_norm.tif lu_7_norm.tif lu_8_norm.tif lu_9_norm.tif lu_10_norm.tif soil_wavg_01_norm.tif soil_wavg_02_norm.tif soil_wavg_03_norm.tif soil_wavg_05_norm.tif  upcells_land_norm.tif

gdal_translate   -ot  Int32 -co  BIGTIFF=YES -co  COMPRESS=LZW -co ZLEVEL=9  stack.vrt  stack.tif 

# run the random to match the min and maximum value 
qsub   /home/fas/sbsc/ga254/scripts/CLUSTER_STREAM/sc2_randomsurface.sh

