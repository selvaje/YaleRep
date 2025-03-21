#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_gwm.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_gwm.sh.%J.err
#SBATCH --job-name=sc02_gwm.sh
#SBATCH --mem=40000

####  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GWM/sc02_gwm.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GWM

####  sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GWM/sc02_gwm.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GWM


# RFW (Regularly flooded wetlands)
# This dataset is built from overlaps of inundation datasets
# The legend has three entries:
# 	0: non wet areas
# 	1: RFW Regularly flooded wetlands
# 	2: Lakes (from HydroLAKES)

#gdalwarp -t_srs EPSG:4326 -ot Byte -srcnodata 15 -dstnodata 255 $DIR/RFW/RFW.tif $DIR/RFW/RFW_new.tif

#gdal_edit.py -a_ullr -180 90 180 -90 $DIR/RFW/RFW_new.tif

#pkreclass -nodata 255 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/RFW/RFW_new.tif -o $DIR/out/rfw_reclass.tif -c 2 -r 1


# CW-TCI:
# This dataset is built from overlaps of RFW and groundwater wetland derived from the TCI index (15% of the area with highest TCI values).
# The legend has three entries:
# 	0: non wet areas
# 	1: Groundwater-driven wetlands from TCI (GDW-TCI(15%))
# 	2: Regularly flooded wetlands (RFW)
# 	3: Intersection of RFWs and GDWs
# 	4: Lakes (from HydroLAKES)
#

gdalwarp -t_srs EPSG:4326 -ot Byte -srcnodata 15 -dstnodata 255 $DIR/CW-TCI/CW_TCI.tif $DIR/CW-TCI/CW_TCI_new.tif

gdal_edit.py -a_ullr -180 84 180 -56 $DIR/CW-TCI/CW_TCI_new.tif

pkreclass -nodata 255 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/CW-TCI/CW_TCI_new.tif -o $DIR/out/cw_tci_reclass.tif -c 2 -r 1 -c 3 -r 1 -c 4 -r 1

# CW-WTD:
# This dataset is built from overlaps of RFW and groundwater wetland derived from Fan et al. (2013) for areas with a WTD <= 20 cm
# The legend has five entries:
# 	0: non wet areas
# 	1: Groundwater-driven wetlands from Fan et al. (2013) (GDW-WTD)
# 	2: Regularly flooded wetlands (RFW)
# 	3: Intersection of RFWs and GDWs
# 	4: Lakes (from HydroLAKES)

gdalwarp -t_srs EPSG:4326 -ot Byte -srcnodata 15 -dstnodata 255 $DIR/CW-WTD/CW_WTD.tif $DIR/CW-WTD/CW_WTD_new.tif

gdal_edit.py -a_ullr -180 84 180 -56 $DIR/CW-WTD/CW_WTD_new.tif

pkreclass -nodata 255 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/CW-WTD/CW_WTD_new.tif -o $DIR/out/cw_wtd_reclass.tif -c 2 -r 1 -c 3 -r 1 -c 4 -r 1


exit
