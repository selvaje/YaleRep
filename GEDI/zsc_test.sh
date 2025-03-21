#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc_temp.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc_temp.sh.%A_%a.err
#SBATCH --job-name=sc_temp.sh
#SBATCH --mem=30G


module load miniconda
source activate gedi_sub

# This script contains three steps
# 1) download all .H5 files into scratch60/sbsc/zt226/dataproces/GEDI/ folders
# 2) output DOWNLOAD_DONE and DOWNLOAD_FAIL txt files

##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc_test.sh


export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/2019.04.18_h5_list

FILE=GEDI02_A_2019108185226_O01971_T00922_02_001_01.h5

python $DIRAPI/GEDI_Subsetter_detailed_nocrop.py --dir $OUP_H5 --input $FILE --opd $OUP_H5
