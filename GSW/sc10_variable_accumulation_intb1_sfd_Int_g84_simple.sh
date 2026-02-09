#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 5-00:00:00       # 6 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc10_GSW_sfd_Int_g84_s.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc10_GSW_sfd_Int_g84_s.sh.%J.err

#### AF AU EUA GL NA NAO SA SAO SIO SPO

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/{extent,occurrence,recurrence,seasonality}.vrt  ; do for BOX in AF AU EUA GL NA NAO SA SAO SIO SPO ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt | awk '{ print $2}'); sbatch  --export=tif=$tif,BOX=$BOX --mem=${MEM} --job-name=sc10_sfd_GSW_$(basename $tif .vrt)_$BOX.sh /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc10_variable_accumulation_intb1_sfd_Int_g84_simple.sh ; done; done

MAX_TRIES=10
SLEEP_SEC=60
try=1
while [ $try -le $MAX_TRIES ]; do
    echo "[$(date)] Preflight check attempt $try on $(hostname)"
    # 1. Check HOME readability
    if [ ! -r "$HOME" ] || [ ! -x "$HOME" ]; then
        echo "HOME not readable yet"
        ok=false
    else
        ok=true
    fi
    # 2. Check module system
    if $ok; then
        source /etc/profile.d/modules.sh 2>/dev/null
        module --version >/dev/null 2>&1 || ok=false
    fi
    if $ok; then
        echo "Preflight OK"
        break
    fi
    echo "Preflight failed, sleeping ${SLEEP_SEC}s..."
    sleep $SLEEP_SEC
    try=$((try+1))
done
if [ $try -gt $MAX_TRIES ]; then
    echo "ERROR: GPFS or module system not available after retries"
    exit 1
fi

module load StdEnv 

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /gpfs/gibbs/pi/hydro/hydro/stderr  -mtime +2  -name "*.err" | xargs -n 1 -P 2 rm -ifr
# find  /gpfs/gibbs/pi/hydro/hydro/stdout  -mtime +2  -name "*.out" | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

export  GSWSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW
export  GSWSC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSW
export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export  MERITH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export  RAM=/dev/shm
export  SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export  tifname=$(basename $tif .vrt )
export  dir=$tifname
export  file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_sfd/${BOX}_box.tif
export  box=$BOX

echo GSW file $tifname
echo box $file
echo coordinates $ulx $uly $lrx $lry
echoerr "file $tifname box $file"
echo "file $tifname box $file"

if [ ! -e $GSWSC/$dir/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif ] || [ ! -s $GSWSC/$dir/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.mm ]; then

source ~/bin/gdal3   &> /dev/null
source ~/bin/pktools &> /dev/null

export  xmin=$(getCorners4Gtranslate  $file | awk '{ print $1 }' )
export  ymax=$(getCorners4Gtranslate  $file | awk '{ print $2 }' )
export  xmax=$(getCorners4Gtranslate  $file | awk '{ print $3 }' )
export  ymin=$(getCorners4Gtranslate  $file | awk '{ print $4 }' )

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=8
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif,.vrt"
mkdir -p $GSWSC/${dir}/${dir}_acc_sfd/intb
# cp $RAM/${tifname}_${box}_var.tif $GSWSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif 
# cp $GSWH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif  $RAM/${tifname}_${box}_var.tif 

cp $MERIT/are/${box}_are.tif              $RAM/${tifname}_are_sfd_$box.tif   & 
cp $MERITH/dir_sfd/dir_sfd_$box.tif       $RAM/${tifname}_dir_sfd_$box.tif   & 
cp $MERIT/msk_sfd/${box}_msk.tif          $RAM/${tifname}_${box}_msk.tif
wait 

GDAL_CACHEMAX=$MEMG
GDAL_NUM_THREADS=2 
gdal_translate -of VRT -projwin $xmin $ymax  $xmax $ymin $tif $RAM/${tifname}_${box}_tmp.vrt

# extent 0 1         0 land    255 sea  >  1
# occurrence 0 100   0 land    255 sea  >  100
# recurrence 0 100   0 land    255 sea  >  100 
# seasonality 0 12   0 land    255 sea  >  12  

