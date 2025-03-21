#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_tiling20d_lbasin_oftbb_prep.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_tiling20d_lbasin_oftbb_prep.sh.%J.err
#SBATCH --job-name=sc30_tiling20d_lbasin_oftbb_prep.sh
#SBATCH --mem=5G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc30_tiling20d_lbasin_oftbb_prep.sh


ulimit -c 0

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO


find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

####  1 608 113   basins   +  0 sea area
####  sum pixel for basins that are cross border

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_1p
awk '{ print $1 , $2   }' lbasin_h??v??_histile.txt  | sort -k 1,1 -g   >  all_lbasin_hist_notsum.txt

/home/ga254/scripts/general/sum.sh  all_lbasin_hist_notsum.txt all_lbasin_hist_sum.txt <<EOF
n
1
0
EOF

rm all_lbasin_hist_notsum.txt
sort -g -k 2,2 all_lbasin_hist_sum.txt > all_lbasin_hist_sum_sP.txt

cat lbasin_h??v??_histile.txt | awk '{ print $1 , $4   }' | sort -k 1,1 -g  >  all_lbasin_hist_tile_number_notmax.txt
awk '{if (NR==1) { old = $1 }
else 	        
	   {   if ($1==old) {
		        if ($2>=max) { max = $2 }
			    } else {
		        print old , max;
			  old = $1 ; 
			      max=$2
			          } 
      }
} END { print $1 , $2 } '   all_lbasin_hist_tile_number_notmax.txt  >   all_lbasin_hist_tile_number_max.txt

rm   all_lbasin_hist_tile_number_notmax.txt

COMPUNIT=50  # 50 larger basins  ## large basin ID => 151 
join -a1 -1 1 -2 1 <( sort -k 1,1   all_lbasin_hist_tile_number_max.txt) <(tail -$COMPUNIT all_lbasin_hist_sum_sP.txt | sort -k 1,1 | awk '{ print $1, NR+150  }'  ) | awk '{ if (NF==2) { print $1,$2} else {print $1,$3}}'  > reclass_computational_unit.txt 


awk '{ print $2  }'    reclass_computational_unit.txt | uniq | sort | uniq | sort -g  > uniq_computational_unit.txt 


sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc31_tiling20d_lbasin_oftbb_TilesLarge.sh

