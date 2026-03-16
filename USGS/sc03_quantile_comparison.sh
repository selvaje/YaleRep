#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc02_quantile.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc02_quantile.sh.%A_%a.err
#SBATCH --job-name=sc02_quantile
#SBATCH --mem=10G


INPUT_DIR=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q
OUTPUT_DIR=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile


## /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/quantiles_swap/IDs_lonlat_date_Qquantiles.txt                       IDs my IDstation and quantile 
## /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/quantiles/station_catalogueUSGS_IDs_noori_db_lon_lat_area_alt.txt   IDs my IDstation , noori=IDs_USGS 
##  wc -l /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile/*.rdb.ql                          = 5831347 total
##  wc -l /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/noori_quantile_IDs.txt  = 1149933 
join -1 1 -2 2 \
<(cat /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile/*.rdb.ql | sort -k 1,1  ) \
<(cut -d " " -f 1,2  /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/quantiles/station_catalogueUSGS_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2 ) \
> /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/noori_quantile_IDs.txt 

join -1 1 -2 1 \
<(awk '{print $1"_"$4"_"$5, $11}' /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/quantiles_swap/IDs_lonlat_date_Qquantiles.txt | sort -k 1,1  ) \
<(awk '{print $15"_"$2"_"$3, $9}' /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/noori_quantile_IDs.txt | sort -k 1,1)\
     > /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/china_mine.txt 


#  12523963 /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/quantiles_swap/IDs_lonlat_date_Qquantiles.txt
#   1149933 /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/noori_quantile_IDs.txt
#   1140909 /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile_comparison/china_mine.txt

