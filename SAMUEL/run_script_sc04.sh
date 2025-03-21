#for var in cec bdod cfvo nitrogen ocd soc phh2o; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc04_grow_from_${var}_${depth}_from_SOILGRIDS.sh    --export=var=$var,depth=$depth sc04_SOILGRIDS_grow.sh  ;done ;  done


## ocs  0-30cm

for var in ocs; do for depth in 0-30cm ; do sbatch --job-name=sc04_grow_from_${var}_${depth}_from_SOILGRIDS.sh    --export=var=$var,depth=$depth sc04_SOILGRIDS_grow.sh  ;done ;  done
