#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_tiling20d_TERRA_sfd_Int_g84.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_tiling20d_TERRA_sfd_Int_g84.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=30G

### --array=1-116

#### 1-116 # row number /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116
#### sbatch  --job-name=sc11_tiling20d_TERRA_ppt_1958.sh  --export=dir=ppt,yyyy=1958,mm=01 /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc11_tiling20d_TERRA_sfd_Int_g84.sh

### for yyyy in {1958..1969} ; do for mm in 01 02 03 04 05 06 07 08 09 10 11 12 ; do  dir=ppt ; sbatch  --job-name=sc11_tiling20d_TERRA_${dir}_${yyyy}_${mm}.sh   --export=dir=$dir,yyyy=$yyyy,mm=$mm /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc11_tiling20d_TERRA_sfd_Int_g84.sh ; done ; done 

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

ulimit -c 0
source ~/bin/gdal3   &> /dev/null
source ~/bin/pktools &> /dev/null

export GRASS=/tmp
export RAM=/dev/shm
export TERRASC=/vast/palmer/scratch/sbsc/hydro/dataproces/TERRA
export TERRASH=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
export HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###  SLURM_ARRAY_TASK_ID=111

export dir=$dir
export tifname=${dir}_${yyyy}_${mm}
export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR) print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

if [ $tile =  h16v10 ] ; then exit 1 ; fi ### tile h16v10 complitly empity also in TERRAS2 

ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{if(NR==AR) print int($2)}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{if(NR==AR) print int($3)}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{if(NR==AR) print int($4)}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{if(NR==AR) print int($5)}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

echo processing  $tifname tile $tile
echoerr  "processing  ${tifname} tile ${tile}"

GDAL_CACHEMAX=10000
GDAL_NUM_THREADS=2
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [ $SLURM_ARRAY_TASK_ID -eq 1  ] ; then
    mkdir -p $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d
    mkdir -p $TERRASC/${dir}_acc_sfd/$yyyy/tiles20d
    gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $TERRASC/${dir}_acc_sfd/$yyyy/${tifname}_intb.vrt  $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_*_acc_sfd_Int_g84.tif
fi
sleep 100
gdal_translate -co COMPRESS=ZSTD -co ZSTD_LEVEL=12  -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata 0 -ot UInt32 -projwin $ulx $uly $lrx $lry  $TERRASC/${dir}_acc_sfd/$yyyy/${tifname}_intb.vrt $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_${tile}_acc_sfd.tif 

echo ${tifname}_${tile}_acc_sfd.tif $( pkstat -hist -src_min -0.1 -src_max +0.1 -i $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_${tile}_acc_sfd.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc_sfd.nd 
#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc_sfd.nd   > $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_${tile}_acc_sfd.nd
rm /dev/shm/${tifname}_${tile}_acc_sfd.nd

gdalwarp -r max -tr 0.0083333333333 0.0083333333333  -multi -wo NUM_THREADS=2  -co COMPRESS=ZSTD -co ZSTD_LEVEL=12  -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -srcnodata  0  -dstnodata 0 -ot UInt32  $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_${tile}_acc_sfd.tif $TERRASC/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_${tile}_acc_sfd_10p.tif  -overwrite 

if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 1000
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $TERRASH/${dir}_acc_sfd/$yyyy/${tifname}_sfd.vrt $TERRASH/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_*_acc_sfd.tif

gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $TERRASC/${dir}_acc_sfd/${tifname}_sfd_10p.vrt $TERRASC/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_*_acc_sfd_10p.tif

gdal_translate -a_nodata 0 -a_srs EPSG:4326 -co COMPRESS=ZSTD -co ZSTD_LEVEL=12 -r nearest  -tr 0.0083333333333 0.0083333333333 $TERRASC/${dir}_acc_sfd/${tifname}_sfd_10p.vrt  $TERRASH/${dir}_acc_sfd/$yyyy/${tifname}_sfd_10p.tif
echo ${tifname}_${tile}_acc_sfd.tif $( pkstat -hist -src_min -0.1 -src_max +0.1 -i $TERRASH/${dir}_acc_sfd/$yyyy/${tifname}_sfd_10p.tif  | awk '{ print $2 }' ) > $TERRASH/${dir}_acc_sfd/$yyyy/${tifname}_sfd_10p.nd

# rm $TERRASC/${dir}_acc_sfd/$yyyy/${tifname}_*_acc_sfd_Int_g84.tif  $TERRASC/${dir}_acc_sfd/$yyyy/${tifname}_*_acc_sfd_Int_g84.mm
rm $TERRASC/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_*_acc_sfd_10p.tif $TERRASC/${dir}_acc_sfd/$yyyy/tiles20d/${tifname}_*_acc_sfd_10p.nd  $TERRASC/${dir}_acc_sfd/${tifname}_sfd_10p.vrt 
fi

exit
## for checking

cat /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/tmin_acc_sfd/*/tmin_*_sfd_10p.nd | grep -v 551748615 | cut -f 1 -d " " |  cut -f 2,3 -d "_" > /tmp/list.txt
for line in $( cat  /tmp/list.txt) ; do
    yyyy=$( echo $line |  cut -f 1 -d "_")
    mm=$( echo $line |  cut -f 2 -d "_")
    sbatch --job-name=sc11_tiling20d_TERRA_${dir}_${yyyy}_${mm}.sh    --export=dir=tmin,yyyy=$yyyy,mm=$mm /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc11_tiling20d_TERRA_sfd_Int_g84.sh
done 
