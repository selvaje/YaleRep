#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc10_point4snapingByTiles_flowred.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc10_point4snapingByTiles_flowred.sh.%J.err
#SBATCH --job-name=sc10_point4snapingByTiles_flowred.sh 
#SBATCH --mem=16G

### testing 58    h18v02
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc11_snapingByTiles_flowred.sh

####  wc -l   quantiles/x_y_ID.txt  40813  # this are uniq pare of lat lon 
####  wc -l   quantiles/x_y.txt   orig_txt/x_y_ID_*.txt  41234 29 punti   lost because they are in antartica 
####  wc -l   snapFlow_txt/x_y_snapFlowYesSnap_*.txt   snapFlow_txt/x_y_snapFlowNoSnap_*.txt 41234 
####  wc -l   snapFlow_txt/x_y_snapFlowFinal_stream_flow_*.txt   41213 

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  


#### new coutn

#### wc -l $IN/IDs_x_y.txt    # IDs IDstation                                   ## 41233 
#### wc -l $IN/IDcu_x_y.txt   # IDcu ID cordinate uniq                          ## 40813
#### wc -l $IN/IDs_IDcu_x_y.txt   # IDs IDstation  # IDcu ID cordinate uniq     ## 41233 

#### integrate
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt 
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/usgs/usgs_sites_USA.tsv 
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/grdc/GRDC_Stations.csv 

  #  3616 ANA    done 
  #    17 ArcticGRO inserted as it is 
  #  4790 BOM    no area information ad lat long already accurate 
  #   699 CCCRR  done 
  #    30 CHY    to dificult to find
  #  7926 GRDC   done 
  #  5444 HYDAT  done 
  # 18580 USGS   done 
  #   161 WRIS   to dificult to find



#### improve GRDC
join -1 2 -2 1 <(grep GRDC /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F  "," '{print $1,$8,$7,($9 == "-999" ? "-9999" : $9) }'    /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/grdc/GRDC_Stations.csv | sort -k 1,1 ) | awk '{ 
  # Compare $4 vs $8 → choose more precise longitude
  p4 = match($4, /\./) ? length(substr($4, index($4, ".") + 1)) : 0;
  p8 = match($8, /\./) ? length(substr($8, index($8, ".") + 1)) : 0;
  best_lon = (p8 > p4) ? $8 : $4;
  # Compare $5 vs $9 → choose more precise latitude
  p5 = match($5, /\./) ? length(substr($5, index($5, ".") + 1)) : 0;
  p9 = match($9, /\./) ? length(substr($9, index($9, ".") + 1)) : 0;
  best_lat = (p9 > p5) ? $9 : $5;
  # Handle elevation: if $6 == -9999 and $10 != 0 then use $10, else keep -9999
  area = ($6 == -9999 && $10 != 0) ? $10 : $6;
  # Print selected fields
  print $2, $1, $3, best_lon, best_lat, area  , $7 
}' |   sed 's/-9999\.0\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueGRDC_IDs_noori_db_lon_lat_area_alt.txt 

#### to correct this kind of errors 
#### 2969151 6920 GRDC 103.429264 15.141556 -9999.0 -9999.0 103.429264 15.141556 6297.2
#### 2969510 6968 GRDC 102.779 17.721 -9999.0 -9999.0 102.4146 17.7229 1312.6
#### 3471400 218 GRDC -54.4 -33.25 -9999.0 -9999.0 -54.4019 -33.2419 4677.6
#### 6150300 3211 GRDC 9.379366 42.602313 -9999.0 261.37 9.379983664 42.603210511 54
#### 6242915 3692 GRDC 17.09611111 47.95222222 -9999.0 127.35 17.09611111 47.95222222 0
#### 6854503 5162 GRDC 24.39158 60.420434 -9999.0 40.0 24.39158 60.420434 0

join -1 2 -2 1 -v 1  <(grep GRDC /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F   "," '{print $1,$8,$7,($9 == "-999" ? "-9999" : $9) }'    /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/grdc/GRDC_Stations.csv | sort -k 1,1 ) | awk '{print $2,$1,$3,$4,$5,$6,$7}'  |  sed 's/-9999\.0\b/-9999/g'  >> /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueGRDC_IDs_noori_db_lon_lat_area_alt.txt 

wc -l /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueGRDC_IDs_noori_db_lon_lat_area_alt.txt ### 7926
grep GRDC /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | wc -l ### 7926

################### USGS ################

