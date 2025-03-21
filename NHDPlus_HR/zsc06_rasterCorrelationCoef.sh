#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_rasterCorrelationCoef.sh.%J.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_rasterCorrelationCoef.sh.%J.err
#SBATCH --job-name=sc06_rasterCorrelationCoef.sh
#SBATCH --mem=50G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc06_rasterCorrelationCoef.sh

module load R/3.5.3-foss-2018a-X11-20180131

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_corr 

paste -d " " <(awk '{print $1/10000 }' $NHDP/NHDP_flow_*_90m_mskstr.txt) <(cat  $NHDP/MERIT_flow_*_90m_mskstr.txt) <(cat  $NHDP/HYDRO_flow_*_90m_mskstr.txt)  > $NHDP/NHDP_MERIT_HYDRO_flow_90m_mskstr.txt

paste -d " " <(awk '{print log($1/10000) }' $NHDP/NHDP_flow_*_90m_mskstr.txt) <(awk '{print log($1)}' $NHDP/MERIT_flow_*_90m_mskstr.txt) <(awk '{print log($1)}' $NHDP/HYDRO_flow_*_90m_mskstr.txt) > $NHDP/NHDP_MERIT_HYDRO_log_flow_90m_mskstr.txt

~/scripts/general/pearson_awk.sh  $NHDP/NHDP_MERIT_HYDRO_flow_90m_mskstr.txt 1 2  > $NHDP/NHDP_MERIT_cor_atpixel.txt
~/scripts/general/pearson_awk.sh  $NHDP/NHDP_MERIT_HYDRO_flow_90m_mskstr.txt 1 3  > $NHDP/NHDP_HYDRO_cor_atpixel.txt

~/scripts/general/pearson_awk.sh  $NHDP/NHDP_MERIT_HYDRO_log_flow_90m_mskstr.txt 1 2 > $NHDP/NHDP_MERIT_cor_log_atpixel.txt
~/scripts/general/pearson_awk.sh  $NHDP/NHDP_MERIT_HYDRO_log_flow_90m_mskstr.txt 1 3 > $NHDP/NHDP_HYDRO_cor_log_atpixel.txt

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_corr  
~/scripts/general/spearman_awk.sh NHDP_MERIT_HYDRO_flow_90m_mskstr.txt 1 2  > NHDP_MERIT_spea_atpixel.txt
~/scripts/general/spearman_awk.sh NHDP_MERIT_HYDRO_flow_90m_mskstr.txt 1 3  > NHDP_HYDRO_spea_atpixel.txt

~/scripts/general/spearman_awk.sh NHDP_MERIT_HYDRO_log_flow_90m_mskstr.txt 1 2 > NHDP_MERIT_spea_log_atpixel.txt
~/scripts/general/spearman_awk.sh NHDP_MERIT_HYDRO_log_flow_90m_mskstr.txt 1 3 > NHDP_HYDRO_spea_log_atpixel.txt

exit 

awk '{  if ($1>1 && $2>1 && $3>1  ) print log($1) , log($2) , log($3)  }' NHDP_MERIT_HYDRO_flow_90m_mskstr.txt > NHDP_MERIT_HYDRO_flow_90m_mskstr_lr1.txt

awk 'NR%100==0'  NHDP_MERIT_HYDRO_flow_90m_mskstr_lr1.txt > NHDP_MERIT_HYDRO_flow_90m_mskstr_lr1_100.txt
awk 'NR%10==0'   NHDP_MERIT_HYDRO_flow_90m_mskstr_lr1.txt > NHDP_MERIT_HYDRO_flow_90m_mskstr_lr1_10.txt

