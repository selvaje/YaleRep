#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_stream_extract_tiles.sh.%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_stream_extract_tiles.sh.%A_%a.out  
#SBATCH --mem-per-cpu=15000
#SBATCH --array=1-1

## file number 1150 
# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# awk '{ if ($5 <= 90 && $7 >= -60 )  print }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_10d.txt  | xargs -n 13 -P 1  bash -c $' tile=$1 ; w=$4 ; n=$5 ; e=$6 ; s=$7 ; sbatch  --export=tile=$tile,n=$n,s=$s,e=$e,w=$w   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_stream_extract_tiles.sh ' _ 

export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR) { gsub("_dem.tif","") ;   print $1 } }'  /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/tiles_corners.txt )
export w=$( awk -v AR=$SLURM_ARRAY_TASK_ID    '{ if(NR==AR)  print int($2)  }'  /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/tiles_corners.txt )
export n=$( awk -v AR=$SLURM_ARRAY_TASK_ID    '{ if(NR==AR)  print int($3)  }'  /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/tiles_corners.txt )
export e=$( awk -v AR=$SLURM_ARRAY_TASK_ID    '{ if(NR==AR)  print int($4)  }'  /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/tiles_corners.txt )
export s=$( awk -v AR=$SLURM_ARRAY_TASK_ID    '{ if(NR==AR)  print int($5)  }'  /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/tiles_corners.txt )

echo tile n=$n s=$s w=$w e=$e 

export GRASS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb
export DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  $GRASS/loc_MERIT_ALL/PERMANENT

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc$tile
export GISRC=$HOME/.grass7/rc$tile

rm -fr  $GRASS/loc_MERIT_ALL/map_$tile
g.mapset  -c  mapset=map_$tile   location=loc_MERIT_ALL   dbase=$GRASS   --quiet --overwrite 

echo create mapset $tile 
cp $GRASS/loc_MERIT_ALL/PERMANENT/WIND   $GRASS/loc_MERIT_ALL/map_$tile/WIND

rm -f  $GRASS/loc_MERIT_ALL/map_$tile/.gislock

g.gisenv 
r.mask raster=msk@PERMANENT --o


wL=$( expr $w - 4 )   ; if [ $wL -lt  -180  ] ; then wL=-180 ; fi  
nL=$( expr $n + 4 )   ; if [ $nL -gt   85   ] ; then nL=85   ; fi  
eL=$( expr $e + 4 )   ; if [ $wL -gt   180  ] ; then mL=180  ; fi  
sL=$( expr $s - 4 )   ; if [ $sL -lt  -60  ]  ; then sL=-60  ; fi  

echo enlarge region n=$nL s=$sL w=$wL e=$eL 
g.region n=$nL s=$sL e=$eL w=$wL save=enlarge --o

r.stream.extract elevation=elv  accumulation=upa threshold=5 depression=dep                direction=dir_$tile   stream_raster=stream_$tile memory=14000 --o --verbose 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream_$tile  direction=dir_$tile   basins=lbasin_$tile   memory=14000 --o --verbose 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin_${tile}  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif  

echo left stripe 
eS=$(g.region -m  | grep e= | awk -F "=" '{ print $2   }' )
wS=$(g.region -m  | grep e= | awk -F "=" '{ printf ("%.14f\n" , $2 -  0.000833333333333 ) }' )

g.region n=$nL s=$sL  e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_${tile}_wstripe    = lbasin_${tile} " --o

g.region region=enlarge
echo right stripe 
wS=$(g.region -m  | grep w= | awk -F "=" '{ print $2   }' )
eS=$(g.region -m  | grep w= | awk -F "=" '{ printf ("%.14f\n" , $2 +  0.000833333333333 ) }' )

g.region n=$nL s=$sL e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_${tile}_estripe    = lbasin_${tile} " --o

####

g.region region=enlarge
echo top stripe 
nS=$(g.region -m  | grep n= | awk -F "=" '{ print $2   }' )
sS=$(g.region -m  | grep n= | awk -F "=" '{ printf ("%.14f\n" , $2 -  0.000833333333333 ) }' )

g.region  n=$nS s=$sS  e=$eL w=$wL  res=0:00:03
r.mapcalc " lbasin_${tile}_nstripe    = lbasin_${tile} " --o

g.region region=enlarge
echo bottom stripe 
sS=$(g.region -m  | grep ^s= | awk -F "=" '{ print $2   }' )
nS=$(g.region -m  | grep ^s= | awk -F "=" '{ printf ("%.14f\n" , $2 +  0.000833333333333 ) }' )

g.region e=$eL w=$wL n=$nS s=$sS  res=0:00:03
r.mapcalc " lbasin_${tile}_sstripe    = lbasin_${tile} " --o

g.region region=enlarge # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_${tile}_estripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_${tile}_wstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_${tile}_sstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_${tile}_nstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
       <( r.report -n -h units=c map=lbasin_${tile}         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) \
      | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${tile}_reclass.txt 
r.reclass input=lbasin_${tile}  output=lbasin_${tile}_rec   rules=/dev/shm/lbasin_${tile}_reclass.txt   --o
 
rm -f /dev/shm/lbasin_${tile}_reclass.txt 

r.mapcalc  " lbasin_${tile}_clean = lbasin_${tile}_rec  " --o
g.remove -f  type=raster name=lbasin_${tile}_rec,lbasin_${tile}_estripe,lbasin_${tile}_wstripe,lbasin_${tile}_nstripe,lbasin_${tile}_sstripe 

r.mask raster=lbasin_${tile}_clean --o

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream_${tile}  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles/stream_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin_${tile}  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles/lbasin_$tile.tif  
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles/lbasin_$tile.tif.aux.xml 
exit 


