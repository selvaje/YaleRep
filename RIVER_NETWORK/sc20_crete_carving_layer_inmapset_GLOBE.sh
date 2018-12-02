#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_crete_carving_layer_inmapset_GLOBE.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_crete_carving_layer_inmapset_GLOBE.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# best combination 200 log ; 120 depth ;  151 diamiter stdev ;  30798730 
# sbatch   --export=N=200,DIM=120,GLOBE="GLOBE",RADIUS=151  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc20_crete_carving_layer_inmapset_GLOBE.sh 

# create the txt file 

cd         /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT 
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
r.mask     raster=$MASK  --o

echo ${N} $DIM 

if [ $N = "200" ] ; then 
r.in.gdal in=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}.tif out=fin_be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk --overwrite  memory=2000

r.mapcalc "fin_be75_grd_LandEnlarge_std${RADIUS}_norm_GLOBE_pk = fin_be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk / $( r.info fin_be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk  | grep max | awk '{  print $10".0"  }' ) "  --overwrite
r.mapcalc "fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV} = if( $OCCURENCE@PERMANENT < 101 , ( log( $OCCURENCE@PERMANENT + 1) / 4.615121 * $DIM * (( 1 - fin_be75_grd_LandEnlarge_std${RADIUS}_norm_GLOBE_pk ))), 0 )"  --overwrite
fi 



