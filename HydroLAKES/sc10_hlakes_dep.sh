#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_hlakes_dep.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_hlakes_dep.sh.%A_%a.err
#SBATCH --job-name=sc10_hlakes_dep.sh
#SBATCH --mem=10G
#SBATCH --array=1-116 

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc10_hlakes_dep.sh 


source ~/bin/gdal3
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO


export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)

export var=$var

### xmin ymin xmax ymax 

gdal_rasterize -tr 0.000833333333333333  0.000833333333333333 -te $ulx $lry $lrx $uly  -ot UInt32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a Hylak_id   -l  HydroLAKES_polys_v10   $DIR/HydroLAKES_polys_v10_shp/HydroLAKES_polys_v10.shp   $DIR/tif_ID/HydroLAKES_$tile.tif 

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   -projwin $ulx $uly $lrx $lry    $MERIT/dep/all_tif_dis.vrt   $RAM/${tile}_dep.tif  
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/${tile}_dep.tif -msknodata 0 -nodata 0 -i $DIR/tif_ID/HydroLAKES_$tile.tif    -o $DIR/tif_ID/HydroLAKES_dep_$tile.tif 

pkstat --hist -i $DIR/tif_ID/HydroLAKES_$tile.tif      | grep -v " 0"  > $DIR/tif_ID/HydroLAKES_$tile.hist
pkstat --hist -i $DIR/tif_ID/HydroLAKES_dep_$tile.tif  | grep -v " 0"  > $DIR/tif_ID/HydroLAKES_dep_$tile.hist

