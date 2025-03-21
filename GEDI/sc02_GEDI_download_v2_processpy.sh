#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc02_GEDI_download_v2_processpy.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc02_GEDI_download_v2_processpy.sh.%A_%a.err
#SBATCH --job-name=sc02_GEDI_download_v2_processpy.sh
#SBATCH --mem=50G
#SBATCH --array=1-1216%8
### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc02_GEDI_download_v2_processpy.sh

# wc -l folder_h5_list_germany.txt =   1216 
# wc -l folder_h5_list.txt         =  33081

source ~/bin/gdal3 
source ~/bin/pktools 

export GEDIPR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export GEDISC=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/GEDI
export DATE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if (NR==ID) print $1 }' $GEDIPR/H5_TXT_LIST/folder_h5_list_germany.txt)
export H5=$(  awk -v ID=$SLURM_ARRAY_TASK_ID '{ if (NR==ID) print $2 }' $GEDIPR/H5_TXT_LIST/folder_h5_list_germany.txt)
export H5_NAME=$(basename $H5 .h5)
export OUP_H5=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/GEDI/GEDI02_A.002_h5/$DATE
export OUP_TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/GEDI02_A.002_txt/$DATE
export RAM=/dev/shm

mkdir -p $OUP_H5
mkdir -p $OUP_TXT

# download .h5 files 
echo downloading ${DATE}
ssh transfer "wget  --waitretry=90 --retry-connrefused --tries=120 --no-check-certificate --auth-no-challenge=on  -P $OUP_H5 --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -A .h5 -erobots=off https://e4ftl01.cr.usgs.gov//GEDI_L1_L2/GEDI/GEDI02_A.002/${DATE}/$H5 --progress=bar:force  -o $OUP_H5/${H5_NAME}_log.txt"

module load miniconda/4.10.3
source activate gedi_sub

h5ls $OUP_H5/$H5  && echo $H5  >  $OUP_H5/${H5_NAME}_READY_4PROC.txt

rm -f $OUP_TXT/${H5_NAME}_detailed.txt
python /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/GEDI_Subsetter_detailed_nocrop_v2.py --dir $OUP_H5 --input $H5 --opd $OUP_TXT

# echo "Lat Lon a1_95 a2_95 a3_95 a4_95 a5_95 a6_95 min_rh_95 max_rh_95 BEAM digital_elev elev_low qc_a1 qc_a2 qc_a3 qc_a4 qc_a5 qc_a6 se_a1 se_a2 se_a3 se_a4 se_a5 se_a6 deg_fg solar_ele" > $OUP_TXT/${H5_NAME}_header.txt



