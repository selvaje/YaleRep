#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc22_broken_basin_clumping.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc22_broken_basin_clumping.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc22_broken_basin_clumping.sh
#SBATCH --mem=20000

# sbatch  /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc22_broken_basin_clumping.sh
# sbatch -d afterany:$( myq | grep   sc20_build_dem_location_4streamMacroTile.sh   | awk '{ print $1}' | uniq)  /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc22_broken_basin_clumping.sh

source ~/bin/gdal
source ~/bin/pktools
source ~/bin/grass

export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

gdalbuildvrt -overwrite  $SC/lbasin_tiles_brokb_msk/all_tif.vrt  $SC/lbasin_tiles_brokb_msk/lbasin_h??v??.tif 

gdal_translate -a_nodata 255 --config GDAL_CACHEMAX 16000 -co TILED=YES -co INTERLEAVE=BAND -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte $SC/lbasin_tiles_brokb_msk/all_tif.vrt $SC/lbasin_tiles_brokb_msk/all_tif.tif 


#### intb = 1 ; brokb = 2 ; nodata 255

# clumping 90m 

cp $SC/lbasin_tiles_brokb_msk/all_tif.tif   $RAM/all_tif.tif  


grass76  -f -text --tmp-location  -c $RAM/all_tif.tif     <<'EOF'

r.external  input=$RAM/all_tif.tif     output=msk    --overwrite
g.region  rast=msk
r.mask raster=msk  cats=1,255  --o

r.clump -d  --overwrite    input=msk    output=brokb_msk_clump 
r.colors -r map=brokb_msk_clump 
r.out.gdal -c -m nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES,INTERLEAVE=BAND,TILED=YES" format=GTiff type=UInt32 input=brokb_msk_clump  output=$SC/lbasin_tiles_brokb_msk/brokb_msk_clump.tif 

EOF 

pkstat -hist -i  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump.tif | sort -k 1,1 -g  > $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist0.txt  
awk '{ if (NR>1) print  }'  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist0.txt  > $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1.txt

# -r in this way the larg pol start first
sort -k 2,2 -rg  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1.txt > $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1_s.txt

# start the next scritp 
# sbatch  

pkfilter -co  INTERLEAVE=BAND -co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx 10  -dy 10 -d 10  -f mode  -i $SC/lbasin_tiles_brokb_msk/brokb_msk_clump.tif -o   $SC/lbasin_tiles_brokb_msk1km/brokb_msk_clump.tif 

