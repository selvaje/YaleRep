
# this script save  the results of sc6_fillsplineAkima_merge_tile_MOYD11A2_allobs.sh  153 161 169 177 185 193 201 209 217 225 and mv to tifcloudcont
    
# cd /tmp/ ; for SENS in MYD MOD ; do for DN in Day Nig ; do  qsub  -v SENS=$SENS,DN=$DN  /u/gamatull/scripts/LST/spline/sc5_allobservation_noenlarge4spline_maskoutIndia-PatagMOYD11A2.sh ; done ; done ; cd -

#PBS -S /bin/bash
#PBS -q normal
#PBS -l select=1:ncpus=24:model=has
#PBS -l walltime=4:00:00
#PBS -N sc5_allobservation_noenlarge4spline_maskoutIndia-PatagMOYD11A2.sh
#PBS -V
#PBS -o /nobackup/gamatull/stdout
#PBS -e /nobackup/gamatull/stderr

echo   /u/gamatull/scripts/LST/spline/sc5_allobservation_noenlarge4spline_maskoutIndia-PatagMOYD11A2.sh
export SENS=$SENS
export DN=$DN
export INSENS=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_mean/wgs84
export OUTSENS=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_spline4fill
export MSK=/nobackup/gamatull/dataproces/LST/${SENS}11A2_mean_msk
export RAMDIR=/dev/shm

cleanram 

# copy the fill spline results to tifcloudcont   si puo cancellare queste line 
# cat /nobackup/gamatull/dataproces/LST/geo_file/list_day.txt | xargs -n 1 -P  23 bash -c $'
# DAY=$1
# cp /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tif  /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tifcloudcont
# ' _

# chreazione del file all'inizio
# echo 009 025 033 041 049 057 065 073 089 097 105 113 121 129 137 145 161 169 177 193 201 209 217 289 297 305 313 321 329 337 345 353 361 | tr " " "\n"  > /nobackup/gamatull/dataproces/LST/geo_file/list_day_PatMYD.txt

# echo 001 009 033 033 041 049 057 065 073 097 105 113 129 137 145 153 161 169 177 201 217 313 321 329 337 345 353 361 | tr " " "\n"    > /nobackup/gamatull/dataproces/LST/geo_file/list_day_PatMOD.txt 

# echo 153 161 169 177 185 193 201 209 217 225  | tr " " "\n"    > /nobackup/gamatull/dataproces/LST/geo_file/list_day_India.txt 

echo $SENS $DN 

rm -f  /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day???_allobs_Fill5obs_CLmsk.tif
                                                                             
if [[ $DN = Nig ]] ; then  
cat /nobackup/gamatull/dataproces/LST/geo_file/list_day_Pat$SENS.txt /nobackup/gamatull/dataproces/LST/geo_file/list_day_India.txt | sort -k 1,1  | uniq  | xargs -n 1 -P 24  bash -c $' 
DAY=$1

ININD=$(grep $DAY /nobackup/gamatull/dataproces/LST/geo_file/list_day_India.txt) 
if [[ -n $ININD ]]  ; then MASKIND="-m /nobackupp8/gamatull/dataproces/LST/MASK/IndiaMya_maskLarg01.tif -msknodata 1 -nodata 0" ; fi 

INPAT=$(grep $DAY /nobackup/gamatull/dataproces/LST/geo_file/list_day_Pat$SENS.txt) 
if [[ -n $INPAT  ]]  ; then MASKPAT="-m /nobackupp8/gamatull/dataproces/LST/MASK/patagonia_maskLarg01.tif -msknodata 1 -nodata 0" ; fi 

pksetmask -co COMPRESS=LZW \
$(echo $MASKIND)  \
$(echo $MASKPAT)  \
-i /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tif \
-o /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif

' _ 

fi


if [[ $DN = Day ]] ; then  
cat  /nobackup/gamatull/dataproces/LST/geo_file/list_day_India.txt  | xargs -n 1 -P 24  bash -c $' 
DAY=$1

pksetmask -co COMPRESS=LZW \
-m /nobackupp8/gamatull/dataproces/LST/MASK/IndiaMya_maskLarg01.tif -msknodata 1 -nodata 0 \
-i /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tif \
-o /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif

' _ 

fi


echo remake the bolean 
cat /nobackup/gamatull/dataproces/LST/geo_file/list_day.txt | xargs -n 1 -P  24 bash -c $'
DAY=$1

if [[ -f /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif ]] ; then 
file=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif
else 
file=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tif
fi 