echo pkreclass 
if [ $tifname = extent  ]  ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=8 -of GTiff -c 255 -r 1   -i $RAM/${tifname}_${box}_tmp.vrt -o $RAM/${tifname}_${box}_var.tif; fi
if [ $tifname = occurrence ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=8 -of GTiff -c 255 -r 100 -i $RAM/${tifname}_${box}_tmp.vrt -o $RAM/${tifname}_${box}_var.tif; fi
if [ $tifname = recurrence ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=8 -of GTiff -c 255 -r 100 -i $RAM/${tifname}_${box}_tmp.vrt -o $RAM/${tifname}_${box}_var.tif; fi
if [ $tifname = seasonality ] ; then 
pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=8 -of GTiff -c 255 -r 12  -i $RAM/${tifname}_${box}_tmp.vrt -o $RAM/${tifname}_${box}_var.tif; fi

rm -f $RAM/${tifname}_${box}_tmp.vrt

gdalwarp -ot Float32  -s_srs EPSG:4326 -t_srs EPSG:4326 -r sum -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=ZSTD -co ZSTD_LEVEL=9 -co INTERLEAVE=BAND -co NUM_THREADS=8 -co TILED=YES -multi -wo NUM_THREADS=8 $RAM/${tifname}_${box}_var.tif $RAM/${tifname}_${box}_var_sum.tif
gdalinfo -mm $RAM/${tifname}_${box}_var.tif ; rm -f $RAM/${tifname}_${box}_var.tif
gdalinfo -mm $RAM/${tifname}_${box}_var_sum.tif
gdal_edit.py -a_nodata 65535  $RAM/${tifname}_${box}_var_sum.tif 
cp $RAM/${tifname}_${box}_var.tif ~/tmp/
cp $RAM/${tifname}_${box}_var_sum.tif ~/tmp/
 
# extent      Min/Max=0.000,11.111
# occurrence  Min/Max=0.000,1111.111
# recurrence  Min/Max=0.000,1111.111
# seasonality Min/Max=0.000,133.333

module unload GDAL/3.6.2-foss-2022b ### this is usefull to allow certen python numpy versions
module unload PKTOOLS/2.6.7.6-foss-2020b

apptainer exec  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project $RAM/${tifname}_${box}_msk.tif  <<'EOF'
r.external input=$RAM/${tifname}_${box}_msk.tif       output=msk  --overwrite 
r.what  map=msk coordinates=3.34999999999997167,-54.42500000000001137
g.region raster=msk zoom=msk
r.mask raster=msk --o

r.external  input=$RAM/${tifname}_${box}_var_sum.tif  output=var  --overwrite &
r.external  input=$RAM/${tifname}_are_sfd_$box.tif    output=are  --overwrite &
r.external  input=$RAM/${tifname}_dir_sfd_$box.tif    output=dir  --overwrite 
wait 
r.what  map=var coordinates=3.34999999999997167,-54.42500000000001137
r.what  map=are coordinates=3.34999999999997167,-54.42500000000001137
r.what  map=dir coordinates=3.34999999999997167,-54.42500000000001137

if [ $tifname = occurrence  ] || [ $tifname = recurrence ]; then
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled 'var_are = float(are / 1111.11111111  * var * 10000.0 )'   nprocs=8 # out of the water shoulb 0 
fi
if [ $tifname = seasonality ] ; then 
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(are / 133.333333   * var * 10000.0 )'   nprocs=8 # out of the water shoulb 0 
fi
if [ $tifname = extent ] ; then 
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(are / 11.11111111  * var *  10000.0 )'   nprocs=8 # out of the water shoulb 0 
fi 

echo var_are
r.info -r var_are
r.what  map=var_are coordinates=3.34999999999997167,-54.42500000000001137

export OMP_NUM_THREADS=8
r.flowaccumulation input=dir type=CELL weight=var_are   output=varare_acc nprocs=8
g.remove -f type=raster name=var_are
echo varare_acc
r.info -r varare_acc
r.what  map=varare_acc coordinates=3.34999999999997167,-54.42500000000001137
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'varare_acc1  = int(varare_acc + 1 )'   nprocs=8
echo varare_acc1
r.info -r varare_acc1
r.what  map=varare_acc1 coordinates=3.34999999999997167,-54.42500000000001137

export GDAL_CACHEMAX=G
export GDAL_NUM_THREADS=1
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE

### max value 2 049 030 016  so the UInt32 is appropriate. 
r.out.gdal --o -f -c -m format=GTiff createopt='BIGTIFF=YES,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256' nodata=0 type=UInt32   input=varare_acc1  output=/tmp/${tifname}_${box}_acc_sfd_Int_g84.tif --overwrite  --verbose 

EOF
"

source ~/bin/gdal3 &> /dev/null

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=4
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
gdallocationinfo -geoloc /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 3.34999999999997167 -54.42500000000001137 
gdalinfo -mm /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $GSWSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.mm
gdal_translate -a_nodata 0  -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co BIGTIFF=YES -co NUM_THREADS=4 -co TILED=YES /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif $GSWSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh $GSWSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 

rm -f $RAM/${tifname}_are_sfd_$box.tif  $RAM/${tifname}_dir_sfd_$box.tif $RAM/${tifname}_${box}_msk.tif $RAM/${tifname}_${box}_var.tif  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 

fi

exit


### for checking
for DIR in  ; do

    GSW_{water,lake,delta,canal,river}.tif

    for BOX in EUA AF AU GL NA NAO SA SAO SIO SPO ; do
ll /vast/palmer/scratch/sbsc/hydro/dataproces/GSW/$DIR/*_acc_sfd/intb/*_${BOX}_acc_sfd_Int_g84.tif
done
echo " " 
done 

#### memory luckup table
for n in $(grep _CELL /vast/palmer/scratch/sbsc/ga254/stderr/sc10_GSW_sfd_Int_g84_s.sh.*.err | tr "." " " | cut -d " " -f 3 | sort | uniq ) ; do
    echo $(head -1 /vast/palmer/scratch/sbsc/ga254/stderr/sc10_GSW_sfd_Int_g84_s.sh.$n.err | cut -d "/" -f 10 | cut -d "_" -f 1) $(seff $n | grep "Average Memory Usag" | awk '{ print int($4 + 50)"G"}')
done > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/mem_request_BOX.txt 



                                                                                 



