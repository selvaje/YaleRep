#!/bin/bash
#SBATCH -p day
#SBATCH -J sc03_neg_imp_250.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc03_cost_250.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc03_cost_250.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc03_neg_imp_250.sh
# bsub -W 24:00 -M 100000 -R "rusage[mem=100000]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc03_neg_imp_250.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc03_net_imp_250.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc03_neg_imp_250.sh

module load Libs/ARMADILLO/7.700.0 

export DIR=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_watershad

rm -rf /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/GSHL/grassdb/cost250
gdal_edit.py -a_nodata 0 $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_WGS84_core.tif 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/GSHL/grassdb/ cost250  $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_WGS84_core.tif

# source /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh   $DIR/grassdb/cost/PERMANENT 

g.rename   raster=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_WGS84_core,core
g.region   rast=core 
r.in.gdal  in=$DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_WGS84.tif   output=impervius    --overwrite   memory=2047 
r.mapcalc " impervius_neg =  ( 1 - impervius )   "  --overwrite

# unit preparation 

for UNIT in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810 497_338 3562_333 ; do 

NORTH=$(pkinfo -te   -i /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk.tif | awk '{ print $NF  }' )

if  (( $(bc <<< "$NORTH  >  80") ))  ; then 
geo_string=$(getCorners4Gtranslate UNIT${UNIT}msk.tif | awk  '{ print $1,80,$3,$4   }')
gdal_translate -projwin $geo_string  -co COMPRESS=DEFLATE -co ZLEVEL=9 /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk.tif /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk4GHS.tif
else 
echo cp UNIT${UNIT}msk.tif 
cp /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk.tif /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk4GHS.tif
fi 

r.in.gdal in=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_unit/UNIT${UNIT}msk4GHS.tif out=UNIT$UNIT --overwrite  
done 


