#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc10_variable_accumulation_intb1_SOILGRIDS_sfd.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc10_variable_accumulation_intb1_SOILGRIDS_sfd.sh.%J.err
#SBATCH --mem=400G

#### AF AU EUA GL NA NAO SA SAO SIO SPO
#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/sand_0-200cm.vrt ; do for BOX in SIO  ; do    sbatch   --export=tif=$tif,BOX=$BOX  --job-name=sc10_var_acc_intb1_SOILGRIDS_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS_sfd.sh ; done ; done 

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/sand_100-200cm.vrt ; do for ID in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt ) ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print $4}' ) ;  sbatch   --export=tif=$tif,BOX=$BOX --mem=${MEM}M --job-name=sc10_var_acc_intb1_SOILGRIDS_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS.sh ; done ; sleep 1200 ; done 

## for checking
## cd /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
## for var in silt clay sand ; do for depth in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm 0-200cm  ; do ll   /vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2/$var/${var}_acc/intb/${var}_${depth}_*_acc.tif  | wc -l   ; done ; done


source ~/bin/gdal3 &> /dev/null
module load StdEnv 

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /gpfs/gibbs/pi/hydro/hydro/stderr  -mtime +2  -name "*.err" | xargs -n 1 -P 2 rm -ifr
# find  /gpfs/gibbs/pi/hydro/hydro/stdout  -mtime +2  -name "*.out" | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

export  SOILGRIDSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export  MERITH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export  RAM=/dev/shm
MEMG=$( awk -v MEM=$MEM 'BEGIN { print int (int(MEM) / 3 ) }' ) 
SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
SOILGRIDSSC=/vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2

export  tifname=$(basename  $tif .vrt )
dir=$(echo $tifname | cut -d "_"  -f 1 )
file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_sfd/${BOX}_box.tif
filename=$(basename $file .tif )
export box=$BOX
export ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo SOILGRIDS file $tifname 
echo box $file
echo coordinates $ulx $uly $lrx $lry
echoerr "file $tifname box $file"
echo "file $tifname box $file"

# run the first time for one var and for all the box

GDAL_CACHEMAX=100000
GDAL_NUM_THREADS=4
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif $MERITH/flow_sfd/flow_sfd_$box.tif &
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/are/all_tif_dis.vrt $MERIT/are/${box}_are.tif & 
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction.tif $MERITH/dir_sfd/dir_sfd_$box.tif & 

# gdal_translate -a_srs EPSG:4326 -r bilinear -ot Float32 -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $tif $RAM/${tifname}_${box}_var.tif
# mkdir -p $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb
# cp $RAM/${tifname}_${box}_var.tif $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif 

cp $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif  $RAM/${tifname}_${box}_var.tif 
wait 

cp $MERIT/are/${box}_are.tif              $RAM/${tifname}_are_sfd_$box.tif   & 
cp $MERITH/dir_sfd/dir_sfd_$box.tif       $RAM/${tifname}_dir_sfd_$box.tif   & 
cp $MERIT/msk_sfd/${box}_msk.tif          $RAM/${tifname}_${box}_msk.tif
wait 

module unload GDAL/3.6.2-foss-2022b
module load StdEnv 

apptainer exec --env=SC=$SC /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project $RAM/${tifname}_${box}_msk.tif  <<'EOF'
r.external input=$RAM/${tifname}_${box}_msk.tif       output=msk  --overwrite 
g.region raster=msk zoom=msk
r.external input=$RAM/${tifname}_${box}_var.tif       output=var  --overwrite 
r.mask raster=msk --o
r.external  input=$RAM/${tifname}_are_sfd_$box.tif    output=are  --overwrite  &
r.external  input=$RAM/${tifname}_dir_sfd_$box.tif    output=dir  --overwrite 
wait 

### adding a small number to avoid to accumulate 0 values that finaly resoult in no-data accumulation.
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(var * are )'   nprocs=4 
# r.out.gdal --o -c -m  createopt='COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES' type=Float32 format=GTiff nodata=-9999 input=var_are  output=$SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${zone}${box}_varTMP.tif

OMP_NUM_THREADS=4  ## input_accumulation=flow
r.flowaccumulation input=dir type=CELL weight=var_are   output=varare_acc nprocs=4  

# r.mapcalc.tiled    'flow_int =  float(flow * 1000)'     nprocs=4   #### cell in grass  -2,147,483,648 to 2,147,483,647 so opt for float 

export GDAL_CACHEMAX=100G
export GDAL_NUM_THREADS=4

##### Float32   Computed Min/Max= 0.001, 5 853 598.000 , * 1000 = 5 853 598 000    
r.out.gdal --o -f -c -m createopt='COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES' nodata=-9999999 type=Int32   input=varare_acc  output=$SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd.tif 


EOF
"
module load StdEnv 
source ~/bin/gdal3 &> /dev/null
gdalinfo -mm $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd.mm 

gdalinfo -mm $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${zone}${box}_varTMP.tif | grep Computed | awk '{gsub(/[=,]/," ", $0); print $3,$4 }' > $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${zone}${box}_varTMP.mm

exit 
