#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout1/sc03_rerun_procGLAD_ARD_canceled.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr1/sc03_rerun_procGLAD_ARD_canceled.sh.%A_%a.err
#SBATCH --mem=25G 
#SBATCH --job-name=sc03_rerun_procGLAD_ARD_canceled.sh

### scontrol update ArrayTaskThrottle=20 JobId=11423078
### 10433  
### #SBATCH --array=10400-10500 
### 19221
##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/sc02_curl_procGLAD_ARD.sh
###### total array 19221 
##### array 5073   159W_22N  ; 5074 159W_21N

## cd /gpfs/scratch60/fas/sbsc/ga254/stderr1 
## grep "CANCELLED"    sc02_curl_procGLAD_ARD.sh.*.err   | grep ":slurmstepd"  |  awk '{ gsub("_", " ") ; gsub(".err", " ") ; print $5 }' >  /tmp/list_ID.txt 
## join -1 2  -2 1  <(ogrinfo -al -geom=NO /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/MERIT_landsat_tiles.shp | grep "TILE " | awk '{  print NR,  $4 }' | sort -k 2,2 )   <(ls    /gpfs/scratch60/fas/sbsc/ga254/dataproces/GLAD_ARD/data/*/*/DOWNLOAD_FAIL.txt | awk -F "/" '{  print $(NF-1) }' | sort  ) | awk '{ print $2  }' >> /tmp/list_ID.txt 
## sort -g /tmp/list_ID.txt | uniq > /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/list_ID_u.txt

##                 increase every 500
## ls  */*/*_min.tifdone   | awk ' { gsub("/"," ") ; print $2  }  ' | sort  > dir_done.txt  ### 15520  # 17122 
## ls    */   |  grep "_"                                           | sort  > dir_list.txt  ### 19221  # 19217 e' stata rimossa qualcuna?
## join -v 1   -1 1 -2 1  dir_list.txt dir_done.txt                 | sort  > dir_miss.txt  ###  3701  # 2095
## join -1 2  -2 1  <(ogrinfo -al -geom=NO /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/MERIT_landsat_tiles.shp | grep "TILE " | awk '{  print NR,  $4 }' | sort -k 2,2 )   dir_miss.txt | awk '{ print $2  }'    > /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/list_ID_u.txt 
## sbatch --array=$(head -500 /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/list_ID_u.txt | tail -500  | awk '{ printf ("%i,", $1) }' | sed  's/,$//'; echo -e "%10") /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/sc03_rerun_procGLAD_ARD_canceled.sh

ulimit -c 0

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  

source ~/bin/gdal3  
source ~/bin/pktools 

export GLAD=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD
export GLADSC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GLAD_ARD
export RAM=/dev/shm

## SLURM_ARRAY_TASK_ID=5073
export TILE=$(ogrinfo -al -geom=NO $GLAD/metadata/glad_landsat_tiles/MERIT_landsat_tiles.shp | grep "TILE " | awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR) print $4 }')   ### total 19221

export TILENS=$(echo $TILE  | cut -d "_" -f 2) 

echo $TILE 
echo $TILENS
### download 23  * 4 = 96 tif 
rm -f $GLADSC/data/$TILENS/$TILE/DOWNLOAD_FAIL.txt  
rm -f $GLADSC/data/$TILENS/$TILE/DOWNLOAD_DONE.txt  
rm -f $GLADSC/data/$TILENS/$TILE/???.tif

### wget --user=elselvaje --password='wrSDhgTaqkP6aBkK' -O - -A.tif  https://glad.umd.edu/dataset/landsat_v1.1/68N/179W_68N/

