#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout1/sc20_curl_1tileGLAD_ARD.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr1/sc20_curl_1tileGLAD_ARD.sh.%A_%a.err
#SBATCH --mem=10G 
#SBATCH --job-name=sc20_curl_1tileGLAD_ARD.sh

### scontrol update ArrayTaskThrottle=400 JobId=11423078
### 10433  
### #SBATCH --array=10400-10500 
### 19221
##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/sc20_curl_1tileGLAD_ARD.sh
###### total array 19221 
##### array 5073   159W_22N  ; 5074 159W_21N

ulimit -c 0

source ~/bin/gdal3 
source ~/bin/pktools 

export GLAD=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/
export GLADSC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GLAD_ARD_BK
export RAM=/dev/shm


export TILE=015E_38N
export TILENS=38N


# ### wget --user=elselvaje --password='wrSDhgTaqkP6aBkK' -O - -A.tif  https://glad.umd.edu/dataset/landsat_v1.1/38N/015E_38N/929.tif

# for INTER in $(grep -e ^2020 -e ^2019 -e ^2018 $GLAD/metadata/16d_intervals.csv | awk '{ $1=""; print $0 }' ) ; do
# ### wait the connection for 10 min per file 
# curl --connect-timeout 600 -u elselvaje:wrSDhgTaqkP6aBkK -X GET https://glad.umd.edu/dataset/landsat_v1.1/$TILENS/$TILE/$INTER.tif -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/$INTER.tif -q || { handle ; error ; } 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin 15.24 38.11 15.34 38 $GLADSC/data/${TILENS}_1T/${TILE}_1T/${INTER}.tif $GLADSC/data/${TILENS}_1T/${TILE}_1T/${INTER}_crop.tif

# if [[ "$?" != 0 ]]; then
#     echo "Error downloading $TILENS/$TILE/$INTER.tif"
#     # save the file name into DOWNLOAD_FAIL.txt
#     echo $TILENS/$TILE/$INTER.tif  >> $GLADSC/data/$TILENS/$TILE/DOWNLOAD_FAIL.txt  
# else
#     echo $TILENS/$TILE/$INTER.tif  >> $GLADSC/data/$TILENS/$TILE/DOWNLOAD_DONE.txt  
# sleep 3 
# FORMAT=$(file $GLADSC/data/$TILENS/$TILE/$INTER.tif | awk '{ print $2  }')
# if [ $FORMAT = HTML ] ; then rm $GLADSC/data/$TILENS/$TILE/$INTER.tif  ; fi 
# fi  
# done 

# # QA code   Description Quality
# # 0         Nodata                                                          stripes and out of the image
# # 1         Land                                                            clear-sky
# # 2         Water                                                           clear-sky
# # 3         Cloud                                                           Cloud contaminated
# # 4         Cloud shadow                                                    Shadow contaminated
# # 5         Hillshade                                                       clear-sky 
# # 6         Snow                                                            clear-sky
# # 7         Haze                                                            Cloud contaminated
# # 8         Cloud buffer                                                    Cloud contaminated
# # 9         Shadow buffer                                                   Shadow contaminated
# # 10        Shadow high likelihood                                          Shadow contaminated
# # 11        Additional cloud buffer over land                               clear-sky
# # 12        Additional cloud buffer over water                              clear-sky
# # 14        Additional shadow buffer over land                              clear-sky
# # 15        Land, water detected but not used                               clear-sky
# # 16        Additional cloud buffer over land, water detected but not used  clear-sky
# # 17        Additional shadow buffer over land, water detected but not used clear-sky

# # 1 Normalized surface reflectance of blue band
# # 2 Normalized surface reflectance of green band
# # 3 Normalized surface reflectance of red band
# # 4 Normalized surface reflectance of NIR band
# # 5 Normalized surface reflectance of SWIR1 band
# # 6 Normalized surface reflectance of SWIR2 band
# # 7 Normalized brightness temperature
# # 8 Observation quality code (QA)    = -bndnodata 7

# ### keep only 1
# #### create median value for each band using 3 years

# # 2019 898 899 900 901 902 903 904 905 906 907 908 909 910 911 912 913 914 915 916 917 918 919 920         
# # 2020 921 922 923 924 925 926 927 928 929 930 931 932 933 934 935 936 937 938 939 940 941 942 943 

