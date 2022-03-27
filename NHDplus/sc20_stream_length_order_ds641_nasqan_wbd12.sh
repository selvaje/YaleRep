#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 168:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_stream_length_order_ds641_nasqan_wbd12.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_stream_length_order_ds641_nasqan_wbd12.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc20_stream_length_order_ds641_nasqan_wbd12.sh
#SBATCH --array=27-27

###  #SBATCH --array=1-39
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc20_stream_length_order_ds641_nasqan_wbd12.sh

# bilong to missipi 
# b32202309.shp   line 38 
# b07373420.shp   line 25 
# b07374000.shp   line 26
# b07374525.shp   line 27 
# largest basin  b07374525 store in line 27 the other can be skiped 

NHD=/project/fas/sbsc/ga254/dataproces/NHDplus
file=$(ls $NHD/ds641_nasqan_wbd12_wgs84/*.shp  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )

# data preparation 
# for file in $NHD/ds641_nasqan_wbd12/nasqan_basins/*.shp ; do
#     filename=$(basename $file .shp )
#     rm -f  ds641_nasqan_wbd12_wgs84/$filename.*
#     ogr2ogr -t_srs "$NHD/shp/NHDPlusV21_GB_16_NHDSnapshot_06/NHDFlowline.prj" $NHD/ds641_nasqan_wbd12_wgs84/$filename.shp  $file
# done 

# vrt structure 

# <OGRVRTDataSource>
#     <OGRVRTUnionLayer name="unionLayer">
#         <OGRVRTLayer name="source1">
#             <SrcDataSource>source1.shp</SrcDataSource>
#         </OGRVRTLayer>
#         <OGRVRTLayer name="source2">
#             <SrcDataSource>source2.shp</SrcDataSource>
#         </OGRVRTLayer>
#     </OGRVRTUnionLayer>
# </OGRVRTDataSource>

# cd $NHD/shp 

# echo "<OGRVRTDataSource>"                      >  NHDFlowline.vrt 
# echo "<OGRVRTUnionLayer name=\"unionLayer\">" >>  NHDFlowline.vrt 
 
# for file in $NHD/shp/*/NHDFlowline.shp ; do 
#     echo "<OGRVRTLayer name=\"NHDFlowline\">"     >>  NHDFlowline.vrt 
#     echo "<SrcDataSource>$file</SrcDataSource>"   >>  NHDFlowline.vrt 
#     echo "</OGRVRTLayer>">>  NHDFlowline.vrt 
# done 

# cho "</OGRVRTUnionLayer>"                    >>  NHDFlowline.vrt 
# echo "</OGRVRTDataSource>"                    >>  NHDFlowline.vrt 
 
echo start the loop  $file 

filename=$( basename  $file  .shp )
ogr2ogr -overwrite -spat $(ogrinfo -al -so $file | grep Extent | awk '{ gsub ("[(),]",""); print $2,$3,$5,$6 }')  -sql "SELECT  LENGTHKM, StreamOrde  FROM 'unionLayer' WHERE ( FTYPE = 'StreamRiver')  OR ( FTYPE = 'Connector')  OR ( FTYPE = 'ArtificialPath')  "   $NHD/ds641_nasqan_wbd12_wgs84_crop/${filename}_streams.shp $NHD/shp/NHDFlowline.vrt
ogr2ogr -overwrite -clipdst $file $NHD/ds641_nasqan_wbd12_wgs84_clip_streams/$filename.shp $NHD/ds641_nasqan_wbd12_wgs84_crop/${filename}_streams.shp 
ogrinfo -al -geom=NO   -where  " FTYPE='StreamRiver' OR  FTYPE='Connector' OR  FTYPE='ArtificialPath' "  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams/$filename.shp  |  grep -e StreamOrde  -e  LENGTHKM -e FTYPE   | awk '{  if($1=="StreamOrde") { printf("%s\n", $4) }  else {  printf("%s ", $4) }}' | awk '{ print $2"_"$3, $1  , 1 }' | sort -k 1,1  >  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams_txt/${filename}_streams_oder.txt 

/gpfs/home/fas/sbsc/ga254/scripts/WWF_ECO/sum.sh  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams_txt/${filename}_streams_oder.txt  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams_txt/${filename}_streams_oder_sum.txt  <<EOF
n
1
3
EOF

awk '{ gsub("_"," " ) ; print $1 ","  $2  "," $3 "," int($4) }'  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams_txt/${filename}_streams_oder_sum.txt >  $NHD/ds641_nasqan_wbd12_wgs84_clip_streams_txt/${filename}_streams_oder_sum.csv

