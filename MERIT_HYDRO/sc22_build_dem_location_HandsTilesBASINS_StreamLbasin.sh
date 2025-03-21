#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 8:00:00       # 8 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc22_build_dem_location_HandsTilesBASINS_Flow_StreamLbasin.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc22_build_dem_location_HandsTilesBASINS_Flow_StreamLbasin.sh.%A_%a.err
#SBATCH --job-name=sc22_build_dem_location_HandsTilesBASINS_StreamLbasin.sh
#SBATCH --array=1-59
#SBATCH --mem=100G

### -59
ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc22_build_dem_location_HandsTilesBASINS_StreamLbasin.sh

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

echo SLURM_JOB_ID $SLURM_JOB_ID
echo SLURM_ARRAY_JOB_ID $SLURM_ARRAY_JOB_ID
echo SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID
echo SLURM_ARRAY_TASK_COUNT $SLURM_ARRAY_TASK_COUNT
echo SLURM_ARRAY_TASK_MAX $SLURM_ARRAY_TASK_MAX
echo SLURM_ARRAY_TASK_MIN  $SLURM_ARRAY_TASK_MIN

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

##  SLURM_ARRAY_TASK_ID=33
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   

export file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${SLURM_ARRAY_TASK_ID}.tif
export filename=$(basename $file .tif  )
export tile=$(echo $filename | tr "ID" " " | awk '{ print $2 }' )
export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )
export  ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export  uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export  lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export  lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )
#  all tiles have been enlarged of 3 degree in the previus script, some other even more in the below if. 

echo $file 
echo coordinates $ulx $uly $lrx $lry

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SC/flow_tiles/all_tif_dis.vrt $SC/flow_tiles/flow_h??v??.tif 
else 
sleep 60 
fi

GDAL_CACHEMAX=40000 

echo msk dep | xargs -n 1 -P 2 bash -c $'
var=$1
gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/${var}/all_tif_dis.vrt $RAM/${tile}_${var}.tif
gdal_edit.py  -a_nodata 0  -a_ullr  $ulx $uly $lrx $lry   $RAM/${tile}_${var}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333    $RAM/${tile}_${var}.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry   $RAM/${tile}_${var}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333    $RAM/${tile}_${var}.tif
' _ 

gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/elv/all_tif_dis.vrt     $RAM/${tile}_elv.tif
gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $SC/flow_tiles/all_tif_dis.vrt $RAM/${tile}_flow.tif

gdal_edit.py -a_ullr  $ulx $uly $lrx $lry $RAM/${tile}_elv.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${tile}_elv.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_elv.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${tile}_elv.tif

gdal_edit.py -a_ullr  $ulx $uly $lrx $lry $RAM/${tile}_flow.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${tile}_flow.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_flow.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${tile}_flow.tif

###  rm -fr $SC/grassdb/loc_$tile 
###  grass76 -f -text -c $RAM/${tile}_elv.tif   $SC/grassdb/loc_$tile   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/${tile}_elv.tif    <<'EOF'

r.external  input=$RAM/${tile}_msk.tif  output=msk      --overwrite # create the folder structure

echo elv dep flow  | xargs -n 1 -P 2 bash -c $'
r.external  input=$RAM/${tile}_$1.tif     output=$1       --overwrite  
' _ 

r.mask raster=msk --o # usefull to mask the flow accumulation 

nL=$uly
sL=$lry
eL=$lrx
wL=$ulx

g.region w=$wL  n=$nL  s=$sL  e=$eL  res=0:00:03   --o 
g.region  -m

### maximum ram 66571M  for 2^63 -1   (2 147 483 647 cell)  / 1 000 000  * 31 M   

####  -m  Enable disk swap memory option: Operation is slow   
####  -a Use positive flow accumulation even for likely underestimates
####  -b Beautify flat areas
####   threshold=0.05  = 0.05 km2 = 50000 m2 = 50000 / 90*90 = 6.17 cell 

r.stream.extract elevation=elv  accumulation=flow depression=dep threshold=0.05  direction=dir_rs  stream_raster=stream  stream_vector=stream memory=90000 --o --verbose 
v.to.rast input=stream layer=2 type=point use=val val=1   output=outlet cats=2  memory=90000 --o 
r.stream.basins -l  stream_rast=stream direction=dir_rs   basins=lbasin  memory=90000 --o --verbose  
r.stream.basins     stream_rast=stream direction=dir_rs   basins=basin   memory=90000 --o --verbose  

r.colors -r stream ; r.colors -r lbasin ; r.colors -r flow

g.remove -f  type=raster name=elv,dep,are
rm -f  $RAM/${tile}_elv.tif $RAM/${tile}_dep.tif $RAM/${tile}_are.tif

#### create a small zone flow binary for later use ###########  
r.mapcalc " small_zone_flow =   if( !isnull(flow) && isnull(lbasin) , 1 , null()) " --o           
r.report map=small_zone_flow unit=c
##### create a smaller box

CropW=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropW" | awk '{  print $4 }' )
CropE=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropE" | awk '{  print $4 }' )
CropS=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropS" | awk '{  print $4 }' )
CropN=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropN" | awk '{  print $4 }' )

