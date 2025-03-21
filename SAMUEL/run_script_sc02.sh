#!/bin/bash

#for var in bdod cfvo nitrogen ocd ocs phh2o wrb; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc02_merge_tiles_from_${var}_${depth}_from_SOILGRIDS.sh    --export=var=$var,depth=$depth sc02_merge_tiles_from_SOILGRIDS.sh  ;done ;  done

for var in bdod  nitrogen  wrb; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm ; do sbatch --job-name=sc02_merge_tiles_from_${var}_${depth}_from_SOILGRIDS.sh    --export=var=$var,depth=$depth 
sc02_merge_tiles_from_SOILGRIDS.sh  ;done ;  done

## forget ocs for now 0-30cm
