#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 12:00:00       # 6 hours 
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc10_TERRA_sfd_Int_g84_s.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc10_TERRA_sfd_Int_g84_s.sh.%A_%a.err
#SBATCH --array=1-264

##### --array=1,756 
#### AF AU EUA GL NA NAO SA SAO SIO SPO
#### /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/

#### for BOX in EUA NA AU AF SPO SA SIO GL SAO NAO ; do MEM=$(grep ^"$BOX " /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/mem_request_BOX.txt | awk '{ print $2}'); sbatch  --export=BOX=$BOX,dir=tmax --mem=${MEM} --job-name=sc10_TERRA_sfd_$BOX.sh /nfs/roberts/pi/pi_ga254/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_sfd_Int_g84_bouchet.sh ; done

## module load StdEnv 

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /nfs/roberts/pi/pi_ga254/hydro/stderr  -mtime +2  -name "*.err" | xargs -n 1 -P 2 rm -ifr
# find  /nfs/roberts/pi/pi_ga254/hydro/stdout  -mtime +2  -name "*.out" | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

export  TERRASH=/nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA
export  TERRASC=/nfs/roberts/scratch/pi_ga254/ga254/hydro/dataproces/TERRA
export  MERIT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/MERIT_HYDRO_DEM
export  MERITH=/nfs/roberts/pi/pi_ga254/hydro/dataproces/MERIT_HYDRO
export  RAM=/dev/shm

export  yyyy=$(awk -v AR=$SLURM_ARRAY_TASK_ID  '{ if(NR==AR)  print $2 }' /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/nr_year_month_list.txt )
export  mm=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $3 }' /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/nr_year_month_list.txt )

export  tif=/nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/${dir}/${dir}_${yyyy}_${mm}.tif
export  tifname=$(basename $tif .tif )

export  file=/nfs/roberts/pi/pi_ga254/hydro/dataproces/MERIT_HYDRO_DEM/msk_sfd/${BOX}_box.tif
export  filename=$(basename $file .tif )
export  box=$BOX

echo TERRA file $tifname
echo box $file
echo coordinates $ulx $uly $lrx $lry
echoerr "file $tifname box $file"
echo "file $tifname box $file"

if [ ! -e $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_${box}_acc_sfd_Int_g84.tif ] || [ ! -s $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_${box}_acc_sfd_Int_g84.mm ]; then

source ~/bin/gdal  &> /dev/null
source ~/bin/grass &> /dev/null
export  xmin=$(getCorners4Gtranslate  $file | awk '{ print $1 }' )
export  ymax=$(getCorners4Gtranslate  $file | awk '{ print $2 }' )
export  xmax=$(getCorners4Gtranslate  $file | awk '{ print $3 }' )
export  ymin=$(getCorners4Gtranslate  $file | awk '{ print $4 }' )

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=8
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif,.vrt"
echo time gdalwarp
time gdalwarp -srcnodata -9999 -dstnodata -9999  -s_srs EPSG:4326 -t_srs EPSG:4326  -r bilinear -ot Float32 -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co PREDICTOR=3 -co INTERLEAVE=BAND -co NUM_THREADS=8 -co TILED=YES -multi -wo NUM_THREADS=8  -te $xmin $ymin $xmax $ymax  $tif $RAM/${tifname}_${box}_var.tif
mkdir -p $TERRASC/${dir}_acc_sfd/$yyyy/intb
# cp $RAM/${tifname}_${box}_var.tif $TERRASC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif 
# cp $TERRASH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif  $RAM/${tifname}_${box}_var.tif 

cp $MERIT/are/${box}_are.tif              $RAM/${tifname}_are_sfd_$box.tif   & 
cp $MERITH/dir_sfd/dir_sfd_$box.tif       $RAM/${tifname}_dir_sfd_$box.tif   & 
cp $MERIT/msk_sfd/${box}_msk.tif          $RAM/${tifname}_${box}_msk.tif
wait 

