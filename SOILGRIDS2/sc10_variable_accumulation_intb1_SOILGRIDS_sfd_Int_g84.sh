#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc10_SOILGRIDS_sfd_Int_g84.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84.sh.%J.err

#### AF AU EUA GL NA NAO SA SAO SIO SPO
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{bdod,ces,cfvo}_0-200cm.vrt   
#### /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{nitrogen,ocd,phh2o,soc}_0-200cm.vrt

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/{sand,silt,clay}_0-200cm.vrt; do for BOX in AF AU EUA GL NA NAO SA SAO SIO SPO ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt | awk '{ print $2}'); sbatch --exclude=r818u29n01,r818u23n02 --export=tif=$tif,BOX=$BOX --mem=${MEM} --job-name=sc10_SOILGRIDS_sfd_Int_g84_$(basename $tif .vrt).sh /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS_sfd_Int_g84.sh; done; done

#### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/ocs_0-30cm.vrt; do for BOX in AF AU EUA GL NA NAO SA SAO SIO SPO ; do MEM=$(grep ^"$BOX " /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/mem_request_BOX.txt | awk '{ print $2}'); sbatch --exclude=r818u29n01,r818u23n02 --export=tif=$tif,BOX=$BOX --mem=${MEM} --job-name=sc10_SOILGRIDS_sfd_Int_g84_$(basename $tif .vrt).sh /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc10_variable_accumulation_intb1_SOILGRIDS_sfd_Int_g84.sh; done; done 

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

export  tifname=$(basename  $tif .vrt )
export dir=$(echo $tifname | cut -d "_"  -f 1 )
export file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_sfd/${BOX}_box.tif
export filename=$(basename $file .tif )
export box=$BOX
export xmin=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export ymax=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export xmax=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export ymin=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo SOILGRIDS file $tifname 
echo box $file
echo coordinates $ulx $uly $lrx $lry
echoerr "file $tifname box $file"
echo "file $tifname box $file"

# run the first time for one var and for all the box


# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif $MERITH/flow_sfd/flow_sfd_$box.tif &
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/are/all_tif_dis.vrt $MERIT/are/${box}_are.tif & 
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction.tif $MERITH/dir_sfd/dir_sfd_$box.tif & 

export GDAL_CACHEMAX=5000
export GDAL_NUM_THREADS=8
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif,.vrt"
echo time gdalwarp
time gdalwarp -s_srs EPSG:4326 -t_srs EPSG:4326  -r bilinear -ot Float32 -tr 0.000833333333333333333 0.000833333333333333333 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=6 -co INTERLEAVE=BAND -co NUM_THREADS=ALL_CPUS -co TILED=YES -multi -wo NUM_THREADS=8  -te $xmin $ymin $xmax $ymax  $tif $RAM/${tifname}_${box}_var.tif
mkdir -p $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb
mkdir -p $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb
cp $RAM/${tifname}_${box}_var.tif $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif 

# cp $SOILGRIDSH/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_var.tif  $RAM/${tifname}_${box}_var.tif 
wait

cp $MERIT/are/${box}_are.tif              $RAM/${tifname}_are_sfd_$box.tif   & 
cp $MERITH/dir_sfd/dir_sfd_$box.tif       $RAM/${tifname}_dir_sfd_$box.tif   & 
cp $MERIT/msk_sfd/${box}_msk.tif          $RAM/${tifname}_${box}_msk.tif
wait 

module unload GDAL/3.6.2-foss-2022b ### this is usefull to allow certen python numpy versions

apptainer exec  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project $RAM/${tifname}_${box}_msk.tif  <<'EOF'
r.external input=$RAM/${tifname}_${box}_msk.tif       output=msk  --overwrite 
g.region raster=msk zoom=msk
r.mask raster=msk --o
tilex=\$(g.region -p | grep cols | cut -d ' ' -f 8)
tiley=\$(g.region -p | grep rows | cut -d ' ' -f 8)
echo matrix size tilex \$tilex tiley \$tiley
r.external  input=$RAM/${tifname}_${box}_var.tif      output=var  --overwrite &
r.external  input=$RAM/${tifname}_are_sfd_$box.tif    output=are  --overwrite &
r.external  input=$RAM/${tifname}_dir_sfd_$box.tif    output=dir  --overwrite 
wait 

/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'var_are = float(var * are )'   nprocs=
r.info -r var_are