oft-calc -ot Byte  $file  $MSK/LST_${SENS}_QC_day${DAY}_wgs84_${DN}_allobsBolean.tif <<EOF
1
#1 1 > 0 1 ?
EOF

rm -f $MSK/LST_${SENS}_QC_day${DAY}_wgs84_${DN}_allobsBolean.tif.eq 

' _ 

rm -f   $RAMDIR/LST_${SENS}.vrt  
gdalbuildvrt -overwrite -separate  $RAMDIR/LST_${SENS}.vrt  $MSK/LST_${SENS}_QC_day???_wgs84_${DN}_allobsBolean.tif 

oft-calc -ot Byte  $RAMDIR/LST_${SENS}.vrt  $RAMDIR/${SENS}_LST3k_count_${DN}.tif   <<EOF
1
#1 #2 #3 #4 #5 #6 #7 #8 #9 #10 #11 #12 #13 #14 #15 #16 #17 #18 #19 #20 #21 #22 #23 #24 #25 #26 #27 #28 #29 #30 #31 #32 #33 #34 #35 #36 #37 #38 #39 #40 #41 #42 #43 #44 #45 #46 + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
EOF

echo create $MSK/${SENS}_LST3k_mask_daySUM_wgs84_${DN}_allobs_mask5noobs.tif 

pkcreatect   -min 0 -max 46   > /tmp/color.txt
pkcreatect   -co COMPRESS=LZW -co ZLEVEL=9   -ct  /tmp/color.txt   -i     $RAMDIR/${SENS}_LST3k_count_${DN}.tif  -o  $MSK/${SENS}_LST3k_mask_daySUM_wgs84_${DN}_allobs.tif

# the max value is considered as 1 ; max <= 5  ; this is used in combination of the sea mask to select only pixel with more than 5 obs.                         
pkgetmask -min -1 -max 5 -data 1 -nodata 0 -co COMPRESS=LZW -co ZLEVEL=9   -i  $MSK/${SENS}_LST3k_mask_daySUM_wgs84_${DN}_allobs.tif -o $MSK/${SENS}_LST3k_mask_daySUM_wgs84_${DN}_allobs_mask5noobs.tif
# mask all pixel with les than 5 obs in the year



cat   /nobackup/gamatull/dataproces/LST/geo_file/list_day.txt  | xargs -n 1 -P 24    bash -c $'
DAY=$1
echo masking $DAY  $SENS
# 0 for the cloud and -1 for the sea  and -1 also for the pixel with less than 5 observation
# 0 lst with 0 value
# OBS_${SENS}_QC_day${DAY}_wgs84.tif  exclude pixel with less then one observation over 12 years


if [[ -f /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif ]] ; then 
file=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs_CLmsk.tif
else 
file=/nobackupp8/gamatull/dataproces/LST/${SENS}11A2_splinefill_merge/LST_${SENS}_akima_${DN}_day${DAY}_allobs_Fill5obs.tif
fi 

pksetmask -co COMPRESS=LZW -co ZLEVEL=9  \
-m  /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_mean_msk/${SENS}_LST3k_count_yessea_ct.tif      -msknodata 255   -nodata -1   \
-m  /nobackupp8/gamatull/dataproces/LST/${SENS}11A2_mean_msk/${SENS}_LST3k_count_yessea_ct.tif      -msknodata 0     -nodata -1   \
-m  $MSK/${SENS}_LST3k_mask_daySUM_wgs84_${DN}_allobs_mask5noobs.tif                                -msknodata 1     -nodata -1   \
-i  $file  \
-o  $OUTSENS/LST_${SENS}_QC_day${DAY}_wgs84_${DN}_allobs_mask5noobs_Fill5obs_maskoutIndia.tif

gdalwarp -srcnodata -1  -dstnodata -1  -t_srs EPSG:4326 -r average  -te -180 -90 +180 +90 -tr 0.08333333333333 0.08333333333333  -multi  -overwrite  -co  COMPRESS=LZW -co ZLEVEL=9 $OUTSENS/LST_${SENS}_QC_day${DAY}_wgs84_${DN}_allobs_mask5noobs_Fill5obs_maskoutIndia.tif    $OUTSENS/LST_${SENS}_QC_day${DAY}_wgs84_${DN}_allobs_mask5noobs_Fill5obs_maskoutIndia_10km.tif

' _

cleanram 



qsub -v SENS=$SENS,DN=$DN  /u/gamatull/scripts/LST/spline/sc6_fillsplineAkima_MOYD11A2_allobs.sh

