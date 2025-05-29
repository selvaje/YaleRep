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