join -1 2 -2 1 <(grep USGS /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(grep -e  USGS -e USFS  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/usgs/usgs_sites_USA.tsv | awk -F '\t' '{  print int($2),$6,$5,$7,$8}' | sort -k 1,1 ) |  awk '{
  # Compare $4 vs $8 → choose more precise longitude
  p4 = match($4, /\./) ? length(substr($4, index($4, ".") + 1)) : 0;
  p8 = match($8, /\./) ? length(substr($8, index($8, ".") + 1)) : 0;
  best_lon = (p8 > p4) ? $8 : $4;
  # Compare $5 vs $9 → choose more precise latitude
  p5 = match($5, /\./) ? length(substr($5, index($5, ".") + 1)) : 0;
  p9 = match($9, /\./) ? length(substr($9, index($9, ".") + 1)) : 0;
  best_lat = (p9 > p5) ? $9 : $5;
  # Handle elevation: if $6 == -9999 and $10 != 0 then use $10, else keep -9999
  area = ($6 == -9999 && $10 != 0) ? $10 : $6;
  # Print selected fields
  print $2, $1, $3, best_lon, best_lat, area  , $7 
}' |   sed 's/-9999\.0\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueUSGS_IDs_noori_db_lon_lat_area_alt.txt 




### add only one point 
join -1 2 -2 1 -v 1  <(grep USGS  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(grep -e USGS -e USFS /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/usgs/usgs_sites_USA.tsv | awk -F '\t' '{  print int($2),$6,$5,$7,$8}' | sort -k 1,1 ) | awk '{print $2,$1,$3,$4,$5,$6,$7}'  | sed 's/-9999\.0\b/-9999/g' >> /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueUSGS_IDs_noori_db_lon_lat_area_alt.txt 

grep USGS  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | wc -l ## 18580 
wc -l /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueUSGS_IDs_noori_db_lon_lat_area_alt.txt          ## 18580

######################### HYDAT
### in HYDAT no elevation 
join -1 2 -2 1 <(grep HYDAT /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F '\t' '{  print $2,$7,$6,($8 == "" ? "-9999" : $8)}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/hydat/hydat_sel.tsv    | sort -k 1,1 )  |  awk '{ 
  # Compare $4 vs $8 → choose more precise longitude
  p4 = match($4, /\./) ? length(substr($4, index($4, ".") + 1)) : 0;
  p8 = match($8, /\./) ? length(substr($8, index($8, ".") + 1)) : 0;
  best_lon = (p8 > p4) ? $8 : $4;
  # Compare $5 vs $9 → choose more precise latitude
  p5 = match($5, /\./) ? length(substr($5, index($5, ".") + 1)) : 0;
  p9 = match($9, /\./) ? length(substr($9, index($9, ".") + 1)) : 0;
  best_lat = (p9 > p5) ? $9 : $5;
  # Handle area: if $6 == -9999 and $10 != 0 then use $10, else keep -9999
  area = ($6 == -9999 && $10 != 0) ? $10 : $6;
  # Print selected fields
  print $2, $1, $3, best_lon, best_lat, area  , $7
}' |   sed 's/-9999\.0\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueHYDAT_IDs_noori_db_lon_lat_area_alt.txt 

wc -l /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueHYDAT_IDs_noori_db_lon_lat_area_alt.txt # 5444 
grep HYDAT   /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | wc -l # 5444

##### BOM 

grep BOM  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sed 's/-9999\.0\b/-9999/g' > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueBOM_IDs_noori_db_lon_lat_area_alt.txt

### CHY 
grep CHY   /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sed 's/-9999\.0\b/-9999/g' > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueCHY_IDs_noori_db_lon_lat_area_alt.txt

### WRIS
grep WRIS  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sed 's/-9999\.0\b/-9999/g' > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueWRIS_IDs_noori_db_lon_lat_area_alt.txt

### ArcticGRO
grep ArcticGRO  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sed 's/-9999\.0\b/-9999/g' > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueArcticGRO_IDs_noori_db_lon_lat_area_alt.txt

#### ANA

join -1 2 -2 1 <(grep " ANA " /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F ',' '{print $3,$1,$2,($12 == "" ? "-9999" : $12) ,($11 == "" ? "-9999" : $11) }'  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/ana/ana_full_all.csv   | sort -k 1,1 )  |  awk '{
  # Compare $4 vs $8 → choose more precise longitude  
  p4 = match($4, /\./) ? length(substr($4, index($4, ".") + 1)) : 0;  
  p8 = match($8, /\./) ? length(substr($8, index($8, ".") + 1)) : 0;  
  best_lon = (p8 > p4) ? $8 : $4;   
  # Compare $5 vs $9 → choose more precise latitude  
  p5 = match($5, /\./) ? length(substr($5, index($5, ".") + 1)) : 0;                     
  p9 = match($9, /\./) ? length(substr($9, index($9, ".") + 1)) : 0;              
  best_lat = (p9 > p5) ? $9 : $5;            
  # Handle elevation: if $6 == -9999 and $10 != 0 then use $10, else keep -9999     
  area = ($6 == -9999 && $10 != 0) ? $10 : $6;         
  elv =  ($7 == -9999 && $11 != 0) ? $11 : $7;         
  # Print selected fields                            
  print $2, $1, $3, best_lon, best_lat, area  , elv
}' | sed 's/-9999\.0\b/-9999/g' | sed 's/-99999\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueANA_IDs_noori_db_lon_lat_area_alt.txt

wc -l /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueANA_IDs_noori_db_lon_lat_area_alt.txt # 3616
grep " ANA " /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt  | wc -l # 3616

############# CCCRR ##############

join -1 2 -2 1 <(grep " CCCRR " /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F ',' '{  print $1,$4,$3,$11  }'  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/cccrr/catchment_attributes.csv    | sort -k 1,1 )  |  awk '{  print $2, $1, $3, $4 , $5 , $10  , $7 }' | sed 's/-9999\.0\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueCCCRR_IDs_noori_db_lon_lat_area_alt.txt



join -1 2 -2 1 -v 1 <(grep " CCCRR " /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogue_IDs_noori_db_lon_lat_area_alt.txt | sort -k 2,2) <(awk -F ',' '{  print $1,$4,$3,$11  }'  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/cccrr/catchment_attributes.csv    | sort -k 1,1 )   | sed 's/-9999\.0\b/-9999/g'   > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles/station_catalogueCCCRR_IDs_noori_db_lon_lat_area_alt.txt




#########################

														      

join -1 1 -2 1 <( sort -k 1,1   $IN/quantiles/IDs_IDcu_x_y.txt ) <( sort -k 1,1  $IN/quantiles/station_catalogue_IDs_lon_lat_area_alt.txt ) | cut -d " " -f 1,2,3,4,7,8 | sort -k 1 -g > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt.txt

paste -d " " $IN/snapFlow_area/IDs_IDcu_x_y_area_alt.txt \
<(gdallocationinfo -valonly -geoloc $MH/hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment.tif < <(cut -d " " -f 3,4 $IN/snapFlow_area/IDs_IDcu_x_y_area_alt.txt)) \
<(gdallocationinfo  -valonly -geoloc $MH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif  < <(cut -d " " -f 3,4 $IN/snapFlow_area/IDs_IDcu_x_y_area_alt.txt)) \
<(gdallocationinfo  -valonly -geoloc $MH/../MERIT_HYDRO_DEM/elv/all_tif_dis.vrt < <(cut -d " " -f 3,4 $IN/snapFlow_area/IDs_IDcu_x_y_area_alt.txt))  > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev.txt


# $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev.txt
# IDs IDcu        X       Y  areaT altT seg flow_acc           elv
# 1 19187 -179.2500 66.4100  207.0 42.0 0   -9999999           -9999
# 2 29804  -76.7500  5.6300 1436.0 30.0 0   0.0170898530632257 29.1000003814697

#### points that do not need snapping areaT basin +- 10     ### 2825  (already belong to the correct river) 
awk '{ if ($7>0  &&  (($5-$8)/($5+0.1) * 100) > -10  && (($5-$8)/($5+0.1) * 100) < 10  && $5!=-9999.0 )  print $0 }'  $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev.txt  > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_area10.txt  

# points that need snapping    38408  
join -v 1  -1 1 -2 1 <(sort -k 1,1  $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev.txt)  <( awk '{ print $1 }' $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_area10.txt | sort -k 1,1  ) > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10.txt

# points that need snapping    38408   with areaT       16825  #### snapping useing area-10%  as treshold for each point
awk '{ if ( $5>0 ) print $0 }'  $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10.txt > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10_warea.txt  

# points that need snapping    38408   without   area  21354 snaping first and then use snapped lat long to retrive river name.
awk '{ if ( $5<=0 ) print $0 }' $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10.txt > $IN/snapFlow_area/IDs_IDcu_x_y_area_alt_seg_acc_elev_NOarea10_NOwarea.txt 


