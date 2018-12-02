#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_4streamTile.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_4streamTile.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc20_build_dem_location_4streamTile.sh
#SBATCH --array=1-2
#SBATCH --mem-per-cpu=21000

# 1150 number of files 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc20_build_dem_location_4streamTile.sh

# file=$(ls /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/{n35w100,n40w100}_elv.tif    | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )

file=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/n35w100_elv.tif
MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp

RAM=/dev/shm
tile=$(basename $file _elv.tif )
echo filename  $tile 

### take the coridinates from the orginal files and increment on 100 pixels

export ulxL=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  - (1200 * 0.000833333333333 )) }')
export ulyL=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  + (1200 * 0.000833333333333 )) }')
export lrxL=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  + (1200 * 0.000833333333333 )) }')
export lryL=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  - (1200 * 0.000833333333333 )) }')

export ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3 ) }')
export uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4 ) }')
export lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3 ) }')
export lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4 ) }')



echo $ulx $uly $lrx $lry  # vrt is needed to clip before to create the tif 

for var in elv msk dep upa ; do 
gdalbuildvrt -overwrite -te $ulxL $lryL $lrxL $ulyL $RAM/${tile}_${var}.vrt  $MERIT/${var}/all_tif.vrt   
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulx $uly $lrx $lry  $RAM/${tile}_${var}.vrt $RAM/${tile}_${var}.tif

if [ $var = "elv" ] || [ $var = "upa" ] ; then  
    gdal_edit.py  -a_nodata -9999  $RAM/${tile}_${var}.tif
else
    gdal_edit.py  -a_nodata 0      $RAM/${tile}_${var}.tif
fi
done 
rm -f  $RAM/${tile}_${var}.vrt 

rm -r $GRASS/loc_$tile
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh $GRASS loc_$tile $RAM/${tile}_elv.tif

g.rename  raster=${tile}_elv,elv  ; rm -f $RAM/${tile}_elv.tif

r.in.gdal in=$RAM/${tile}_msk.tif  out=msk    memory=2000 --o ; rm -f $RAM/${tile}_msk.tif
r.in.gdal in=$RAM/${tile}_dep.tif  out=dep    memory=2000 --o ; rm -f $RAM/${tile}_dep.tif
r.in.gdal in=$RAM/${tile}_upa.tif  out=upa    memory=2000 --o ; rm -f $RAM/${tile}_upa.tif 

r.mask raster=msk --o

r.stream.extract elevation=elv  accumulation=upa threshold=0.5     depression=dep    direction=dir  stream_raster=stream memory=20000 --o --verbose  ;  r.colors -r stream
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir  basins=lbasin        memory=20000 --o --verbose  ;  r.colors -r lbasin

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_large/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif.aux.xml 

# w=$( awk -v ulx=$ulx 'BEGIN{ printf ("%.16f\n" ,  ulx  + (1199 * 0.000833333333333 )) }')

g.region w=$ulx  n=$uly  s=$lry  e=$lrx  res=0:00:03   save=crop --o  

echo g.region w=$ulx  n=$uly  s=$lry  e=$lrx  res=0:00:03   save=crop --o 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_full/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif.aux.xml 

echo left stripe 
eS=$(g.region -m  | grep e= | awk -F "=" '{ print $2   }' )
wS=$(g.region -m  | grep e= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry     e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_wstripe    = lbasin " --o

g.region region=crop
echo right stripe 
wS=$(g.region -m  | grep w= | awk -F "=" '{ print $2   }' )
eS=$(g.region -m  | grep w= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry  e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_estripe    = lbasin " --o

####

g.region region=crop
echo top stripe 
nS=$(g.region -m  | grep n= | awk -F "=" '{ print $2   }' )
sS=$(g.region -m  | grep n= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region e=$lrx w=$ulx  n=$nS s=$sS   res=0:00:03
r.mapcalc " lbasin_nstripe    = lbasin " --o

g.region region=crop
echo bottom stripe 
sS=$(g.region -m  | grep ^s= | awk -F "=" '{ print $2   }' )
nS=$(g.region -m  | grep ^s= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region  n=$nS s=$sS  res=0:00:09
r.mapcalc " lbasin_sstripe    = lbasin " --o

g.region region=crop # report on the basis of the region setting 
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

r.mask raster=lbasin_clean --o

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_intb/stream_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_intb/lbasin_$tile.tif  
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_intb/lbasin_$tile.tif.aux.xml 

r.mask raster=msk --o 

r.mapcalc  " lbasin_broke = if ( isnull(lbasin_clean ) , 1 , null()  )  "        --o 
r.mapcalc  " stream_broke = if ( isnull(lbasin_clean ) , stream  , null()  )  "  --o 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream_broke  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_brokb/stream_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin_broke  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif  
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif.aux.xml 

# rm -r /tmp/loc_$tile

exit 
