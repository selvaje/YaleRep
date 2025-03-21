#!/bin/bash
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 10:00:00
#SBATCH --job-name=sc04_download_proces_delete.sh
#SBATCH -p scavenge
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc04_download_proces_delete.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc04_download_proces_delete.sh.%A_%a.err
#SBATCH --mem=10g
#SBATCH --array=1-796%4


# --array=1-796 
# 1-198 -p scavenge
# This script contains three steps
# 1) download a .h5 file in **_h5_list.txt and store them into folders named with their requiring dates, such as 2018.12.10_h5_list
# 2) process the .h5 file
# 3) if there is an output .txt file, delete the h5.file

# module load miniconda
# module load GDAL/3.1.0-foss-2018a-Python-3.6.4

module load miniconda/4.10.3
source activate gedi_sub

###### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc04_ICESAT2download_proces_delete.sh

export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2
export RAM=/dev/shm

# open the main folder
cd $INP_DIR

# SLURM_ARRAY_TASK_ID=1
export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $INP_DIR/folderlist_004.txt)
export filename=${DATE}_h5_list_004.txt
export check_DIR=${filename/.txt} 
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2/$check_DIR

# check if there is a folder named as $check_DIR
if [ -d "$OUP_H5" ]; then
	echo "Folder ${check_DIR} is already created."
else
	echo "create a new folder named ${check_DIR}."
  	mkdir $OUP_H5
fi

# output folder 
# export OUP_DIR=$INP_DIR/$check_DIR

