#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 8 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_Statation_LatLonCorrection.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_Statation_LatLonCorrection.sh.%J.err
#SBATCH --job-name=sc10_Statation_LatLonCorrection.sh
#SBATCH --mem=1G


ulimit -c 0

####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc10_Statation_LatLonCorrection.sh

export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_shp
export SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

### 30959  number of station 

## Lat Long manual correction. 

awk '{  
      if      ($3=="RU_0000001") {print 180 - $1 + 180, 66.41      ,    $3 }
      else if ($3=="KG_0000003") {print   74.535332   , 42.698998  ,    $3 }
      else if ($3=="IT_0000053") {print   14.443881   , 42.3085    ,    $3 }
      else if ($3=="IT_0000071") {print   16.852939   , 40.390756  ,    $3 }
      else if ($3=="IT_0000073") {print   16.811637   , 40.349810  ,    $3 }
      else if ($3=="IT_0000082") {print   16.556      , 38.674110  ,    $3 }
      else if ($3=="IT_0000083") {print   16.558153   , 38.642189  ,    $3 }
      else if ($3=="RU_0000458") {print   31.99761    , 69.54801   ,    $3 }
      else if ($3=="RU_0000465") {print   35.3325384  , 66.4728715 ,    $3 }
      else if ($3=="RU_0000466") {print   34.30403    , 66.67113   ,    $3 }
      else if ($3=="RU_0000284") {print   40.174955   , 44.285776  ,    $3 }
      else if ($3=="ZW_0000053") {print   31.1333     , -21.1667   ,    $3 }
      else if ($3=="ID_0000021") {print   124.843178  , 1.497452   ,    $3 }
      else if ($3=="ES_0000479") {print   -2.591629   , 40.700972  ,    $3 }
      else if ($3=="IE_0000041") {print   -6.956838   , 52.538194  ,    $3 }
      else {print $0}
}'    $IN/station_x_y_gsim_no.txt  > $SNAP/station_x_y_gsim_no_correctManualy.txt 


exit 

echo 180 90 KG_0000003                  > $RAM/station_x_y_gsim_no_compUnit_noCorrectAdj.txt 
