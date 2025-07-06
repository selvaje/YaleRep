#!/bin/bash
# List of US state codes
USGS=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/usgs

states=(AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY PR VI GU AS MP DC)


rm -f $USGS/usgs_sites.tsv
for state in "${states[@]}"; do
  echo "Checking $state..."
  # Retrieve expanded site metadata for that state
wget -O $USGS/usgs_sites.tsv  "https://waterservices.usgs.gov/nwis/site/?format=rdb&stateCd=$state&siteType=SP,ST,LK&siteOutput=expanded"
awk -F '\t' '{ OFS="\t" ; if (NF==42) { print $1,$2,$3,$4,$7,$8,($30 == "" ? "-9999" : $30), ($20 == "" ? "-9999" : $20) } }' $USGS/usgs_sites.tsv | grep -v 5s  > $USGS/usgs_sites_$state.tsv
rm -f $USGS/usgs_sites.tsv
done
echo combine 
head -1 $USGS/usgs_sites_AL.tsv > $USGS/usgs_sites_USA.tsv
grep -h  -v agency_cd  $USGS/usgs_sites_??.tsv >> $USGS/usgs_sites_USA.tsv
# rm -f $USGS/usgs_sites_??.tsv


###  $USGS/usgs_sites_USA.tsv  contain USGS + other entity . The USGS code (field 2) is unque for observation.
### grep USGS  usgs_sites_USA.tsv | cut  -d $'\t'  -f 7 | grep     "\-9999"  | wc -l   = drain_area_va 129391
### grep USGS  usgs_sites_USA.tsv | cut  -d $'\t'  -f 7 | grep -v  "\-9999"  | wc -l   = drain_area_va  79588

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/hydat 
wget -O Hydat_sqlite3_20250415.zip "https://collaboration.cmc.ec.gc.ca/cmc/hydrometrics/www/Hydat_sqlite3_20250415.zip"
unzip Hydat_sqlite3_20250415.zip

sqlite3 -header -separator $'\t' Hydat.sqlite3 "SELECT * FROM STATIONS;" > hydat_full.txt

## DRAINAGE_AREA_GROSS
## The total contributing area upstream of the station, including both natural flow and regulated or diverted flow.
## Includes upstream artificial diversions (e.g., dams, canals)
## May include areas that do not always contribute flow (e.g., due to reservoirs, inter-basin transfers, or seasonal drying)
## Think of this as the maximum theoretical upstream area.

awk -F '\t' '{   OFS="\t" ;   print "HYDAT" ,  $1,$2,$3,$5,$7,$8,$9}' hydat_full.txt > hydat_sel.tsv   


################# bom
echo '"long_name","name","stationId","stationNo","latitude","longitude"'  > stations.csv 
jq -r '.features[] | [.properties.long_name, .properties.name, .properties.stationId, .properties.stationNo, (.geometry.coordinates[1] // ""), (.geometry.coordinates[0] // "")] | @csv' stations.json >> stations.csv 


####### ANA
### manual download  https://dadosabertos.ana.gov.br/search?collection=dataset&q=estacoes%20fluviometricas

########## CCCRR
#### manual download https://www.cr2.cl/camels-cl/ 
/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/cccrr/catchment_attributes.csv