rm -f $OUP_H5/*  # remove all files in the output folder

# create an empty .txt files to store the downloading failed files if can not find such .txt files
#test -f "$OUP_DIR/DOWNLOAD_FAIL_${DATE}.txt" || touch $OUP_DIR/DOWNLOAD_FAIL_${DATE}.txt
#test -f "$OUP_DIR/PROCESS_FAIL_${DATE}.txt" || touch $OUP_DIR/PROCESS_FAIL_${DATE}.txt
#test -f "$OUP_DIR/NO_POINT_FOUND_${DATE}.txt" || touch $OUP_DIR/NO_POINT_FOUND_${DATE}.txt

# download .h5 files 
# for FILE in $( cat $INP_DIR/H5_TXT_LIST/$filename   ) ; do

cat $INP_DIR/H5_TXT_LIST_004/$filename | xargs -n 1 -P 6 bash -c $' 
FILE=$1
FILENAME=$(basename $FILE .h5 )
FILE_DETAIL=$(basename $FILE .h5 )_detailed.txt
echo $FILE $FILENAME  $FILE_DETAIL


# before downloading, check if the .txt file exists
if test -f "$OUP_H5/${FILE/.h5/_detailed.txt}"; then
    echo "$OUP_H5/${FILE/.h5/_detailed.txt} exists."
else 
    # download .h5 file
    echo ssh transfer-grace "wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password=Tzp19910908 https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}/${FILE} -q"
    ssh transfer-grace "wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password=Tzp19910908 https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}/${FILE} -q"
    
    # check if the .h5 file was completely downloaded
    if [[ "$?" != 0 ]]; then
        echo "Error downloading file!"
        # echo $FILE > $RAM/DOWNLOAD_FAIL_${DATE}_${FILENAME}.txt 
	ssh transfer-grace   "wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password=Tzp19910908 https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}/${FILE} -q" 
	if [[ "$?" != 0 ]]; then
		echo "Error downloading file!"
        	# echo $FILE > $RAM/DOWNLOAD_FAIL_${DATE}_${FILENAME}.txt 
	ssh transfer-grace "wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password=Tzp19910908  https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}/${FILE} -q"
		if [[ "$?" != 0 ]]; then
			echo "Error downloading file!"
        		echo $FILE > $RAM/DOWNLOAD_FAIL_${DATE}_${FILENAME}.txt 
			exit
		fi
	fi
    fi
     
    h5ls $OUP_H5/$FILE && echo $FILE > $RAM/DOWNLOAD_DONE_${DATE}_${FILENAME}.txt 

    echo Now process the files

    if [ -s  $RAM/DOWNLOAD_DONE_${DATE}_${FILENAME}.txt ] ; then 
        
        python $DIRAPI/ICESAT2_ATL08_process_v5.py --dir $OUP_H5 --input $FILE --opd $OUP_H5
        if [[ "$?" == 3 ]]; then
		echo No points were found.
		echo $FILE > $RAM/NO_POINT_FOUND_${DATE}_${FILENAME}.txt 
		rm -f $OUP_H5/$FILE
        elif [[ "$?" == 4 ]]; then
		echo "Error processing file!"
		echo $FILE > $RAM/PROCESS_FAIL_${DATE}_${FILENAME}.txt   #### Here is a problem inside Python code
        
        elif test -f "$OUP_H5/$FILE_DETAIL"; then
		echo Finish processing. ${FILE/.h5/_detailed.txt} exists.
        	echo $FILE > $RAM/PROCESS_DONE_${DATE}_${FILENAME}.txt
        	rm -f $OUP_H5/$FILE

		paste -d " " $OUP_H5/$FILE_DETAIL <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL)) | awk  \'{  if($16>0 )  {  $16="" ;  print } }\' >  $OUP_H5/${FILENAME}_land_tree.txt
             ## paste -d " " $OUP_H5/$FILE_DETAIL <(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt <  <(awk \'{ print $2,$1}\' $OUP_H5/$FILE_DETAIL)) | awk  \'{  if($15>0 )  {  $15="" ;  print } }\' >  $OUP_H5/${FILENAME}_land_tree.txt
		if [ -s  $OUP_H5/${FILENAME}_land_tree.txt ] ; then 
			echo "Finish processing. ${FILENAME}_land_tree.txt  exists."
			echo ${FILENAME}_land_tree.txt  > $RAM/PROCESS_LANDTREE_DONE_${DATE}_${FILENAME}.txt
			# rm -f $OUP_H5/${FILENAME}_detailed.txt 
		else 
			rm -f $OUP_H5/${FILENAME}_land_tree.txt
		fi
        fi
    fi   
fi

' _


echo move the DOWNLOAD and PROCESS txt to the folder
####  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GFC/treecover2000/all_tif.vrt  select pixels > 0        tree percentage > 0
####  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/elv/all_tif.vrt      select pixels != -9999   only in the land 
####  we may use also the https://ghsl.jrc.ec.europa.eu/download.php eliminate points in the urban areas. 

cat $RAM/DOWNLOAD_FAIL_${DATE}_*.txt  >  $OUP_H5/DOWNLOAD_FAIL_${DATE}.txt 
rm -f $RAM/DOWNLOAD_FAIL_${DATE}_*.txt

cat $RAM/DOWNLOAD_DONE_${DATE}_*.txt  >  $OUP_H5/DOWNLOAD_DONE_${DATE}.txt 
rm -f $RAM/DOWNLOAD_DONE_${DATE}_*.txt

cat $RAM/PROCESS_DONE_${DATE}_*.txt    >  $OUP_H5/PROCESS_DONE_${DATE}.txt 
rm -f $RAM/PROCESS_DONE_${DATE}_*.txt

cat PROCESS_FAIL_${DATE}_*.txt         > $OUP_H5/PROCESS_FAIL_${DATE}.txt
rm -f $RAM/PROCESS_FAIL_${DATE}_*.txt 

cat $RAM/NO_POINT_FOUND_${DATE}_*.txt  >  $OUP_H5/NO_POINT_FOUND_${DATE}.txt 
rm -f $RAM/NO_POINT_FOUND_${DATE}_*.txt 

cat $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt >  $OUP_H5/PROCESS_LANDTREE_DONE_${DATE}.txt
rm -f $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt 

echo check if the txt is empty
[[ -s $OUP_H5/PROCESS_FAIL_${DATE}.txt ]] || rm $OUP_H5/PROCESS_FAIL_${DATE}.txt
[[ -s $OUP_H5/NO_POINT_FOUND_${DATE}.txt ]] || rm $OUP_H5/NO_POINT_FOUND_${DATE}.txt 
[[ -s $OUP_H5/DOWNLOAD_FAIL_${DATE}.txt ]] || rm $OUP_H5/DOWNLOAD_FAIL_${DATE}.txt 


exit

# wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password=\'Tzp19910908\' https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.003/${DATE}/${FILE} -q || { handle ; error ; } 


