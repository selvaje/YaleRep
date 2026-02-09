#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_tiling20d_GRWL_sfd_Int_g84.sh.%A_%a.out  
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_tiling20d_GRWL_sfd_Int_g84.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=30G

### --array=1-116

#### 1-116 # row number /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116

#### for dir in water lake delta canal river ; do sbatch  --export=dir=$dir,tifname=GRWL_${dir} --job-name=sc11_tiling20d_$dir.sh /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc11_tiling20d_GRWL_sfd_Int_g84.sh   ; done

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
export GRWLSC=/vast/palmer/scratch/sbsc/hydro/dataproces/GRWL
export GRWLSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
export HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###  SLURM_ARRAY_TASK_ID=111

export dir=$dir
export tifname=$tifname
export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR) print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

mkdir -p $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d
mkdir -p $GRWLSC/${dir}/${dir}_acc_sfd/intb

if [ $tile =  h16v10 ] ; then exit 1 ; fi ### tile h16v10 complitly empity also in GRWL

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
    gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $GRWLSC/${dir}/${dir}_acc_sfd/intb/${tifname}_intb.vrt  $GRWLSC/${dir}/${dir}_acc_sfd/intb/${tifname}_*_acc_sfd_Int_g84.tif
fi
sleep 100
gdal_translate -co COMPRESS=ZSTD -co ZSTD_LEVEL=12  -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata 0 -ot UInt32 -projwin $ulx $uly $lrx $lry  $GRWLSC/${dir}/${dir}_acc_sfd/intb/${tifname}_intb.vrt $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_${tile}_acc_sfd.tif 

echo ${tifname}_${tile}_acc_sfd.tif $( pkstat -hist -src_min -0.1 -src_max +0.1 -i $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_${tile}_acc_sfd.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc_sfd.nd 
#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc_sfd.nd   > $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_${tile}_acc_sfd.nd
rm /dev/shm/${tifname}_${tile}_acc_sfd.nd

mkdir -p $GRWLSC/${dir}/${dir}_acc_sfd/tiles20d/
gdalwarp -r max -tr 0.0083333333333 0.0083333333333  -multi -wo NUM_THREADS=2  -co COMPRESS=ZSTD -co ZSTD_LEVEL=12  -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -srcnodata  0  -dstnodata 0 -ot UInt32  $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_${tile}_acc_sfd.tif $GRWLSC/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_${tile}_acc_sfd_10p.tif  -overwrite 

if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 1000
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $GRWLSH/${dir}/${dir}_acc_sfd/${tifname}_sfd.vrt $GRWLSH/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_*_acc_sfd.tif

gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $GRWLSC/${dir}/${dir}_acc_sfd/${tifname}_sfd_10p.vrt $GRWLSC/${dir}/${dir}_acc_sfd/tiles20d/${tifname}_*_acc_sfd_10p.tif

gdal_translate -a_nodata 0 -a_srs EPSG:4326 -co COMPRESS=ZSTD -co ZSTD_LEVEL=12 -r nearest  -tr 0.0083333333333 0.0083333333333 $GRWLSC/${dir}/${dir}_acc_sfd/${tifname}_sfd_10p.vrt  $GRWLSH/${dir}/${dir}_acc_sfd/${tifname}_sfd_10p.tif

pkstat -hist -src_min -0.1 -src_max +0.1 -i $GRWLSH/${dir}/${dir}_acc_sfd/${tifname}_sfd_10p.tif   | awk '{ print $2 }'  > $GRWLSH/${dir}/${dir}_acc_sfd/${tifname}_sfd_10p.nd

fi

exit
## for checking
var=clay 
for file in /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/${var}/${var}_acc/tiles20d/${var}_0-200cm_*_acc.nd  ; do
paste -d " " <(cat $file) <( cut -f 1,2 -d " "   /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWLS2/${var}/${var}_acc_sfd/tiles20d/$( basename $file .nd )_sfd.nd ) | awk '{  print $1 , $3 , $2 - $4  }'
done
