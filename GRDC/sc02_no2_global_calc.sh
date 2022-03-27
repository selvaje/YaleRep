#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/no2_global_calc.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/no2_global_calc.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=no2_global_calc.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRDC/no2_global_calc.sh

find  /tmp/     -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

cd  /project/fas/sbsc/ga254/dataproces/GRDC 

# remove some negative value in the runoff  mm/yr over a 30-minute (0.5 degree) pixel.  
pksetmask -of GTiff  -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m runoff/cmp_ro.grd  -msknodata -9999  -p '='  -nodata -9999 \
-m runoff/cmp_ro.grd  -msknodata 0  -p '<'  -nodata 0  -i runoff/cmp_ro.grd   -o /dev/shm/cmp_ro.tif 

# /0.50deg-Area_prj6842.tif   km2 in 1/2 degree 
gdalbuildvrt -te $(getCorners4Gwarp   runoff/cmp_ro.grd )  -allow_projection_difference  -overwrite  -separate  /dev/shm/Overall_TN.vrt  /dev/shm/cmp_ro.tif  /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/0.50deg-Area_prj6842.tif  

# get mm per km2  dm=mm/100  dm=km*10000  ... 10000/100 = 100 first oft-calc
oft-calc -ot Float32  /dev/shm/Overall_TN.vrt  /dev/shm/cmp_ro_km2.tif  <<EOF
1
#1 #2 * 1000 * 
EOF
# gdallocationinfo -geoloc   /dev/shm/cmp_ro_km2.tif    6.2882 47.4625   # 1438521384.38948
 

# impose sea mask -9999
pksetmask -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -m  /dev/shm/cmp_ro.tif  -msknodata -9999   -p '='  -nodata -9999 -i  /dev/shm/cmp_ro_km2.tif -o  runoff/cmp_ro_km2.tif 
rm -f /dev/shm/cmp_ro_km2.tif

# change pixel resolution of the runoff # non piu usato effetuato la divisione con lo 0.5 degree
gdalwarp  -s_srs EPSG:4326   -t_srs EPSG:4326   -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9  -overwrite  -tr 0.0083333333333333333333  0.0083333333333333333333  -srcnodata -9999  -dstnodata  -9999 -r cubic  runoff/cmp_ro_km2.tif     runoff/cmp_ro_1km.tif # this is just a resampling to smoth the border effect  

gdalwarp  -s_srs EPSG:4326   -t_srs EPSG:4326   -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9  -overwrite  -tr 0.0083333333333333333333  0.0083333333333333333333  -srcnodata -9999  -dstnodata  -9999 -r cubic  /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/0.50deg-Area_prj6842.tif    /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/0.50deg-Area_prj6842_1km.tif   

# convert uM to mgN   
# i should do uM/1000 * 14 and I will get mgN/L    # second oft-cal
oft-calc -ot Float32    NO3_TN/map_pred_TN.tif  /dev/shm/map_pred_TN_mg-l.tif    <<EOF
1
#1 1000 / 14 *
EOF
# gdallocationinfo -geoloc   /dev/shm/map_pred_TN_mg-l.tif    6.2882 47.4625  # 2.89827899169922
  
# impose sea mask -1
pksetmask -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -m  NO3_TN/map_pred_TN.tif -msknodata -1  -p '=' -nodata -1 -i /dev/shm/map_pred_TN_mg-l.tif -o  NO3_TN/map_pred_TN_mg-l.tif 
rm /dev/shm/map_pred_TN_mg-l.tif

gdalbuildvrt -allow_projection_difference  -tr 0.008333333333333  0.008333333333333    -te $(getCorners4Gwarp   NO3_TN/map_pred_TN.tif   )   -overwrite  -separate  /dev/shm/Overall_TN.vrt    NO3_TN/map_pred_TN_mg-l.tif   runoff/cmp_ro_1km.tif   /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/0.50deg-Area_prj6842_1km.tif   

# /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/30arc-sec-Area_prj6842.tif

# the 100   convert the mm in dm 
# the 10000 convert the km in dm 

oft-calc -ot Float32   /dev/shm/Overall_TN.vrt    /dev/shm/cmp_ro_TN.tif  <<EOF
1
#1 #2 * #3 / 1000 /
EOF
# gdallocationinfo -geoloc   /dev/shm/cmp_ro_TN.tif    6.2882 47.4625  #  1987.032586929

pksetmask  -ot Float32     -co COMPRESS=DEFLATE -co ZLEVEL=9  \
-m  /dev/shm/cmp_ro_TN.tif   -msknodata  0  -p '<'     -nodata -1 \
-m  runoff/cmp_ro_km2.tif    -msknodata -9999 -p '='   -nodata -1 \
-m  NO3_TN/map_pred_TN.tif   -msknodata -1  -p '='     -nodata -1  -i   /dev/shm/cmp_ro_TN.tif  -o  NO3_TN/cmp_ro_TN.tif

pkfilter -nodata -1  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -f mean -d 10  -dx 10  -dy 10   -i  NO3_TN/cmp_ro_TN.tif   -o  NO3_TN/cmp_ro_TN_10km.tif
pkfilter -nodata -1  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -f mean -d 20  -dx 20  -dy 20   -i  NO3_TN/cmp_ro_TN.tif   -o  NO3_TN/cmp_ro_TN_20km.tif


# find  /tmp/     -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
# find  /dev/shm  -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  