for INTER in $(grep -e ^2017 -e ^2018 -e ^2019 -e ^2020 $GLAD/metadata/16d_intervals.csv | awk '{ $1=""; print $0 }' ) ; do
### wait the connection for 10 min per file 
curl --connect-timeout 600  -u elselvaje:wrSDhgTaqkP6aBkK -X GET https://glad.umd.edu/dataset/landsat_v1.1/$TILENS/$TILE/$INTER.tif -o $GLADSC/data/$TILENS/$TILE/$INTER.tif  -q || { handle ; error ; } 
if [[ "$?" != 0 ]]; then
    echo "Error downloading $TILENS/$TILE/$INTER.tif"
    # save the file name into DOWNLOAD_FAIL.txt
    echo $TILENS/$TILE/$INTER.tif  >> $GLADSC/data/$TILENS/$TILE/DOWNLOAD_FAIL.txt  
else
    echo $TILENS/$TILE/$INTER.tif  >> $GLADSC/data/$TILENS/$TILE/DOWNLOAD_DONE.txt  
sleep 3 
FORMAT=$(file $GLADSC/data/$TILENS/$TILE/$INTER.tif | awk '{ print $2  }')
if [ $FORMAT = HTML ] ; then rm $GLADSC/data/$TILENS/$TILE/$INTER.tif  ; fi 
fi  
done 

# QA code   Description Quality
# 0         Nodata                                                          stripes and out of the image
# 1         Land                                                            clear-sky
# 2         Water                                                           clear-sky
# 3         Cloud                                                           Cloud contaminated
# 4         Cloud shadow                                                    Shadow contaminated
# 5         Hillshade                                                       clear-sky 
# 6         Snow                                                            clear-sky
# 7         Haze                                                            Cloud contaminated
# 8         Cloud buffer                                                    Cloud contaminated
# 9         Shadow buffer                                                   Shadow contaminated
# 10        Shadow high likelihood                                          Shadow contaminated
# 11        Additional cloud buffer over land                               clear-sky
# 12        Additional cloud buffer over water                              clear-sky
# 14        Additional shadow buffer over land                              clear-sky
# 15        Land, water detected but not used                               clear-sky
# 16        Additional cloud buffer over land, water detected but not used  clear-sky
# 17        Additional shadow buffer over land, water detected but not used clear-sky

# 1 Normalized surface reflectance of blue band
# 2 Normalized surface reflectance of green band
# 3 Normalized surface reflectance of red band
# 4 Normalized surface reflectance of NIR band
# 5 Normalized surface reflectance of SWIR1 band
# 6 Normalized surface reflectance of SWIR2 band
# 7 Normalized brightness temperature
# 8 Observation quality code (QA)    = -bndnodata 7

### keep only 1

#### create median value for each band using 4 years

# 2016 829 830 831 832 833 834 835 836 837 838 839 840 841 842 843 844 845 846 847 848 849 850 851         not used 
# 2017 852 853 854 855 856 857 858 859 860 861 862 863 864 865 866 867 868 869 870 871 872 873 874         
# 2018 875 876 877 878 879 880 881 882 883 884 885 886 887 888 889 890 891 892 893 894 895 896 897         
# 2019 898 899 900 901 902 903 904 905 906 907 908 909 910 911 912 913 914 915 916 917 918 919 920         
# 2020 921 922 923 924 925 926 927 928 929 930 931 932 933 934 935 936 937 938 939 940 941 942 943 

