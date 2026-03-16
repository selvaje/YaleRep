#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc01_download.sh.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc01_download.sh.%J.err
#SBATCH --job-name=sc01_download.sh
#SBATCH --mem=5G

##### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/USGS/sc01_download.sh 



USER_AGENT="HydrologyResearchScript - giuseppe.amatulli@gmail.com"

START_DATE="1958-01-01"
END_DATE="2020-12-31"
STATION_LIST="/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_metadata/usgs_sites_ID20_USA.tsv"

mkdir -p usgs_data

cd /nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q
while read STATION; do
    URL="https://waterservices.usgs.gov/nwis/dv/?format=rdb&sites=${STATION}&startDT=${START_DATE}&endDT=${END_DATE}&parameterCd=00060&statCd=00003"
    wget -c -O "${STATION}.rdb" --user-agent="$USER_AGENT" "$URL"
done < $STATION_LIST
