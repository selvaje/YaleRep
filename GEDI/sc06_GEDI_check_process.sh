#!/bin/bash 
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc06_GEDI_check_process.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc06_GEDI_check_process.sh.%A_%a.err
#SBATCH --job-name=sc06_GEDI_check_process.sh
#SBATCH --mem=70G



##-p scavenge

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load miniconda
source activate gedi_sub


##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc06_GEDI_check_process.sh

#--- folder where the datasets are located  # export DATE=2019.12.17

export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export RAM=/dev/shm

ls   /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/2019.*/*h5  |  xargs -n 1 -P 2 bash -c $' 
H5_FILE=$1
OUP_H5=$(dirname $H5_FILE)
FILE=$(basename $H5_FILE)

echo $OUP_H5 $FILE

rm -f $OUP_H5/PROCESS_CHECK.txt

python $DIRAPI/GEDI_Subsetter_detailed_nocrop.py --dir $OUP_H5 --input $FILE --opd $OUP_H5

# chek if the processing succeeds or not
if [[ "$?" == 3 ]]; then
	echo No points were found. 

elif test -f "$OUP_H5/${FILE/.h5/_detailed.txt}"; then
	echo Finish processing. ${FILE/.h5/_detailed.txt} exists.
	echo YES >> $OUP_H5/PROCESS_CHECK.txt
        rm -f $OUP_H5/$FILE
else
	echo "Error processing file!"
	echo NO >> $OUP_H5/PROCESS_CHECK.txt
fi


' _ 
