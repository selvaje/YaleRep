#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc10_SOILGRIDS_sfd_Int_g84_s.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84_s.sh.%J.err

#### AF AU EUA GL NA NAO SA SAO SIO SPO
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{bdod,ces,cfvo}_0-200cm.vrt   
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{nitrogen,ocd,phh2o,soc}_0-200cm.vrt

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{sand,silt,clay}_0-200cm.vrt; do for BOX in AF AU EUA GL NA NAO SA SAO SIO SPO ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt | awk '{ print $2}'); sbatch --exclude=r818u29n01,r818u23n02 --export=tif=$tif,BOX=$BOX --mem=${MEM} --job-name=sc10_SOILGRIDS_sfd_$(basename $tif .vrt)_$BOX.sh /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS_sfd_Int_g84_simple.sh; done; done

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/ocs_0-30cm.vrt; do for BOX in AF AU EUA GL NA NAO SA SAO SIO SPO ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt | awk '{ print $2}'); sbatch --exclude=r818u29n01,r818u23n02 --export=tif=$tif,BOX=$BOX --mem=${MEM} --job-name=sc10_SOILGRIDS_sfd_$(basename $tif .vrt)_s.sh /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS_sfd_Int_g84_simple.sh; done; done 

source ~/bin/gdal3 &> /dev/null
module load StdEnv 

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
# find  /gpfs/gibbs/pi/hydro/hydro/stderr  -mtime +2  -name "*.err" | xargs -n 1 -P 2 rm -ifr
# find  /gpfs/gibbs/pi/hydro/hydro/stdout  -mtime +2  -name "*.out" | xargs -n 1 -P 2 rm -ifr
  
# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr
#### check memory 
#### sacct --format="JobID,CPUTime,MaxRSS" | grep jobID

export  SOILGRIDSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
export  SOILGRIDSC=/vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2
export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export  MERITH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export  RAM=/dev/shm
export  SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export  tifname=$(basename $tif .vrt )
export  dir=$(echo $tifname | cut -d "_"  -f 1 )
export  file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_sfd/${BOX}_box.tif
export  filename=$(basename $file .tif )
export  box=$BOX
export  xmin=$(getCorners4Gtranslate  $file | awk '{ print $1 }' )
export  ymax=$(getCorners4Gtranslate  $file | awk '{ print $2 }' )
export  xmax=$(getCorners4Gtranslate  $file | awk '{ print $3 }' )
export  ymin=$(getCorners4Gtranslate  $file | awk '{ print $4 }' )

echo SOILGRIDS file $tifname
echo box $file
echo coordinates $ulx $uly $lrx $lry
echoerr "file $tifname box $file"
echo "file $tifname box $file"

export GDAL_CACHEMAX=4G
export GDAL_NUM_THREADS=8
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif,.vrt"
echo time gdalwarp
time gdalwarp -s_srs EPSG:4326 -t_srs EPSG:4326  -r bilinear -ot Float32 -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co PREDICTOR=3 -co INTERLEAVE=BAND -co NUM_THREADS=8 -co TILED=YES -multi -wo NUM_THREADS=8  -te $xmin $ymin $xmax $ymax  $tif $RAM/${tifname}_${box}_var.tif
mkdir -p $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb
mkdir -p $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb
# cp $RAM/${tifname}_${box}_var.tif $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif 
# cp $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif  $RAM/${tifname}_${box}_var.tif 

cp $MERIT/are/${box}_are.tif              $RAM/${tifname}_are_sfd_$box.tif   & 
cp $MERITH/dir_sfd/dir_sfd_$box.tif       $RAM/${tifname}_dir_sfd_$box.tif   & 
cp $MERIT/msk_sfd/${box}_msk.tif          $RAM/${tifname}_${box}_msk.tif
wait 

module unload GDAL/3.6.2-foss-2022b ### this is usefull to allow certen python numpy versions

apptainer exec  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project $RAM/${tifname}_${box}_msk.tif  <<'EOF'
r.external input=$RAM/${tifname}_${box}_msk.tif       output=msk  --overwrite 
r.what  map=msk coordinates=3.34999999999997167,-54.42500000000001137
g.region raster=msk zoom=msk
r.mask raster=msk --o

r.external  input=$RAM/${tifname}_${box}_var.tif      output=var  --overwrite &
r.external  input=$RAM/${tifname}_are_sfd_$box.tif    output=are  --overwrite &
r.external  input=$RAM/${tifname}_dir_sfd_$box.tif    output=dir  --overwrite 
wait 
r.what  map=var coordinates=3.34999999999997167,-54.42500000000001137
r.what  map=are coordinates=3.34999999999997167,-54.42500000000001137
r.what  map=dir coordinates=3.34999999999997167,-54.42500000000001137

/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(var * are )'   nprocs=8
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
gdalinfo -mm /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.mm
gdal_translate -a_nodata 0  -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co BIGTIFF=YES -co NUM_THREADS=4 -co TILED=YES /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 

rm -f $RAM/${tifname}_are_sfd_$box.tif  $RAM/${tifname}_dir_sfd_$box.tif $RAM/${tifname}_${box}_msk.tif $RAM/${tifname}_${box}_var.tif  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 

exit


### for checking
for DIR in bdod cec cfvo clay nitrogen ocd ocs phh2o sand silt soc ; do
for BOX in EUA AF AU GL NA NAO SA SAO SIO SPO ; do
ll /vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2/$DIR/*_acc_sfd/intb/*_0-*cm_${BOX}_acc_sfd_Int_g84.tif
done
echo " " 
done 

#### memory luckup table
for n in $(grep _CELL /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84_s.sh.*.err | tr "." " " | cut -d " " -f 3 | sort | uniq ) ; do
    echo $(head -1 /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84_s.sh.$n.err | cut -d "/" -f 10 | cut -d "_" -f 1) $(seff $n | grep "Average Memory Usag" | awk '{ print int($4 + 50)"G"}')
done > /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt 


/usr/bin/grass -f --text --tmp-project /vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2/silt/silt_acc_sfd/intb/silt_0-200cm_SIO_var.tif  <<'EOF'
r.external input=/vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2/silt/silt_acc_sfd/intb/silt_0-200cm_SIO_var.tif output=test
r.out.gdal --o -f -c -m format=GTiff createopt='PREDICTOR=2,COMPRESS=LZW,BIGTIFF=YES,NUM_THREADS=2,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256' nodata=0 type=UInt32   input=varare_acc1  output=/tmp/test_comp.tif --overwrite  --verbose
r.out.gdal --o -f -c -m format=GTiff createopt='BIGTIFF=YES,NUM_THREADS=2,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256' nodata=0 type=UInt32   input=varare_acc1 output=/tmp/test_NOcomp.tif --overwrite  --verbose          
EOF

                                                                                 



