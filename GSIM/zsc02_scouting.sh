#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --ntasks=8 --nodes=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=23:59:00
#SBATCH -o /gpfs/loomis/scratch60/sbsc/ls732/stdout/01_GSIM_scouting_%J.out
#SBATCH -e /gpfs/loomis/scratch60/sbsc/ls732/stderr/01_GSIM_scouting_%J.err

#dirIn=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/zip/GSIM_indices/TIMESERIES/monthly
#dirOut=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/Processed/01_Scouting
dirSrp=/gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/
dirRam=/dev/shm

############################
# count station by regions #
############################

#ls ${dirIn}/*.mon | xargs -I %  basename -s .mon %> ${dirOut}/STN_Raw.lst

#wc -l  ${dirOut}/STN_Raw.lst >   ${dirOut}/STN_num.dat
#ls ${dirIn}/*.mon | wc -l >> ${dirOut}/STN_num.dat

#cut -d _ -f1 ${dirOut}/STN_Raw.lst | sort --parallel=20 | uniq -c > ${dirOut}/STN_Rgn_count.dat

##############################
# get time span distribution #
##############################

export dirOut=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/Processed/01_Scouting/Tab_Form
export dirIn=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/zip/GSIM_indices/TIMESERIES/monthly

find ${dirIn} -type f -name '*.mon' | xargs -n 1 -P 8 bash -c $'
fIn=$1 
fname=$(basename -s .mon ${fIn})
echo ${fname}
python3 GSIM_to_Table.py ${fIn} ${dirOut}
' _

export dirIn=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/Processed/01_Scouting/Tab_Form
export dirOut=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/Processed/01_Scouting/TS_Tabl_slim

find ${dirIn} -name *.csv | xargs -n 1 -P 2 bash -c $'
fIn=$1
fname=$(basename -s .csv $fIn)
awk -F, -v OFS=" " \'{print $26,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$17,$18,$21}\'  ${dirIn}/${fname}.csv > ${dirOut}/${fname}.dat
' _
