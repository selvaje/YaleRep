#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_crete_carving_layer_inmapset_EUROASIA.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_crete_carving_layer_inmapset_EUROASIA.sh.%J.err
#SBATCH --mail-user=email

# best combination 200 log ; 120 depth ;  151 diamiter stdev ;  30798730
# sbatch   --export=N=200,DIM=120,GLOBE="EUROASIA",RADIUS=151  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc20_crete_carving_layer_inmapset_EUROASIA.sh 

# create the txt file 

cd         /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT/.gislock
source /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT 
rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT/.gislock

r.mask   -r  --quiet

export DEM=be75_grd_LandEnlarge_$GLOBE
export OCCURENCE=occurrence_250m_$GLOBE
export STDEVV=$RADIUS
export N=$N
export DIM=$DIM

echo log transform the water layer 

if [ $GLOBE = "GLOBE"     ]  ; then MASK=UNIT_noeuroasia      ; fi 
if [ $GLOBE = "EUROASIA"  ]  ; then MASK=UNIT497_338_3562_333 ; fi 

r.mask -r  --quiet
r.mask  raster=$MASK   --o

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc_fin_${OCCURENCE}_log${N}_DIM$DIM
export GISRC=$HOME/.grass7/rc_fin_${OCCURENCE}_log${N}_DIM$DIM

rm -fr  $DIR/grassdb/loc_river_fill_$GLOBE/fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  
g.mapset  -c  mapset=fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  location=loc_river_fill_$GLOBE  dbase=$DIR/grassdb   --quiet --overwrite 

echo create mapset fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}
cp $DIR/grassdb/loc_river_fill_$GLOBE/PERMANENT/WIND   $DIR/grassdb/loc_river_fill_$GLOBE/fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}/WIND

rm -f  $DIR/grassdb/loc_river_fill_$GLOBE/fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}/.gislock

g.gisenv 

g.region raster=$MASK    --o 
r.mask -r  --quiet
r.mask raster=$MASK  --o

echo ${N} $DIM 

# dem standard deviation  displacement 
RAM=/dev/shm
DPROJ=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK

xminEAo=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3  )}')
xymaxEAo=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxEAo=180
yminEAo=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 40209 )) }')

echo $xminEAo $ymaxEAo $xmaxEAo $yminEAo 3562_333.tif EUROASIA original 
                                                                            
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $xminEAo $ymaxEAo $xmaxEAo $yminEAo $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}.tif $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT3562_333.tif

xminCAo=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3  )}')  # -180 
ymaxCAo=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxCAo=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3 + ( 0.002083333333333 * 4990)) }')
yminCAo=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 3575)) }')


echo $xminCAo $ymaxCAo $xmaxCAo $yminCAo 497_338.tif  camptacha original 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $xminCAo $ymaxCAo $xmaxCAo $yminCAo  $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}.tif $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT497_338.tif

# displacement 

xminEAd=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3 -50 )}')
ymaxEAd=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxEAd=$( expr 180 - 50 )
yminEAd=$(gdalinfo $DPROJ/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 40209 ))    }')

echo $xminEAd $ymaxEAd $xmaxEAd $yminEAd  3562_333.tif EUROASIA displacement 

gdal_edit.py -a_ullr $xminEAd $ymaxEAd $xmaxEAd $yminEAd  $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT3562_333.tif

xminCAd=$(expr 180 - 50 )
ymaxCAd=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  ) }')
xmaxCAd=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" , 130 + 180 +   $3 + ( 0.002083333333333 * 4990)) }')
yminCAd=$(gdalinfo $DPROJ/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 3575  ))    }')

echo  $xminCAd $ymaxCAd $xmaxCAd $yminCAd 497_338.tif  camptacha original 
gdal_edit.py -a_ullr  $xminCAd $ymaxCAd $xmaxCAd $yminCAd     $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT497_338.tif # camptacha  

rm -f  $DPROJ/dem_stdev/stdev${RADIUS}/out.vrt
gdalbuildvrt  $DPROJ/dem_stdev/stdev${RADIUS}/out.vrt  $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT3562_333.tif $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT497_338.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $DPROJ/dem_stdev/stdev${RADIUS}/out.vrt $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}_${GLOBE}.tif
rm -f  $DPROJ/dem_stdev/stdev${RADIUS}/out.vrt $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT3562_333.tif $DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}m_UNIT497_338.tif 

## importing x

if [ $N = "200" ] ; then 
r.in.gdal in=$DPROJ/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}_${GLOBE}.tif  out=fin_be75_grd_LandEnlarge_std${RADIUS}_${GLOBE}_pk --overwrite  memory=2000
                                                                    
r.mapcalc "fin_be75_grd_LandEnlarge_std${RADIUS}_norm_${GLOBE}_pk = fin_be75_grd_LandEnlarge_std${RADIUS}_${GLOBE}_pk / $( r.info fin_be75_grd_LandEnlarge_std${RADIUS}_${GLOBE}_pk  | grep max | awk '{  print $10".0"  }' ) "  --overwrite
r.mapcalc "fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV} = if( $OCCURENCE@PERMANENT < 101 , ( log( $OCCURENCE@PERMANENT + 1) / 4.615121 * $DIM * (( 1 - fin_be75_grd_LandEnlarge_std${RADIUS}_norm_${GLOBE}_pk ))), 0 )"  --overwrite
fi 

for ZONE in RIGHT ; do   RADIUS=151 ; N=200 ; DIM=120 ; if [ $ZONE = RIGHT ]  ; then  RAM=9400 ; else RAM=68000  ; fi  ;  sbatch --export=N=$N,DIM=$DIM,GEO=EUROASIA,ZONE=$ZONE,RADIUS=$RADIUS,TRH=8 -J sc21_ReconditioningHydrodemCarving_N${N}_DIM${DIM}_STDEV${RADIUS}_TRH${TRH}_final_$ZONE.sh -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_ReconditioningHydrodemCarving_final_$ZONE.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_ReconditioningHydrodemCarving_final_$ZONE.%J.err   --mem-per-cpu=$RAM  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc21_ReconditioningHydrodemCarving_UNIT_final_EUROASIA.sh ; done