export OMP_NUM_THREADS=8
r.flowaccumulation input=dir type=DCELL weight=var_are   output=varare_acc nprocs=8
g.remove -f type=raster name=var_are
r.info -r varare_acc
/home/ga254/.grass8/addons/scripts/r.mapcalc.tiled   'varare_acc1  = int(varare_acc + 1 )'   nprocs=8
r.info -r varare_acc1
#### NA EUA AF  ... SPO ???? SA????  AU is odd 
if [[  $box = NA  || $box = AF || $box = EUA  ]]; then

echo processing sfd output with tiling tilex \$tilex tiley \$tiley
r.tile input=varare_acc1 width=\$(expr \$tilex / 2) height=\$(expr \$tiley / 2) output=varare_acc1_tile
echo varare_acc1_tile-000-000 varare_acc1_tile-000-001 varare_acc1_tile-001-000 varare_acc1_tile-001-001 | xargs -n 1 -P 4 bash -c $'
export tile=\$1
export tilen=\$(echo \$1 | cut -d e -f 3)
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export GDAL_CACHEMAX=2G
export GDAL_NUM_THREADS=2
r.out.gdal --o -f -c -m createopt=\'PREDICTOR=2,COMPRESS=LZW,BIGTIFF=YES,NUM_THREADS=2,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256\' nodata=0 type=UInt32 input=\$tile output=/tmp/\${tifname}_\${box}\${tilen}_acc_sfd_Int_g84.tif --overwrite
' _

else
    echo processing sfd output without tiling
export GDAL_CACHEMAX=2G
export GDAL_NUM_THREADS=2
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
r.out.gdal --o -f -c -m createopt='PREDICTOR=2,COMPRESS=LZW,BIGTIFF=YES,NUM_THREADS=2,TILED=YES,BLOCKXSIZE=256,BLOCKYSIZE=256' nodata=0 type=UInt32   input=varare_acc1  output=/tmp/${tifname}_${box}_acc_sfd_Int_g84.tif --overwrite
fi
EOF
"

source ~/bin/gdal3 &> /dev/null

if [[  $box = NA  || $box = AF || $box = EUA  ]]; then
echo varare_acc1_tile-000-000 varare_acc1_tile-000-001 varare_acc1_tile-001-000 varare_acc1_tile-001-001 | xargs -n 1 -P 4 bash -c $'
tile=$1 
tilen=$(echo $1 | cut -d "e" -f 3)
export GDAL_CACHEMAX=2G
export GDAL_NUM_THREADS=2
gdalinfo -mm /tmp/${tifname}_${box}${tilen}_acc_sfd_Int_g84.tif  | grep Computed | awk \'{ gsub(/[=,]/," " , $0 ); print $3 , $4 }\' > $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.mm

if [ -f $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.mm  ] && [ ! -s $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.mm ]; then
    rm -f $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.*
else
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
export GDAL_CACHEMAX=2G
export GDAL_NUM_THREADS=2
gdal_translate -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9  -co BIGTIFF=YES -co NUM_THREADS=2 -co TILED=YES /tmp/${tifname}_${box}${tilen}_acc_sfd_Int_g84.tif  $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.tif
ls -lh  /tmp/${tifname}_${box}${tilen}_acc_sfd_Int_g84.tif
ls -lh  $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}${tilen}_acc_sfd_Int_g84.tif
fi
' _

else
export GDAL_CACHEMAX=2G
export GDAL_NUM_THREADS=4
export GDAL_DISABLE_READDIR_ON_OPEN=TRUE
gdalinfo -mm /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.mm
gdal_translate -co COMPRESS=ZSTD  -co ZSTD_LEVEL=9 -co BIGTIFF=YES -co NUM_THREADS=2 -co TILED=YES /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh  /tmp/${tifname}_${box}_acc_sfd_Int_g84.tif 
ls -lh $SOILGRIDSC/${dir}/${dir}_acc_sfd/intb/${tifname}_${box}_acc_sfd_Int_g84.tif 

fi 

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
for n in $(grep bdod  /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84.sh.*.err | tr "." " " | cut -d " " -f 3 | sort | uniq ) ; do
    echo $(head -1 /vast/palmer/scratch/sbsc/ga254/stderr/sc10_SOILGRIDS_sfd_Int_g84.sh.$n.err | cut -d "/" -f 10 | cut -d "_" -f 1) $(seff $n | grep "Average Memory Usag" | awk '{ print int($4 + 80)"G"}')
done