echo start the composite
export GDAL_CACHEMAX=2000
echo 01 02 03 04 05 06 07 08 09 $( seq 10 23 )   | xargs -n 1 -P 4  bash -c $' 
day=$1
export TILE=$TILE
###### composit only if the file exist. 
pkcomposite $( grep -e ^2017 -e ^2018 -e ^2019 -e ^2020 $GLAD/metadata/16d_intervals.csv | awk -v day=$day  \'{ print $(day+1)  }\' |  xargs  -I {}  -n 1 ls $GLADSC/data/$TILENS/$TILE/{}.tif 2>/dev/null  | xargs  -I {}  -n 1 echo -i  {}  ) -ot UInt16 -co COMPRESS=LZW -co ZLEVEL=9  -cr median -dstnodata 0  -bndnodata 7  -srcnodata 0   -srcnodata 2 -srcnodata 3  -srcnodata 4 -srcnodata 5 -srcnodata 6 -srcnodata 7 -srcnodata 8  -srcnodata 9 -srcnodata 10 -srcnodata 11 -srcnodata 12 -srcnodata 13 -srcnodata 14 -srcnodata 15  -srcnodata 16 -srcnodata 17  -o $RAM/${TILE}_median_$day.tif

##### select only 6 bands  
##### for a crop base on tif the original tif. The pkcomposite create 1x1 pixel more in the LR corner  
gdal_translate -colorinterp undefined  -co COMPRESS=LZW -co ZLEVEL=9 -b 1 -b 2 -b 3 -b 4 -b 5 -b 6 -a_srs EPSG:4326 -a_nodata 0  -projwin $( getCorners4Gtranslate $( ls $GLADSC/data/$TILENS/$TILE/???.tif | head -1 ))  $RAM/${TILE}_median_$day.tif   $RAM/${TILE}_median_${day}_clean.tif  
rm -f $RAM/${TILE}_median_$day.tif
# cp $RAM/${TILE}_median_${day}_clean.tif    $GLADSC/data/$TILENS/$TILE
' _ 

rm -f  $RAM/${TILE}_*.vrt

rm -f $GLADSC/data/$TILENS/$TILE/???.tif

echo  annual aggregation ### calculate min max and median for each band for the year-frame (23 median-images)
export GDAL_CACHEMAX=2000
echo 1 2 3 4 5 6 | xargs -n 1 -P 6  bash -c $'
B=$1

for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 )  ; do 
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -b $B  $RAM/${TILE}_min_max_B${B}_day$day.vrt  $RAM/${TILE}_median_${day}_clean.tif  
done

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -separate $RAM/${TILE}_min_max_B${B}.vrt $RAM/${TILE}_min_max_B${B}_day??.vrt 
pkstatprofile -nodata 0  -co COMPRESS=LZW -co ZLEVEL=9 -f percentile -perc 10 -f percentile -perc 90 -f median  -i $RAM/${TILE}_min_max_B${B}.vrt -o $RAM/${TILE}_min_max_B$B.tif

rm $RAM/${TILE}_min_max_B${B}.vrt 

### extract single band 
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326  -b 1 $RAM/${TILE}_min_B$B.vrt $RAM/${TILE}_min_max_B$B.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326  -b 2 $RAM/${TILE}_max_B$B.vrt $RAM/${TILE}_min_max_B$B.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326  -b 3 $RAM/${TILE}_med_B$B.vrt $RAM/${TILE}_min_max_B$B.tif

# check if each band is less then 10 quantile or higher 90 quantile
for day in 01 02 03 04 05 06 07 08 09 $( seq 10 23 )  ; do 

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -separate $RAM/${TILE}_min_band_B$B.vrt $RAM/${TILE}_min_B$B.vrt $RAM/${TILE}_min_max_B${B}_day$day.vrt

echo percentile bulean operator
### if band2 > band1(min10)  put #2 else 0
oft-calc -ot UInt16   $RAM/${TILE}_min_band_B$B.vrt $RAM/${TILE}_min_band_B${B}_tmp.tif   <<EOF
1
#2 #1 > 0 #2 ?
EOF

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -separate $RAM/${TILE}_max_band_B$B.vrt $RAM/${TILE}_max_B$B.vrt $RAM/${TILE}_min_band_B${B}_tmp.tif

### if band2 < band1(max90)  put #2 else 0
oft-calc -ot UInt16 $RAM/${TILE}_max_band_B$B.vrt $RAM/${TILE}_max_band_B${B}_tmp.tif   <<EOF
1
#2 #1 < 0 #2 ?
EOF
rm $RAM/${TILE}_min_band_B${B}_tmp.tif 
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_srs EPSG:4326 -a_nodata 0 $RAM/${TILE}_max_band_B${B}_tmp.tif  $RAM/${TILE}_day${day}_4median_band_B$B.tif
rm $RAM/${TILE}_max_band_B${B}_tmp.tif  
done 

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -separate $RAM/${TILE}_dayall_4median_B$B.vrt $RAM/${TILE}_day??_4median_band_B$B.tif
pkstatprofile -nodata 0  -co COMPRESS=LZW -co ZLEVEL=9 -f median -i           $RAM/${TILE}_dayall_4median_B$B.vrt -o  $RAM/${TILE}_dayall_4median_B$B.tif

