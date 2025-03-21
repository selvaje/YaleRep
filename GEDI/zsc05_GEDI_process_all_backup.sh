#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 3:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc05_GEDI_process_all.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc05_GEDI_process_all.sh.%A_%a.err
#SBATCH --job-name=sc05_GEDI_process_all.sh
#SBATCH --mem=70G
#SBATCH --array=85-100
######  --array=1-231

# This script contains three steps
# 1) process files from DOWNLOAD_DONE.txt
# 2) output points with 95% percentile

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load miniconda
source activate gedi_sub

##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc05_GEDI_process_all.sh

#--- folder where the datasets are located  # export DATE=2019.12.17

export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export RAM=/dev/shm
export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $INP_DIR/date_2020.txt)
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export OUP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/$check_DIR

# process the .h5 file
# rm -f $OUP_H5/NO_POINT_FOUND_${DATE}.txt  $OUP_H5/PROCESS_DONE_${DATE}.txt $OUP_H5/PROCESS_FAIL_${DATE}.txt $OUP_H5/PROCESS_LAND_DONE_${DATE}.txt

echo "Start processing"

cat $OUP_H5/DOWNLOAD_DONE_$DATE.txt | xargs -n 1 -P 3 bash -c $' 
FILE=$1
FILENAME=$(basename $FILE .h5 )
FILE_DETAIL=$(basename $FILE .h5 )_detailed.txt

## echo Latitude  Longitude rh_95 BEAM digital_elev elev_low q_flag sensit degrade_flag solar_elev rh_a1 rh_a2 rh_a3 rh_a4 # rh_0 rh_5 rh_10 rh_15 rh_20 rh_25 # rh_30 rh_35 rh_40 rh_45 rh_50 rh_55 rh_60 rh_65 rh_70 rh_75 rh_80 rh_85 rh_90 rh_100 rh_a5 rh_a6" >  header_detailed.txt 

####### python $DIRAPI/GEDI_Subsetter_detailed_nocrop.py --dir $OUP_H5 --input $FILE --opd $OUP_H5

# chek if the processing succeeds or not
#if [[ "$?" == 3 ]]; then
#	echo No points were found.
#	echo $FILE >> $OUP_H5/NO_POINT_FOUND_${DATE}.txt  
#elif test -f "$OUP_H5/${FILE/.h5/_detailed.txt}"; then
#	echo Finish processing. ${FILE/.h5/_detailed.txt} exists.
#	echo $FILE >> $OUP_H5/PROCESS_DONE_${DATE}.txt
#else
#	echo "Error processing file!"
#	echo $FILE >> $OUP_H5/PROCESS_FAIL_${DATE}.txt
#fi


####  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GFC/treecover2000/all_tif.vrt  select pixels > 0        tree percentage > 0
####  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt      select pixels != -9999   only in the land 
####  we may use also the https://ghsl.jrc.ec.europa.eu/download.php eliminate points in the urban areas. 

paste -d " " $OUP_H5/$FILE_DETAIL  <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL))  <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GFC/treecover2000/all_tif.vrt  <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL)) | awk  \'{  if($37!=-9999 && $38>0 )  {  $37="" ; $38=""   ;  print } }\' >  $OUP_H5/${FILENAME}_land_tree.txt

if [ -s  $OUP_H5/${FILENAME}_land_tree.txt ] ; then 
	echo "Finish processing. ${FILENAME}_land_tree.txt  exists."
	echo $FILE >> $OUP_H5/PROCESS_LANDTREE_DONE_${DATE}.txt
else 
	rm $OUP_H5/${FILENAME}_land_tree.txt
fi

' _



exit

rclone copy --fast-list --include=*_detailed.txt  $OUP_H5    TobyData:Tree_detailed/$DATE --transfers=40 --checkers=40 --tpslimit=10 --drive-chunk-size=1M --max-backlog 200000 --verbose --log-file=/gpfs/loomis/scratch60/sbsc/zt226/stdout/$DATE.log 
sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc08_rclone_to_googledrive.sh 

## mv $OUP_DIR/*_quintiles.txt $OUP_H5
mv $RAM/*_$DATE.txt $OUP_H5/

if [ -s  t2.txt ] ; then 
echo 'remove it'
fi


paste -d " " $OUP_H5/$FILE_DETAIL  <(gdallocationinfo  -wgs84   -geoloc -valonly    /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt <  <(awk \'{ print $2,$1  }\' $OUP_H5/$FILE_DETAIL ) ) | awk  \'{  if($37!=-9999)  {  $37="" ;  print } }\' >  $OUP_H5/${FILENAME}_land.txt
