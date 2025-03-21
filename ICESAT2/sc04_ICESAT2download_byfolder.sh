#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH --job-name=sc04_ICESAT2download_proces_delete_byfolder.sh
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_ICESAT2download_byfolder.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_ICESAT2download_byfolder.sh.%A_%a.err
#SBATCH --mem=1G
#SBATCH --array=1-796%8

# --array=1-796 
# 1-198 -p scavenge
# This script contains three steps
# 1) download a  .h5 file in **_h5_list.txt and store them into folders named with their requiring dates, such as 2018.12.10_h5_list
# 2) process the .h5 file
# 3) if there is an output .txt file, delete the h5.file

###### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc04_ICESAT2download_byfolder.sh

export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2
export RAM=/dev/shm

# open the main folder
cd $INP_DIR

###  SLURM_ARRAY_TASK_ID=1
export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $INP_DIR/folderlist_004.txt)
export filename=${DATE}_h5_list_004.txt
export check_DIR=${filename/.txt} 
export OUP_H5=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/ICESAT2/$check_DIR

# check if there is a folder named as $check_DIR
if [ -d "$OUP_H5" ]; then
	echo "Folder ${check_DIR} is already created."
else
	echo "create a new folder named ${check_DIR}."
  	mkdir -p $OUP_H5
fi


### rm -f   https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}.zip

wget  --no-check-certificate --auth-no-challenge=on -r --reject "index.html*"  -e robots=off  --user=el_selvaje  --password=Speleo_74   --waitretry=30  --tries=5   --random-wait -w 30  -c    -np -nH  --cut-dirs 3  -P $OUP_H5     https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}.zip   --progress=bar:force:noscroll
if [[ "$?" != 0 ]]; then
    touch $OUP_H5/DOWNLOAD_FAIL_${DATE}.txt 
else
    touch $OUP_H5/DOWNLOAD_DONE_${DATE}.txt 
fi


sleep 60 

exit 


rm -f $INP_DIR/TXT_004/$check_DIR/*

if [ -f  $( ls $OUP_H5/*.h5 | head -1) ] ; then 

module load miniconda/4.10.3
source activate gedi_sub

ls $OUP_H5/*.h5    | xargs -n 1 -P 12 bash -c $'
FILE=$1
FILENAME=$(basename $FILE .h5 )

h5ls $FILE && echo $FILENAME > $RAM/DOWNLOAD_DONE_${DATE}_${FILENAME}.txt
if [ $? -eq 1   ] ; then echo $FILENAME > $RAM/DOWNLOAD_FAIL_${DATE}_${FILENAME}.txt  ; fi  

echo Now process the file $FILENAME

if [ -s $RAM/DOWNLOAD_DONE_${DATE}_${FILENAME}.txt ] ; then         

source  /gpfs/loomis/project/sbsc/ga254/conda_envs/gedi_sub/lib/python3.1/venv/scripts/common/activate

echo python $DIRAPI/ICESAT2_ATL08_process_v5.py --dir $OUP_H5 --input ${FILENAME}.h5 --opd $INP_DIR/TXT_004/$check_DIR
python $DIRAPI/ICESAT2_ATL08_process_v5.py --dir $OUP_H5 --input ${FILENAME}.h5 --opd $INP_DIR/TXT_004/$check_DIR

if [ -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_nopoint.txt ]; then
echo "Bash No points were found in $FILE"
echo $FILENAME > $RAM/NO_POINT_FOUND_${DATE}_${FILENAME}.txt 
rm -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_nopoint.txt 
fi

if [ -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_h5error.txt ]; then
echo "Error processing file $FILE"
echo $FILENAME > $RAM/PROCESS_FAIL_${DATE}_${FILENAME}.txt   #### Here is a problem inside Python code
rm -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_h5error.txt 
fi

if [ -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_detailed.txt ]  ; then
echo "Finish processing ${FILENAME}_detailed.txt exists"
echo $FILENAME > $RAM/PROCESS_DONE_${DATE}_${FILENAME}.txt
	
paste -d " " $INP_DIR/TXT_004/$check_DIR/${FILENAME}_detailed.txt  \
<(gdallocationinfo -wgs84 -geoloc -valonly /gpfs/gibbs/pi/hydro/hydro/dataproces/GFC/treecover2000/all_tif.vrt <  \
<(awk \'{ print $2,$1}\' $INP_DIR/TXT_004/$check_DIR/${FILENAME}_detailed.txt )) | awk  \'{  if($16>0 )  {  $16="" ;  print}}\'  >  $INP_DIR/TXT_004/$check_DIR/${FILENAME}_land_tree.txt

if [ -s $INP_DIR/TXT_004/$check_DIR/${FILENAME}_land_tree.txt ] ; then 
echo "Finish processing ${FILENAME}_land_tree.txt exists."
echo $FILENAME  >  $RAM/PROCESS_LANDTREE_DONE_${DATE}_${FILENAME}.txt
else
rm -f $INP_DIR/TXT_004/$check_DIR/${FILENAME}_land_tree.txt
fi

fi
fi

' _

cat $RAM/DOWNLOAD_FAIL_${DATE}_*.txt  >  $INP_DIR/TXT_004/$check_DIR/DOWNLOAD_FAIL_${DATE}.txt 
rm -f $RAM/DOWNLOAD_FAIL_${DATE}_*.txt

cat $RAM/DOWNLOAD_DONE_${DATE}_*.txt  >  $INP_DIR/TXT_004/$check_DIR/DOWNLOAD_DONE_${DATE}.txt 
rm -f $RAM/DOWNLOAD_DONE_${DATE}_*.txt

cat $RAM/PROCESS_DONE_${DATE}_*.txt   > $INP_DIR/TXT_004/$check_DIR/PROCESS_DONE_${DATE}.txt 
rm -f $RAM/PROCESS_DONE_${DATE}_*.txt

cat $RAM/PROCESS_FAIL_${DATE}_*.txt    > $INP_DIR/TXT_004/$check_DIR/PROCESS_FAIL_${DATE}.txt
rm -f $RAM/PROCESS_FAIL_${DATE}_*.txt 
    
cat $RAM/NO_POINT_FOUND_${DATE}_*.txt  > $INP_DIR/TXT_004/$check_DIR/NO_POINT_FOUND_${DATE}.txt 
rm -f $RAM/NO_POINT_FOUND_${DATE}_*.txt 

cat $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt >  $INP_DIR/TXT_004/$check_DIR/PROCESS_LANDTREE_DONE_${DATE}.txt
rm -f $RAM/PROCESS_LANDTREE_DONE_${DATE}_*.txt 

echo check if the txt is empty
[[ -s $INP_DIR/TXT_004/$check_DIR/PROCESS_FAIL_${DATE}.txt ]]   || rm $INP_DIR/TXT_004/$check_DIR/PROCESS_FAIL_${DATE}.txt
[[ -s $INP_DIR/TXT_004/$check_DIR/NO_POINT_FOUND_${DATE}.txt ]] || rm $INP_DIR/TXT_004/$check_DIR/NO_POINT_FOUND_${DATE}.txt 
[[ -s $INP_DIR/TXT_004/$check_DIR/DOWNLOAD_FAIL_${DATE}.txt ]]  || rm $INP_DIR/TXT_004/$check_DIR/DOWNLOAD_FAIL_${DATE}.txt 


else 

echo  "did not working"
echo   ssh transfer-grace \"wget --random-wait -c -w 5 -A ".h5" -np -nH --cut-dirs 3 -r --no-remove-listing -P $OUP_H5 --user=toby_tang --password=Tzp19910908  https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE} -q\"

fi 