# get the value from 10-90 median and only if 0 fill with the full-median # the last layer is the on top 
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326        $RAM/${TILE}_dayall_4median_full_B$B.vrt $RAM/${TILE}_med_B$B.vrt $RAM/${TILE}_dayall_4median_B$B.tif   
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_srs EPSG:4326 -a_nodata 0  $RAM/${TILE}_dayall_4median_full_B$B.vrt $RAM/${TILE}_dayall_4median_full_B$B.tif

if [ $B -eq 1 ] ; then   ### usefull for final assesment 
gdal_translate  -co COMPRESS=LZW -co ZLEVEL=9 -a_nodata 0 -tr 0.008333333333333333 0.008333333333333333 -r average $RAM/${TILE}_dayall_4median_full_B1.tif $GLADSC/data/$TILENS/$TILE/${TILE}_med_B1.tif
fi 
rm -f $RAM/${TILE}_min_max_B${B}.vrt $RAM/${TILE}_dayall_min_band_B$B.vrt $RAM/${TILE}_dayall_4median_B$B.vrt  $RAM/${TILE}_max_B$B.vrt $RAM/${TILE}_min_B$B.vrt 

# cp $RAM/${TILE}_dayall_4median_B$B.tif $GLADSC/data/$TILENS/$TILE
# cp $RAM/${TILE}_day??_4median_band_B$B.tif   $GLADSC/data/$TILENS/$TILE 
rm -f $RAM/${TILE}_day??_4median_band_B$B.tif
' _ 

rm -f  $RAM/${TILE}_*.vrt

echo  re-aggregate the 6 bands  for min max and median 
export GDAL_CACHEMAX=4000
echo 1 2 3 | xargs -n 1 -P 3  bash -c $'
MMM=$1
if [ $MMM -eq 1  ] ; then F=min    ; fi  
if [ $MMM -eq 2  ] ; then F=max    ; fi  
if [ $MMM -eq 3  ] ; then F=med    ; fi  

if [ $MMM -eq 1 ]  || [ $MMM -eq 2 ] ; then 
for B in 1 2 3 4 5 6 ; do                                                  
gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326 -b $MMM   $RAM/${TILE}_${F}_B$B.vrt $RAM/${TILE}_min_max_B$B.tif
done 

gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite -a_srs EPSG:4326 -separate  $RAM/${TILE}_${F}.vrt    $RAM/${TILE}_${F}_B?.vrt
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_srs EPSG:4326 -a_nodata 0     $RAM/${TILE}_${F}.vrt    $RAM/${TILE}_${F}.tif
else 

gdalbuildvrt -srcnodata 0 -vrtnodata 0  -overwrite -a_srs EPSG:4326  -separate $RAM/${TILE}_dayall_4median_Ball.vrt $RAM/${TILE}_dayall_4median_full_B?.tif
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_srs EPSG:4326 -a_nodata 0      $RAM/${TILE}_dayall_4median_Ball.vrt $RAM/${TILE}_med.tif

fi

module load  Rclone/1.53.0
rclone copy $RAM/${TILE}_${F}.tif  remote:dataproces/GLAD_ARD/data/$TILENS/$TILE
## cp $RAM/${TILE}_${F}.tif $GLADSC/data/$TILENS/$TILE/${TILE}_${F}.tif

if [ -f $RAM/${TILE}_${F}.tif ] ; then  
touch  $GLADSC/data/$TILENS/$TILE/${TILE}_${F}.tifdone
fi 
rm -f $RAM/${TILE}_${F}.tif
 
' _ 

echo remove files 
rm -f $GLADSC/data/$TILENS/$TILE/*.vrt   $RAM/${TILE}*.tif  $RAM/${TILE}_*.vrt
exit 
