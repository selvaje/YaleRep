#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc08_crete_carving_layer_inmapset.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_crete_carving_layer_inmapset.sh.%J.err
#SBATCH --mail-user=email

# for RADIUS in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161  ; do export RADIUS ;  grep ^200   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  | xargs -n 2 -P 1 bash -c $' sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc08_crete_carving_layer_inmapset.sh $1 $2 GLOBE $RADIUS   ' _ ; done 

# for RADIUS in 161  ; do export RADIUS ;  grep ^200   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  | xargs -n 2 -P 1 bash -c $' sbatch   --export=N=$1,DIM=$2,GLOBE="GLOBE",RADIUS=$RADIUS    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc08_crete_carving_layer_inmapset.sh    ' _ ; done 

# cat  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt   | xargs -n 2 -P 1 bash -c $'   bsub -W 6:00 -n 1 -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_crete_carving_layer.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_crete_carving_layer.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc05_crete_carving_layer_inmapset.sh $1 $2 GLOBE ' _

# cat  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt   | xargs -n 2 -P 1 bash -c $'   bsub -W 6:00 -n 1 -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_crete_carving_layer.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_crete_carving_layer.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc05_crete_carving_layer_inmapset.sh $1 $2 EUROASIA ' _ 

# for RADIUS in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161  ; do export RADIUS ;  grep ^200   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  | xargs -n 2 -P 1 bash -c $'   bsub -W 6:00 -n 1 -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_crete_carving_layer.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_crete_carving_layer.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc05_crete_carving_layer_inmapset.sh $1 $2 GLOBE $RADIUS   ' _ ; done 


# bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc05_crete_carving_layer_inpaset.sh 001 20 GLOBE

# create the txt file 

# rm -f      /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 
# seq  10 10 150  | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 001 $DIM 
# ' _   >>    /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  

# seq  10 10 150  | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 005 $DIM 
# ' _   >>    /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  

# seq  10 10 150  | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 010 $DIM 
# ' _   >>    /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt  

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 100 $DIM 
# ' _   >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 200 $DIM
# ' _   >>   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 


# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 300 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 400 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 500 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 600 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 700 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 800 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 900 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

# seq 10 10 150 | xargs -n 1 -P 8 bash -c $'  
# DIM=$1
# echo 950 $DIM
# ' _  >>  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt 

cd         /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT 
rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_$GLOBE/PERMANENT/.gislock

r.mask   -r  --quiet

export DEM=be75_grd_LandEnlarge_$GLOBE
export OCCURENCE=occurrence_250m_$GLOBE
export STDEV=be75_grd_LandEnlarge_std${RADIUS}_norm_${GLOBE}_pk
export STDEVV=$RADIUS
export N=$N
export DIM=$DIM

echo log transform the water layer 

# # plot ( wa ,  100  * log(wa+1) / ( max(log(0+1)) -  min (log(100+1)))   )  ; log(1)=0   # log(OCCURENCE@PERMANENT + 1) /  4.615121  
                                                             #  gose from 0 to 4  
##  log( $OCCURENCE@PERMANENT + 1) /  4.615121  # log of the occurance /  4.615121  goes from 0 to 1 ; 0 no water at all 1 always water 
# first condition 
# log(occurence ) * altitude (from 10 to 30)

if [ $GLOBE = "GLOBE"     ]  ; then MASK=UNIT_noeuroasia      ; fi 
if [ $GLOBE = "EUROASIA"  ]  ; then MASK=UNIT497_338_3562_333 ; fi 


r.mask -r  --quiet
r.mask  raster=$MASK   --o

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc${OCCURENCE}_log${N}_DIM$DIM
export GISRC=$HOME/.grass7/rc${OCCURENCE}_log${N}_DIM$DIM

rm -fr  $DIR/grassdb/loc_river_fill_$GLOBE/${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  
g.mapset  -c  mapset=${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  location=loc_river_fill_$GLOBE  dbase=$DIR/grassdb   --quiet --overwrite 

echo create mapset ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}
cp $DIR/grassdb/loc_river_fill_$GLOBE/PERMANENT/WIND   $DIR/grassdb/loc_river_fill_$GLOBE/${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}/WIND

rm -f  $DIR/grassdb/loc_river_fill_$GLOBE/${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}/.gislock

g.gisenv 

g.region raster=UNIT3753_4000 # g.region raster=UNIT3753_4000    raster=$MASK    --o #   n=35 s=30 e=0 w=-10  #  
r.mask -r  --quiet
r.mask     raster=$MASK    --o

echo ${N} $DIM 

if [ $N = "001" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT ==  0 ||  $OCCURENCE@PERMANENT == 255  , 0 ,  $DIM  )"   --overwrite
fi 

if [ $N = "005" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  (  $OCCURENCE@PERMANENT  /  100  * $DIM   ), 0 )"   --overwrite
fi 

if [ $N = "010" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM   ), 0 )"   --overwrite
fi 

if [ $N = "100" ] ; then 
r.mapcalc "  ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}   = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * (( 1 - $STDEV )^2)), 0 )"   --overwrite
fi 

if [ $N = "200" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}   = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * (( 1 -  $STDEV  ))), 0 )"   --overwrite
fi 

if [ $N = "300" ] ; then 
r.mapcalc "  ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * (( $STDEV )^2)), 0 )"   --overwrite
fi    

if [ $N = "400" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * (( $STDEV ))), 0 )"   --overwrite
fi 

# stdev = seq( 0 , 1 , 0.01) 
# plot   (log  ( 101 -  stdev * 100  )   / 4.6151205 ) 
# points (1 -  ( log( 1 + stdev * 100  ) / 4.6151205 )) 

if [ $N = "500" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * (  (log( 101 -  ($STDEV * 100)))/4.6151205)), 0 )"   --overwrite
fi 

if [ $N = "600" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV} = if ( $OCCURENCE@PERMANENT < 101 ,  ( log( $OCCURENCE@PERMANENT + 1) /  4.615121 * $DIM * ( 1 - (log( 1 +  ($STDEV * 100)))/4.6151205)), 0 )"   --overwrite
fi 

# occ  = seq  ( 0 , 100 , 1) 
# plot ( log ( 1 + occ  )  /  4.615121 ) 
# points   ( 1 - log ( 101 - occ  )  /  4.615121 )

if [ $N = "700" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV} = if ( $OCCURENCE@PERMANENT < 101 ,  ( 1 - log( 101 - $OCCURENCE@PERMANENT ) /  4.615121 * $DIM * (  (log( 101 -  ($STDEV * 100)))/4.6151205)), 0 )"   --overwrite
fi 

if [ $N = "800" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV} = if ( $OCCURENCE@PERMANENT < 101 ,  ( 1 - log( 101 -  $OCCURENCE@PERMANENT ) /  4.615121 * $DIM * ( 1 - (log( 1 +  ($STDEV * 100)))/4.6151205)), 0 )"   --overwrite
fi 

if [ $N = "900" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( 1 - log( 101 - $OCCURENCE@PERMANENT ) /  4.615121 * $DIM *   (( 1 -  $STDEV  ))), 0 ) "   --overwrite
fi 

if [ $N = "950" ] ; then 
r.mapcalc " ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${STDEVV}  = if ( $OCCURENCE@PERMANENT < 101 ,  ( 1 - log( 101 -  $OCCURENCE@PERMANENT ) /  4.615121 * $DIM *  (( 1 -  $STDEV  ))), 0 ) "   --overwrite
fi 

