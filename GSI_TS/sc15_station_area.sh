#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc15_station_area.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc15_station_area.sh.%A_%a.err
#SBATCH --job-name=sc15_station_area.sh
#SBATCH --mem=100G 
#SBATCH --array=10001-19319

#### #SBATCH  --array=1-19319
#####  sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc15_station_area.sh  

source ~/bin/gdal3   2> /dev/null

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  


read ID lon lat areaT  <<< $(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print $1,$4,$5,$6}'  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/ID_lonOrig_latOrig_lonSnap_latSnap_area.txt)  
export ID=$ID ; export lon=$lon ; export lat=$lat ; export areaT=$areaT

~/bin/echoerr  "$ID $lon $lat $areaT"
         echo  "$ID $lon $lat $areaT"

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_dir 
export IDcomp=$(for file in  dir_*_msk.tif ; do gdallocationinfo -valonly -geoloc $file $lon $lat | awk -v file=$file '{ if ($1>0) print file }'   ; done  | awk '{ gsub("dir_", " ") ; gsub("_msk.tif", " ") ; if (NR==1) printf "%i\n" , $1   }' )

~/bin/echoerr "IDcomp $IDcomp"
        echo  "IDcomp $IDcomp"

cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_dir/dir_${IDcomp}_msk.tif   $RAM/dir_${IDcomp}_msk$ID.tif
cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_are/are_${IDcomp}_msk.tif   $RAM/are_${IDcomp}_msk$ID.tif

gdallocationinfo -valonly -geoloc /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/all_tif_pos_dis.vrt  $lon $lat  > /tmp/accp_mfd$ID.txt

module load GRASS/8.2.0-foss-2022b  2> /dev/null
grass  -f --text --tmp-location  $RAM/dir_${IDcomp}_msk$ID.tif    <<'EOF'

r.external  input=$RAM/dir_${IDcomp}_msk$ID.tif      output=dir       --overwrite 
r.external  input=$RAM/are_${IDcomp}_msk$ID.tif      output=are       --overwrite  

echo r.accumulate for  $lon $lat 
r.accumulate direction=dir weight=are accumulation=acc_acc accumulation_type=FCELL subwatershed=basin_acc  coordinates=$lon,$lat

echo r.stream.basins for  $lon $lat 
r.stream.basins  direction=dir  coordinates=$lon,$lat  basins=basin_bas  memory=60000 
g.region zoom=basin_bas

# r.mapcalc are_basin = if ( basin_bas != null() , are , null() )
r.univar -t map=are zones=basin_bas separator=space  output=/tmp/basin_bas_area$ID.txt  
r.what  map=acc_acc   separator=space  coordinates=$lon,$lat  output=/tmp/accp_sfd$ID.txt 

paste -d " " <(echo $ID $lon $lat) /tmp/accp_mfd$ID.txt <( awk '{ print $3 }' /tmp/accp_sfd$ID.txt) <(awk '{if(NR==2) print $(NF-1) }' /tmp/basin_bas_area$ID.txt) > $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area$ID.txt 
rm -f  /tmp/accp_mfd$ID.txt /tmp/accp_sfd$ID.txt /tmp/basin_bas_area$ID.txt  

# r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16 format=GTiff nodata=-9999 input=basin_bas output=$IN/snapFlow_area/basin_bas$ID.tif
# g.region zoom=basin_acc
# r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16    format=GTiff nodata=-9999  input=basin_acc    output=$IN/snapFlow_area/basin_acc$ID.tif
# r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32  format=GTiff nodata=-9999  input=acc_acc      output=$IN/snapFlow_area/acc_acc$ID.tif
# r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32  format=GTiff nodata=-9999  input=are       output=$IN/snapFlow_area/are$ID.tif

EOF

rm -f   $RAM/dir_${IDcomp}_msk$ID.tif   $RAM/are_${IDcomp}_msk$ID.tif

exit 
rm -f  $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area_all.txt
echo   ID lon lat mfd sfd area   >  $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area_all.txt
cat $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area*.txt  | sort -k 1,1 -g >> $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area_all.txt



join -1 1 -2 1 <( sort -k 1,1  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt/ID_lonOrig_latOrig_lonSnap_latSnap_area.txt) <( sort -k 1,1  $IN/snapFlow_area/ID_lon_lat_mfd_sfd_area_all.txt | cut -d " " -f 1,5 )  | sort -g  >  ID_lon_lat_areaT_sfd.txt

awk '{ print $0, (($6-$7)/($6 + 0.01))*100  }' ID_lon_lat_areaT_sfd.txt  > ID_lon_lat_areaT_sfd_difperc.txt
awk '{ if ($8>-15 && $8 <+15 ) print $0 }' ID_lon_lat_areaT_sfd_difperc.txt > ID_lon_lat_areaT_sfd_difperc_sel.txt
cut -d " " -f 1 ID_lon_lat_areaT_sfd_difperc_sel.txt | sort | uniq > ID_correct_snapping.txt



