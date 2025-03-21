#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 2:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc25_tiling20d_ct_table_create.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc25_tiling20d_ct_table_create.sh.%J.err
#SBATCH --job-name=sc25_tiling20d_ct_table_create.sh
#SBATCH --mem=40G

#### 116  tiles 20 degree full 
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc25_tiling20d_ct_table_create.sh
#### sbatch  --dependency=afterany:$( myq | grep sc22_tiling20d_lbasin_sieve.sh | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc25_tiling20d_lbasin_reclass.sh

ulimit -c 0
source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

echo create ct table  for lbasin basin outlet stream dir

cat $SCMH/lbasin_tiles_final20d/lbasin_h??v??.hist | awk '{ print $1 }' | sort -g | uniq  | awk '{ print $1 , NR-1 }'  >  $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_all.txt
wc=$(  wc -l $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_all.txt  | awk '{ print $1 -1 }' )
paste -d " " <( awk '{ print $2 }' $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_all.txt)  <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0 ; shuf -i 1-255 -n $wc -r) | awk '{ if (NR==1) {print $0 , 0 } else { print $0 , 255 }}' > $SCMH/lbasin_tiles_final20d_1p/lbasin_hist_ct.txt

echo basin outlet stream dir | xargs -n 1 -P 4 bash -c $'
var=$1 
cat $SCMH/${var}_tiles_final20d_1p/${var}_h??v??.hist | awk \'{  print $1  }\' | sort -g | uniq  | awk \'{ print  $1 , NR-1 }\'  >  $SCMH/${var}_tiles_final20d_1p/${var}_hist_all.txt 
wc=$(  wc -l $SCMH/${var}_tiles_final20d_1p/${var}_hist_all.txt  | awk \'{ print $1 -1 }\' )
paste -d " " <( awk \'{ print $2 }\' $SCMH/${var}_tiles_final20d_1p/${var}_hist_all.txt  )  <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0 ; shuf -i 1-255 -n $wc -r) | awk \'{ if (NR==1) {print $0 , 0 } else { print $0 , 255 }}\' > $SCMH/${var}_tiles_final20d_1p/${var}_hist_ct.txt
' _ 

# start to merge the results 

sbatch  --dependency=afterany:$(squeue -u $USER   -o "%.9F %.10K %.4P %.80j %3D%2C%.8T %.9M  %.9l  %.S  %R" | grep sc25_tiling20d_ct_table_create.sh | awk '{ print $1  }' | uniq ) /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc26_tiling20d_lbasin_reclass_ctcreate.sh

# sbatch  --dependency=afterany:$(squeue -u $USER   -o "%.9F %.10K %.4P %.80j %3D%2C%.8T %.9M  %.9l  %.S  %R" | grep   sc25_tiling20d_lbasin_reclass.sh  | awk '{ print $1  }' | uniq )    /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc24_tiling20d_lbasin_oftbb_prep.sh