echo "START GRASS"

~/bin/grass84  -f --text --tmp-project $RAM/${tifname}_${box}_msk.tif  <<'EOF'
r.external input=$RAM/${tifname}_${box}_msk.tif       output=msk  --overwrite 
###  r.what  map=msk coordinates=3.34999999999997167,-54.42500000000001137 
g.region raster=msk zoom=msk
r.mask raster=msk --o

r.external  input=$RAM/${tifname}_${box}_var.tif      output=var  --overwrite &
r.external  input=$RAM/${tifname}_are_sfd_$box.tif    output=are  --overwrite &
r.external  input=$RAM/${tifname}_dir_sfd_$box.tif    output=dir  --overwrite 
wait 

/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(var * are )'   nprocs=8
echo var_are
r.info -r var_are

export OMP_NUM_THREADS=8
r.flowaccumulation input=dir type=CELL weight=var_are   output=varare_acc nprocs=8
g.remove -f type=raster name=var_are
echo varare_acc
r.info -r varare_acc
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'varare_acc1  = int(varare_acc + 1 )'   nprocs=8
echo varare_acc1
r.info -r varare_acc1

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=1
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE

### max value 2 049 030 016  so the UInt32 is appropriate. 
r.out.gdal --o -f -c -m format=GTiff createopt='BIGTIFF=YES,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256' nodata=0 type=UInt32   input=varare_acc1  output=/tmp/${tifname}_${box}_acc_sfd_Int_g84.tif --overwrite  --verbose 

EOF

source ~/bin/gdal &> /dev/null

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=4
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
gdalinfo -mm /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_${box}_acc_sfd_Int_g84.mm
gdal_translate -a_nodata 0  -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co BIGTIFF=YES -co NUM_THREADS=4 -co TILED=YES /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh $TERRASC/${dir}_acc_sfd/$yyyy/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 

rm -f $RAM/${tifname}_are_sfd_$box.tif  $RAM/${tifname}_dir_sfd_$box.tif $RAM/${tifname}_${box}_msk.tif $RAM/${tifname}_${box}_var.tif  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 

fi 
exit

if [ $box = EUA ]  ; then

sbatch  --job-name=sc11_tiling20d_TERRA_${dir}_${yyyy}_${mm}.sh   --exclude=r909u13n03  --export=dir=$dir,yyyy=$yyyy,mm=$mm /nfs/roberts/pi/pi_ga254/hydro/scripts/TERRA/sc11_tiling20d_TERRA_sfd_Int_g84.sh

fi

### re do somo files that are not correctly done with the sc11

cat  /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/tmin_acc_sfd/*/tmin_*_sfd_10p.nd | grep -v 551748615  | cut -f 1 -d " "  |  cut -f 2,3 -d "_"  > /tmp/list.txt 
for line in $( cat /tmp/list.txt  ) ; do
    yyyy=$( echo $line |  cut -f 1 -d "_")  ;
    mm=$( echo $line |  cut -f 2 -d "_") ;
    dir=tmin 
    nr=$(grep "$yyyy $mm"    /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/nr_year_month_list.txt | cut -d " "  -f 1)
echo -n ${nr},
done

    
for BOX in EUA NA AU AF SPO SA SIO GL SAO NAO ; do
    MEM=$(grep ^"$BOX " /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/mem_request_BOX.txt | awk '{ print $2}')
    echo sbatch   --export=BOX=$BOX,dir=tmin  --mem=${MEM} --job-name=sc10_TERRA_sfd_$BOX.sh /nfs/roberts/pi/pi_ga254/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_sfd_Int_g84_simple.sh
done

############ final check
for yyyy in {1958..2018} ; do
    for mm in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
    ll /nfs/roberts/pi/pi_ga254/hydro/dataproces/TERRA/tmin_acc_sfd/$yyyy/tmin_${yyyy}_${mm}_sfd_10p.tif
    done
done  | grep directory 