echo start the composite
export GDAL_CACHEMAX=2000
echo 01 02 03 04 05 06 07 08 09 $( seq 10 23 )   | xargs -n 1 -P 4  bash -c $' 
day=$1
export TILE=$TILE
##### composit only if the file exist. 
pkcomposite $( grep -e ^2019 -e ^2020 -e ^2018 $GLAD/metadata/16d_intervals.csv | awk -v day=$day  \'{ print $(day+1)  }\' |  xargs  -I {}  -n 1 ls $GLADSC/data/${TILENS}_1T/${TILE}_1T/{}_crop.tif 2>/dev/null  | xargs  -I {}  -n 1 echo -i  {}  ) -ot UInt16 -co COMPRESS=LZW -co ZLEVEL=9  -cr median -dstnodata 0  -bndnodata 7  -srcnodata 0  -srcnodata 3  -srcnodata 4 -srcnodata 5 -srcnodata 6 -srcnodata 7 -srcnodata 8  -srcnodata 9 -srcnodata 10 -srcnodata 11 -srcnodata 12 -srcnodata 13 -srcnodata 14 -srcnodata 15  -srcnodata 16 -srcnodata 17  -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_$day.tif

##### select only 6 bands
gdal_translate  -co COMPRESS=LZW -co ZLEVEL=9 -b 1 -b 2 -b 3 -b 4 -b 5 -b 6 -a_srs EPSG:4326 -a_nodata 0  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_$day.tif   $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_${day}_6bs.tif 

' _ 


echo 1 | xargs -n 1 -P 1  bash -c $' 
B=$1

for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 ) ; do 
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -b $B $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_${day}_${B}b.vrt $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_${day}_6bs.tif
done 

gdalbuildvrt -srcnodata 0 -vrtnodata 0 -separate  -overwrite -a_srs EPSG:4326 $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_series_${B}b.vrt $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_*_${B}b.vrt $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_*_${B}b.vrt $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_*_${B}b.vrt

pkfilter -of GTiff -co COMPRESS=LZW -co ZLEVEL=9 -nodata 0 -f smoothnodata -dz 1 -interp akima -i $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_series_${B}b.vrt -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_${B}b.tif 

pkfilter -of GTiff -co COMPRESS=LZW -co ZLEVEL=9 -nodata 0 -f smoothnodata -dz 1 -interp akima_periodic -i $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_series_${B}b.vrt -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akimaperiodic_${B}b.tif 

for dayin in $(seq 24 46); do 
if [ $dayin -le 32  ]  ; then  day=0$(expr $dayin - 23)  ; fi 
if [ $dayin -ge 33  ]  ; then  day=$(expr  $dayin - 23)  ; fi 

gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -b $dayin  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_${B}b.tif   $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_day${day}_${B}b.tif 
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -b $dayin  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akimaperiodic_${B}b.tif   $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akimaperiodic_day${day}_${B}b.tif 
done 

gdalbuildvrt -srcnodata 0 -vrtnodata 0 -separate  -overwrite  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_${B}b.vrt  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_day*_${B}b.tif

pkfilter -of GTiff -co COMPRESS=LZW -co ZLEVEL=9 -nodata 0 -f savgolay -nl 3 -nr 3 -m 2 -pad replicate -i $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_${B}b.vrt -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_savgolay_${B}b.tif 

pkfilter -of GTiff -co COMPRESS=LZW -co ZLEVEL=9 \
$(for day in  01 02 03 04 05 06 07 08 09 $( seq 10 23 )  ; do  echo "-win"  $(expr $day \\* 16  - 8) ; done) \
$(for day in  01 02 03 04 05 06 07 08 09 10 11 12   ; do  echo "-wout"  $(expr $day \\* 31  - 15) "-fwhm" 50  ; done  )  \
-i $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_${B}b.vrt  -o $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_15predict_${B}b.tif 

for MM in $(seq 1 12); do
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -b $MM $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_15predict_${B}b.tif  $GLADSC/data/${TILENS}_1T/${TILE}_1T/${TILE}_median_akima_15predictM${MM}_${B}b.tif 
done 

' _ 


paste -d " " <( for day in  01 02 03 04 05 06 07 08 09 $( seq 10 23 )  ; do  expr $day \* 16  - 8 ; done   ) \
  <(for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 ) ; do gdallocationinfo -valonly  -geoloc 015E_38N_median_${day}_1b.vrt 15.2866 38.0539  ; done ) \
  <(for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 ) ; do gdallocationinfo -valonly  -geoloc  015E_38N_median_akima_day${day}_1b.tif   15.2866 38.0539  ; done ) \
  <(for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 ) ; do gdallocationinfo -valonly  -geoloc  015E_38N_median_akimaperiodic_day${day}_1b.tif   15.2866 38.0539  ; done ) \
  <( gdallocationinfo -valonly  -geoloc   015E_38N_median_savgolay_1b.tif    15.2866 38.0539   )   > day_orig_akima_akper_savgolay.txt 

paste -d " " <(  for day in  01 02 03 04 05 06 07 08 09 10 11 12   ; do    expr $day \* 31  - 15  ; done   ) \
    <(gdallocationinfo -valonly  -geoloc   015E_38N_median_akima_15predict_1b.tif    15.2866 38.0539 )  > day_15predict.txt


exit 


plot 'day_orig_akima_akper_savgolay.txt' u 1:2 pt 10 ps 2 ,  'day_orig_akima_akper_savgolay.txt' u 1:3 ,   'day_orig_akima_akper_savgolay.txt' u 1:4  ,  'day_orig_akima_akper_savgolay.txt' u 1:5






for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 ) ; do gdallocationinfo -valonly  -geoloc 015E_38N_median_${day}_1b.vrt 15.2866 38.0539  ; done



exit 
