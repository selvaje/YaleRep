#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_HandsTilesBASINS_Flow_noDep.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_HandsTilesBASINS_Flow_noDep.sh.%J.err
    
ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 

### for ID in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt ) ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt  | awk  '{ print $4}' ) ;  sbatch  --export=ID=$ID --mem=${MEM}M --job-name=sc20_build_dem_location_HandsTilesBASINS${ID}_Flow.sh   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc20_build_dem_location_HandsTilesBASINS_Flow_noDep.sh; done 

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m
             
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
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

### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### greo G_malloc /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20*
export file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${ID}.tif
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

echo elv are dep | xargs -n 1 -P 2 bash -c $'
var=$1
gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/${var}/all_tif_dis.vrt    $RAM/${tile}_${var}.tif

if [ $var = "elv" ] || [ $var = "are" ] ; then  
    gdal_edit.py -a_ullr  $ulx $uly $lrx $lry   -a_nodata -9999  $RAM/${tile}_${var}.tif
else
    gdal_edit.py -a_ullr  $ulx $uly $lrx $lry   -a_nodata 0      $RAM/${tile}_${var}.tif
fi

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/${tile}_${var}.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_${var}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/${tile}_${var}.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_${var}.tif

' _ 

var=msk
gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $ulx $uly $lrx $lry $MERIT/msk_merit/all_tif_dis.vrt    $RAM/${tile}_${var}.tif

gdal_edit.py -a_ullr  $ulx $uly $lrx $lry   -a_nodata 0      $RAM/${tile}_${var}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/${tile}_${var}.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_${var}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/${tile}_${var}.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tile}_${var}.tif

###  rm -fr $SC/grassdb/loc_$tile 
###  grass76 -f -text -c $RAM/${tile}_elv.tif   $SC/grassdb/loc_$tile   <<'EOF'

grass78  -f -text --tmp-location  -c $RAM/${tile}_elv.tif    <<'EOF'

echo elv are msk dep | xargs -n 1 -P 1 bash -c $'
r.external  input=$RAM/${tile}_$1.tif     output=$1        --overwrite 
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

r.watershed  -b  elevation=elv  depression=dep    accumulation=flow drainage=dir_rw flow=are   memory=90000 --o --verbose 
r.stream.extract elevation=elv  accumulation=flow depression=dep   threshold=0.05  direction=dir_rs  stream_raster=stream  memory=90000 --o --verbose 

r.stream.basins -l  stream_rast=stream direction=dir_rs   basins=lbasin  memory=90000 --o --verbose  
r.colors -r stream ; r.colors -r lbasin ; r.colors -r flow

g.remove -f  type=raster name=elv,dep,are
rm -f  $RAM/${tile}_elv.tif $RAM/${tile}_dep.tif $RAM/${tile}_are.tif

###### create a small zone flow binary for later use ###########              
r.mapcalc " small_zone_flow =   if( !isnull(flow) && isnull(lbasin) , 1 , null()) " --o 

##### create a smaller box

CropW=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropW" | awk '{  print $4 }' )
CropE=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropE" | awk '{  print $4 }' )
CropS=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropS" | awk '{  print $4 }' )
CropN=$( ogrinfo -al   -where  " id  = '$tile' " $SC/tiles_comp/tilesComp.shp  | grep " CropN" | awk '{  print $4 }' )

nS=$(g.region -m  | grep ^n= | awk -F "=" -v CropN=$CropN  '{ printf ("%.14f\n" , $2 - CropN ) }' )
sS=$(g.region -m  | grep ^s= | awk -F "=" -v CropS=$CropS  '{ printf ("%.14f\n" , $2 + CropS ) }' )
eS=$(g.region -m  | grep ^e= | awk -F "=" -v CropE=$CropE  '{ printf ("%.14f\n" , $2 - CropE ) }' )
wS=$(g.region -m  | grep ^w= | awk -F "=" -v CropW=$CropW  '{ printf ("%.14f\n" , $2 + CropW ) }' )

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


g.region   e=$eS  w=$wS  n=$nST  s=$sST  res=0:00:03 --o
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
## for assesment
##  r.mask raster=lbasin_clean --o
##  r.out.gdal --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0 input=lbasin_clean  output=$SC/lbasin_tiles_intb1/lbasin_${zone}$tile.tif 


############ export flow and direction 

r.mask raster=msk --o

r.mapcalc  " lbasin_flow_clean  = if ( !isnull(lbasin_clean ) || !isnull(small_zone_flow) , 1 , null()  ) "
r.grow  input=lbasin_flow_clean  output=lbasin_flow_clean_grow  radius=10
r.mask raster=lbasin_flow_clean_grow   --o

r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES,INTERLEAVE=BAND,TILED=YES"  nodata=-9999999  type=Float32 format=GTiff input=flow  output=$SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif

gdal_edit.py -a_ullr  $wS $nS $eS $sS  $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif 
gdal_edit.py -a_ullr  $wS $nS $eS $sS  $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif 

#####    -1 955 715 minimum value   -1 955 715    #### supported by Float32  -16 777 216 to 16 777 216. 
#######  -9999999   ... seven9 is accepted by buildvrt + gdal treanslate. 

EOF

rm -f  $RAM/msk_${zone}${tile}.tif
GDAL_CACHEMAX=40000
##### minimum value   -1955715   only for assesment 

pkfilter -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Int32  -dx 10  -dy 10 -d 10 -f mean -i $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif -o $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}_10p.tif
gdal_edit.py -a_nodata -9999999   $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}_10p.tif 
pkgetmask -co  COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min -9999998 -max 99999999999999999999 -i $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}.tif -o $SC/flow_noDep_tiles_intb1/flow_${zone}${tile}_msk.tif 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

exit 

if [ $ID -eq 40  ] ; then 
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep  sc20_build_dem_location_HandsTilesBASINS  | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc21a_merge_flowaccumulation_buildvrt.sh 
sleep 10 
fi 

