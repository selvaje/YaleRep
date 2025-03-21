#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH --job-name=sc04_ICESAT2download_byfile.sh 
#SBATCH -p transfer
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc04_ICESAT2download_byfile.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc04_ICESAT2download_byfile.sh.%A_%a.err
#SBATCH --mem=1G
#SBATCH --array=1-796%2

# --array=1-796%2
###### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc04_ICESAT2download_byfile.sh 

export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2
export RAM=/dev/shm

# open the main folder
cd $INP_DIR

# SLURM_ARRAY_TASK_ID=1
export DATE=$( awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print}' $INP_DIR/folderlist_004.txt )
export filename=${DATE}_h5_list_004.txt
export FOLDER=${filename/_h5_list_004.txt} 
export OUP_H5=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/ICESAT2/H5_004/$FOLDER

mkdir -p $OUP_H5
rm -f  $OUP_H5/*

module load miniconda/4.10.3
source activate gedi_sub
source  /gpfs/loomis/project/sbsc/ga254/conda_envs/gedi_sub/lib/python3.1/venv/scripts/common/activate

cat $INP_DIR/H5_TXT_LIST_004/$filename   | xargs -n 1 -P 2 bash -c $' 
FILE=$1
FILENAME=$(basename $FILE .h5 )
FILE_DETAIL=$(basename $FILE .h5 )_detailed.txt
echo $FILE $FILENAME  $FILE_DETAIL

echo  download $FILENAME  file

wget  --waitretry=90 --retry-connrefused --tries=120 --no-check-certificate --auth-no-challenge=on  --user=el_selvaje  -P $OUP_H5  --password=Speleo_74 https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/${DATE}/${FILE}  -o  $OUP_H5/${FILENAME}_log.txt
if [[ "$?" != 0 ]]; then
    touch $OUP_H5/${FILENAME}_DOWNLOAD_FAIL.txt 
else
    touch $OUP_H5/${FILENAME}_DOWNLOAD_DONE.txt 
    h5ls $OUP_H5/$FILE && echo $FILE >  $OUP_H5/${FILENAME}_READY_4PROC.txt 
fi

sleep 30

' _

conda deactivate 
