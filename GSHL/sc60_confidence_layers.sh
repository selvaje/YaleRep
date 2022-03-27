#!/bin/bash
#SBATCH -p day
#SBATCH -J sc60_confidence_layers.sh 
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 4:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc60_confidence_layers.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc60_confidence_layers.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --array=2-649
#SBATCH --mem-per-cpu=10000
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc60_confidence_layers.sh 

# remove file from yesterday
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr 

DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0/WGS84
SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0/WGS84
# gdalbuildvrt $DIR/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0.vrt $DIR/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0/12/*/*.tif 

SLURM_ARRAY_TASK_ID=529
tile=$( awk '{ print $1 , $4 , $7 , $6 , $5 }'  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_10d.txt  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 ) 

geo_string=$(echo $tile |  awk '{ print $2,$3,$4,$5 }' )
tile=$(echo $tile |  awk '{ print $1 }' )

# gdalwarp -t_srs EPSG:4326 -te $geo_string -r bilinear -tr 0.00027777777777777 0.00027777777777777 -co COMPRESS=DEFLATE -co ZLEVEL=9 -overwrite $DIR/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0/GHS_BUILT_LDSMTCNFD_GLOBE_R2015B_3857_38_v1_0.vrt  $SCRATCH/${tile}_30m_250.tif

MAX=$(pkstat -max -i $SCRATCH/${tile}_30m_250.tif | awk ' { print $2  }')

if [ $MAX = "0"  ] ; then
rm -f $SCRATCH/${tile}_30m_250.tif
else
gdal_translate -ot Float32 -scale 0 250 0 100   -co COMPRESS=DEFLATE -co ZLEVEL=9  $SCRATCH/${tile}_30m_250.tif  /dev/shm/${tile}_30m_100.tif
oft-calc /dev/shm/${tile}_30m_100.tif  /dev/shm/${tile}_30m_0_1_tmp.tif <<EOF
1
#1 100 /
EOF
rm -f /dev/shm/${tile}_30m_100.tif  
gdal_translate -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 /dev/shm/${tile}_30m_0_1_tmp.tif $SCRATCH/${tile}_30m_0_1.tif
rm -f /dev/shm/${tile}_30m_0_1_tmp.tif 
pkfilter  -dx 30 -dy 30 -d 30 -f stdev  -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $SCRATCH/${tile}_30m_0_1.tif   -o $SCRATCH/${tile}_1km_stdev.tif  
pkfilter  -dx 30 -dy 30 -d 30 -f mean   -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $SCRATCH/${tile}_30m_0_1.tif   -o $SCRATCH/${tile}_1km_mean.tif  

pkgetmask  -ot Byte -min 0.499999   -max 1.1 -data 1 -nodata 0    -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $SCRATCH/${tile}_30m_0_1.tif -o $SCRATCH/${tile}_30m_0_1_msk.tif
pkfilter -ot UInt32   -dx 30 -dy 30 -d 30 -f sum    -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $SCRATCH/${tile}_30m_0_1_msk.tif   -o $SCRATCH/${tile}_1km_count_msk.tif
# pkfilter -ot UInt32   -dx 30 -dy 30 -d 30 -f stdev  -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $SCRATCH/${tile}_30m_0_1_msk.tif   -o $SCRATCH/${tile}_1km_stdev_msk.tif

oft-calc -ot Float32   $SCRATCH/${tile}_1km_count_msk.tif  $SCRATCH/${tile}_1km_perc_tmp.tif    <<EOF
1
#1 900 /
EOF
gdal_translate -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCRATCH/${tile}_1km_perc_tmp.tif  $SCRATCH/${tile}_1km_perc.tif
# rm -f $SCRATCH/${tile}_1km_count_msk.tif  $SCRATCH/${tile}_1km_perc_tmp.tif $SCRATCH/${tile}_30m_0_1_msk.tif
fi


