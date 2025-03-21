#!/bin/bash
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 12:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc05_GEDI_process_all_followDownload_2.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc05_GEDI_process_all_followDownload_2.sh.%J.err
#SBATCH --job-name=sc05_GEDI_process_all_followDownload_2.sh
#SBATCH --mem=70G

# This script contains three steps
# 1) process files from DOWNLOAD_DONE.txt
# 2) output points with 95% percentile

#### cehck for ram usage 
### for ID in $(ls /gpfs/gibbs/pi/hydro/hydro/stderr1/sc05_GEDI_process_all_followDownload_2.sh.*.err | awk -F . '{ print $3  }' ); do seff $ID | grep "Memory Utilized" ; done  | sort -k 2,2 -g

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load miniconda
source activate gedi_sub

#####                 2019.04.21
##### sbatch --export=DATE=$DATE /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc05_GEDI_process_all_followDownload_2.sh
### --- folder where the datasets are located  # export DATE=2019.12.17

export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export RAM=/dev/shm
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export OUP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/$check_DIR
export DATE=$DATE

# process the .h5 file
rm -f $OUP_H5/NO_POINT_FOUND_${DATE}.txt  $OUP_H5/PROCESS_DONE_${DATE}.txt $OUP_H5/PROCESS_FAIL_${DATE}.txt $OUP_H5/PROCESS_LAND_DONE_${DATE}.txt $OUP_H5/PROCESS_LANDTREE_DONE_${DATE}.txt

echo "Start processing $DATE"

cat $OUP_H5/DOWNLOAD_DONE_$DATE.txt | xargs -n 1 -P 2 bash -c $' 
FILE=$1
FILENAME=$(basename $FILE .h5 )
FILE_DETAIL=$(basename $FILE .h5 )_detailed.txt

## echo Latitude  Longitude rh_95 BEAM digital_elev elev_low q_flag sensit degrade_flag solar_elev rh_a1 rh_a2 rh_a3 rh_a4 # rh_0 rh_5 rh_10 rh_15 rh_20 rh_25 rh_30 rh_35 rh_40 rh_45 rh_50 rh_55 rh_60 rh_65 rh_70 rh_75 rh_80 rh_85 rh_90 rh_100 rh_a5 rh_a6" >  header_detailed.txt 

echo "process python $DIRAPI/GEDI_Subsetter_detailed_nocrop.py --dir $OUP_H5 --input $FILE --opd $OUP_H5 "
python $DIRAPI/GEDI_Subsetter_detailed_nocrop.py --dir $OUP_H5 --input $FILE --opd $OUP_H5

# chek if the processing succeeds or not
if [[ "$?" == 3 ]]; then
	echo No points were found.
	echo $FILE > $RAM/NO_POINT_FOUND_${DATE}_${FILENAME}.txt  

elif test -f "$OUP_H5/${FILE/.h5/_detailed.txt}"; then
	echo Finish processing. ${FILE/.h5/_detailed.txt} exists.
        echo $FILE > $RAM/PROCESS_DONE_${DATE}_${FILENAME}.txt
        rm -f $OUP_H5/$FILE
else
	echo "Error processing file!"
	echo $FILE > $RAM/PROCESS_FAIL_${DATE}_${FILENAME}.txt
fi


####  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GFC/treecover2000/all_tif.vrt  select pixels > 0        tree percentage > 0
####  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt      select pixels != -9999   only in the land 
####  we may use also the https://ghsl.jrc.ec.europa.eu/download.php eliminate points in the urban areas. 

paste -d " " $OUP_H5/$FILE_DETAIL  <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL))  <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GFC/treecover2000/all_tif.vrt  <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL)) | awk  \'{  if($148!=-9999 && $149>0 )  {  $148="" ; $149=""   ;  print } }\' >  $OUP_H5/${FILENAME}_land_tree.txt

if [ -s  $OUP_H5/${FILENAME}_land_tree.txt ] ; then 
	echo "Finish processing. ${FILENAME}_land_tree.txt  exists."
	echo ${FILENAME}_land_tree.txt  > $RAM/PROCESS_LANDTREE_DONE_${DATE}_${FILENAME}.txt
	# rm -f $OUP_H5/${FILENAME}_detailed.txt 
else 
	rm -f $OUP_H5/${FILENAME}_land_tree.txt
fi

' _

cat $RAM/PROCESS_DONE_${DATE}_*.txt    >  $OUP_H5/PROCESS_DONE_${DATE}.txt 
rm -f $RAM/PROCESS_DONE_${DATE}_*.txt

cat PROCESS_FAIL_${DATE}_*.txt         > $OUP_H5/PROCESS_FAIL_${DATE}.txt
rm -f $RAM/PROCESS_FAIL_${DATE}_*.txt 

cat $RAM/NO_POINT_FOUND_${DATE}_*.txt  >  $OUP_H5/NO_POINT_FOUND_${DATE}.txt 
rm -f $RAM/NO_POINT_FOUND_${DATE}_*.txt 

cat $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt >  $OUP_H5/PROCESS_LANDTREE_DONE_${DATE}.txt
rm -f $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt 

## check if the $OUP_H5/DOWNLOAD_FAIL_$DATE.txt is empty
[[ -s $OUP_H5/PROCESS_FAIL_${DATE}.txt ]] || rm $OUP_H5/PROCESS_FAIL_${DATE}.txt
[[ -s $OUP_H5/NO_POINT_FOUND_${DATE}.txt ]] || rm $OUP_H5/NO_POINT_FOUND_${DATE}.txt 

###### lunch the download for the following month 

LASTDATE=$(grep  $( echo $DATE | awk -F . '{ print $1 "."  $2  }'   )     /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/date_2020.txt | tail -1)

if [ "$DATE" =  "$LASTDATE" ] ; then
MONTH=$(grep  $DATE   /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/date_2020.txt  |  awk -F . '{ print $1 "."  $2  }'   )
echo current $MONTH
MONTHPLUS=$(grep  $MONTH -A 1  <(awk -F . '{ print $1 "."  $2  }'   /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/date_2020.txt  | sort | uniq ) |  tail -1 )
echo next $MONTHPLUS
narray=$(grep $MONTHPLUS  /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/date_2020.txt | wc -l )  
sbatch --export=YYYYMM=$MONTHPLUS   --array=1-$narray /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc02_GEDI_download_all_2.sh
fi



