#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_basin_rasterize_disp.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_basin_rasterize_disp.sh.%J.err
#SBATCH --job-name=sc11_basin_rasterize_disp.sh
#SBATCH --mem=20G

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRDC/sc11_basin_rasterize_disp.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export WMO=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRDC/WMO_tif
export RAM=/dev/shm
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# camptch & alaska   # area in displacement from -180 -169 to 180 191   nord 72 south   64

for tile in h00v00  h00v02;  do   
#### masking the west 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 1 -nodata 0  -i $WMO/wmobb_basins_${tile}.tif -o $WMO/wmobb_basins_${tile}_msk.tif 
gdal_edit.py -a_nodata 0 $WMO/wmobb_basins_${tile}_msk.tif
###  transpose west to east
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 0 -nodata 0 -i $WMO/wmobb_basins_${tile}.tif -o $WMO/wmobb_basins_${tile}_tmp.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $WMO/wmobb_basins_${tile}_tmp.tif | awk '{print $1 + 360, int($2), $3 + 360, int($4)}') $WMO/wmobb_basins_${tile}_tmp.tif $WMO/wmobb_basins_${tile}_dis.tif
gdal_edit.py -a_nodata 0 $WMO/wmobb_basins_${tile}_dis.tif
rm $WMO/wmobb_basins_${tile}_tmp.tif
done

#### without displacement 
gdalbuildvrt -overwrite  -srcnodata 0 -vrtnodata  0  $WMO/all_tif.vrt  $WMO/wmobb_basins_h??v??.tif 
rm -f $WMO/all_tif_shp.* 
gdaltindex $WMO/all_tif_shp.shp $WMO/wmobb_basins_h??v??.tif 

#### with displacement 
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $WMO/all_tif_dis.vrt $(ls $WMO/wmobb_basins_h??v??.tif | grep -v h00v00 | grep -v h00v02) $WMO/wmobb_basins_h00v00_dis.tif $WMO/wmobb_basins_h00v02_dis.tif $WMO/wmobb_basins_h00v02_msk.tif $WMO/wmobb_basins_h00v00_msk.tif

rm  -f   $WMO/all_tif_dis_shp.*
gdaltindex $WMO/all_tif_dis_shp.shp $WMO/all_tif_dis.vrt $(ls $WMO/wmobb_basins_h??v??.tif | grep -v h00v00 | grep -v h00v02) $WMO/wmobb_basins_h00v00_dis.tif $WMO/wmobb_basins_h00v02_dis.tif $WMO/wmobb_basins_h00v00_msk.tif $WMO/wmobb_basins_h00v02_msk.tif

######  1k rest 
GDAL_CACHEMAX=14000
gdal_translate -tr 0.00833333333333333  0.00833333333333333  -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $WMO/all_tif.vrt       $WMO/all_tif_1km.tif
gdal_translate -tr 0.00833333333333333  0.00833333333333333  -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $WMO/all_tif_dis.vrt   $WMO/all_tif_dis_1km.tif

