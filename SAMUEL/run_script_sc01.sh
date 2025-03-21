#!/bin/bash


#for var in soc; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc01_download_${var}_${depth}_content_from_SOILGRIDS.sh --export=var=$var,depth=$depthsc01_download_content_from_SOILGRIDS.sh  ;done ;  done


#for var in bdod cfvo nitrogen ocd ocs phh2o soc wrb; do for depth in 100-200cm ; do sbatch --job-name=sc01_download_${var}_${depth}_content_from_SOILGRIDS.sh --export=var=$var,depth=$depthsc01_download_content_from_SOILGRIDS.sh  ;done ;  done


for var in ocs ; do for depth in 0-30cm ; do sbatch --job-name=sc01_download_${var}_${depth}_content_from_SOILGRIDS.sh --export=var=$var,depth=$depthsc01_download_content_from_SOILGRIDS.sh  ;done ;  done