export nS=$(g.region -m  | grep ^n= | awk -F "=" -v CropN=$CropN  '{ printf ("%.14f\n" , $2 - CropN ) }' )
export sS=$(g.region -m  | grep ^s= | awk -F "=" -v CropS=$CropS  '{ printf ("%.14f\n" , $2 + CropS ) }' )
export eS=$(g.region -m  | grep ^e= | awk -F "=" -v CropE=$CropE  '{ printf ("%.14f\n" , $2 - CropE ) }' )
export wS=$(g.region -m  | grep ^w= | awk -F "=" -v CropW=$CropW  '{ printf ("%.14f\n" , $2 + CropW ) }' )

g.region w=$wS  n=$nS  s=$sS  e=$eS  res=0:00:03  save=smallext --o    # smaller region 
g.region region=smallext --o
g.region  -m

g.region -m

echo left stripe   ########
eST=$(g.region -m  | grep ^e= | awk -F "=" '{ print $2   }' )
wST=$(g.region -m  | grep ^e= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region n=$nS s=$sS     e=$eST w=$wST  res=0:00:03 --o
r.mapcalc " lbasin_wstripe = lbasin " --o

g.region region=smallext --o
echo right stripe  ########
wST=$(g.region -m  | grep ^w= | awk -F "=" '{ print $2   }' )
eST=$(g.region -m  | grep ^w= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region n=$nS s=$sS  e=$eST w=$wST  res=0:00:03 --o
r.mapcalc " lbasin_estripe    = lbasin " --o

g.region region=smallext --o
echo top stripe  ##########
nST=$(g.region -m  | grep ^n= | awk -F "=" '{ print $2   }' )
sST=$(g.region -m  | grep ^n= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region e=$eS w=$wS  n=$nST s=$sST   res=0:00:03 --o
r.mapcalc " lbasin_nstripe    = lbasin " --o

g.region region=smallext --o
echo bottom stripe ########
sST=$(g.region -m  | grep ^s= | awk -F "=" '{ print $2   }' )
nST=$(g.region -m  | grep ^s= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region e=$eS  w=$wS  n=$nST  s=$sST  res=0:00:03 --o
r.mapcalc " lbasin_sstripe    = lbasin " --o

g.region region=smallext   --o  # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_estripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_wstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_sstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_nstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) \
      | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${tile}_reclass.txt 
r.reclass input=lbasin  output=lbasin_rec   rules=/dev/shm/lbasin_${tile}_reclass.txt   --o

rm -f /dev/shm/lbasin_${tile}_reclass.txt 

r.mapcalc  " lbasin_clean = lbasin_rec  " --o
g.remove -f  type=raster name=lbasin_rec,lbasin_estripe,lbasin_wstripe,lbasin_nstripe,lbasin_sstripe 

############  export stream and basin 
r.mask raster=lbasin_clean --o 

r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"    type=UInt32 format=GTiff nodata=0   input=lbasin  output=$SC/lbasin_tiles_intb2/lbasin_${zone}$tile.tif 
r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"    type=UInt32 format=GTiff nodata=0   input=basin   output=$SC/basin_tiles_intb2/basin_${zone}$tile.tif 
r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"    type=UInt32 format=GTiff nodata=0   input=stream  output=$SC/stream_tiles_intb2/stream_${zone}$tile.tif
r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"    type=Byte   format=GTiff nodata=0   input=outlet  output=$SC/outlet_tiles_intb2/outlet_${zone}$tile.tif

r.mask raster=msk --o
r.mapcalc  " lbasin_flow_clean  = if ( !isnull(lbasin_clean ) || !isnull(small_zone_flow) , 1 , null()  ) "
r.grow  input=lbasin_flow_clean  output=lbasin_flow_clean_grow  radius=10
r.mask raster=lbasin_flow_clean_grow   --o
#### produce the dir_rs to the same extension of the flowaccumulation 
r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16  format=GTiff nodata=-10 input=dir_rs  output=$SC/dir_tiles_intb2/dir_rs_${zone}$tile.tif

echo outlet stream basin lbasin  | xargs -n 1 -P 2 bash -c $'
var=$1 
gdal_edit.py -a_ullr  $wS $nS $eS $sS  $SC/${var}_tiles_intb2/${var}_${zone}$tile.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SC/${var}_tiles_intb2/${var}_${zone}$tile.tif
' _

gdal_edit.py -a_ullr  $wS $nS $eS $sS  $SC/dir_tiles_intb2/dir_rs_${zone}$tile.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SC/dir_tiles_intb2/dir_rs_${zone}$tile.tif

EOF

rm -f $RAM/${tile}_msk.tif  $RAM/flow_${zone}${tile}.tif

GDAL_CACHEMAX=40000
pkfilter -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot UInt32 -of GTiff -dx 3 -dy 3 -d 3 -f mode -i $SC/lbasin_tiles_intb2/lbasin_${zone}$tile.tif -o  $SC/lbasin_tiles_intb2/lbasin_${zone}${tile}_3p.tif

pkstat -hist -i $SC/lbasin_tiles_intb2/lbasin_${zone}$tile.tif  | awk ' { if ( $2!=0 ) print $1  }' >  $SC/lbasin_tiles_intb2/lbasin_${zone}${tile}_hist.txt


if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then                       
sbatch  --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j"  | grep sc22_build_dem_location_HandsTilesBASINS_StreamLbasin.sh | awk '{ print $1  }' | uniq )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc23_reclass_array_lbasin_stream_intb.sh
sleep 60
fi 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"


exit
