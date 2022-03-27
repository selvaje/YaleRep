#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 10:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_crop_input.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_crop_input.sh.%J.err
#SBATCH --job-name=sc01_crop_input.sh
#SBATCH --mem=40G

source ~/bin/gdal3

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc01_crop_input.sh

MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT/geomorphometry_90m_wgs84
ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/input

# for TOPO in geom aspect aspect-sine cti dev-scale dxx dy eastness pcurv roughness slope tcurv tri aspect-cosine convergence dev-magnitude dx dxy dyy elev-stdev northness rough-magnitude rough-scale spi tpi vrm ; do 
#     gdalbuildvrt -overwrite $MERIT/${TOPO}/all_${TOPO}_90M.vrt $MERIT/${TOPO}/${TOPO}_90M_???????.tif 
#     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $MERIT/${TOPO}/all_${TOPO}_90M.vrt $ONCHO/input/geomorpho90m/${TOPO}_nig.tif 
# done 

# HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0

# for HYDROD in   flow.index  r.stream.channel  r.stream.distance  r.stream.order  r.stream.slope  r.watershed  ; do 
# for DIR in $(ls $HYDRO/$HYDROD ) ; do 
#     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $HYDRO/$HYDROD/$DIR/$(basename $DIR _tiles20d).vrt $ONCHO/input/hydrography90m/$(basename $DIR _tiles20d)_nig.tif 
# done 
# done 

# CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio

# for CHELSAD  in $CHELSA/CHELSA_bio*_1981-2010_V.2.1.tif  ; do
#     filename=$(basename $CHELSAD _1981-2010_V.2.1.tif )
#     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $CHELSAD  $ONCHO/input/chelsa/${filename}_nig.tif
# done

SOILT=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILTEMP/input

for SOIL  in $SOILT/*.tif  ; do
     filename=$(basename  $SOIL .tif)
     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $ONCHO/soiltemp/${filename}_nig.tif
done


SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS

for SOIL in $(ls $SOILGRIDS/*/*_WeigAver.tif | grep  -e _acc  )  ; do
     filename=$(basename  $SOIL  .tif)
     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $ONCHO/soilgrids/${filename}_acc_nig.tif
done


for SOIL in $(ls $SOILGRIDS/*/*_WeigAver.tif |  grep -v  -e _acc -e out_  )  ; do
     filename=$(basename  $SOIL  .tif)
     gdal_translate -projwin 2 15 15 4 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $ONCHO/soilgrids/${filename}_nig.tif
done

