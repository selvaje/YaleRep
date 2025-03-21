#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_hlakes_dep_rec.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_hlakes_dep_rec.sh.%A_%a.err
#SBATCH --job-name=sc11_hlakes_dep_rec.sh
#SBATCH --mem=10G
#SBATCH --array=1-116 

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc11_hlakes_dep_rec.sh
# test  

source ~/bin/gdal3
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO


export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)

export var=$var


### run after sc10 
# join -1 1 -2 1 -a 1 <( awk '{print $1 }'   $DIR/tif_ID/HydroLAKES_??????.hist  | sort -k 1,1   | uniq  )  \
#                     <( awk '{if ($1 != 0) print $1 , 1  }'  $DIR/tif_ID/HydroLAKES_dep_??????.hist | sort -k 1,1  | uniq  ) \
#                     | awk '{if ( $2=="" ) {print $1, 0} else {print $1, $1 }  }'  > $DIR/tif_ID/HydroLAKES_dep_rec.txt

### xmin ymin xmax ymax 


pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9  -code  $DIR/tif_ID/HydroLAKES_dep_rec.txt   -i $DIR/tif_ID/HydroLAKES_$tile.tif  -o $DIR/tif_ID/HydroLAKES_dep_rec_$tile.tif 
pkstat --hist -i $DIR/tif_ID/HydroLAKES_dep_rec_$tile.tif      | grep -v " 0"   > $DIR/tif_ID/HydroLAKES_dep_rec_$tile.hist

exit 
gdalbuildvrt   -overwrite  -srcnodata 0  -vrtnodata 0   all_tif.vrt  HydroLAKES_dep_rec_??????.tif 

