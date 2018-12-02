#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

# sbatch --export=N=200,DIM=140,UNIT=4000,GEO=GLOBE,RADIUS=71,TRH=8  --mem-per-cpu=20000  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 
# sbatch --export=N=200,DIM=20,UNIT=4000,GEO=GLOBE,RADIUS=71,TRH=8   --mem-per-cpu=20000  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 
# sbatch --export=N=200,DIM=20,UNIT=3753,GEO=GLOBE,RADIUS=71,TRH=8   --mem-per-cpu=43000   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 

# 1 2 3 4 5 6 7 8 9 10 11 12 13 14 154 573 810 1145 2597 3005 3317 3629 3753 4000 4001 

# best combination 200 log ; 120 depth ;  151 diamiter stdev ;  30798730 

# for UNIT in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 154 573 810 1145 2597 3005 3317 3629 3753 4000 4001 ; do RADIUS=151 ; N=200 ; DIM=120 ; RAM=$(awk -F "_" -v UNIT=$UNIT  '{ if ($1==UNIT) print $2  }'  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt ) ;   sbatch  --export=N=$N,DIM=$DIM,UNIT=$UNIT,GEO=GLOBE,RADIUS=$RADIUS,TRH=8 -J sc2x1_ReconditioningHydrodemCarving_UNIT${UNIT}_N${N}_DIM${DIM}_STDEV${RADIUS}_TRH${TRH}_final_GLOBAL.sh -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_ReconditioningHydrodemCarving_${UNIT}_final_GLOBAL.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_ReconditioningHydrodemCarving_${UNIT}_final_GLOBAL.%J.err   --mem-per-cpu=$RAM  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc21_ReconditioningHydrodemCarving_UNIT_final_GLOBAL.sh ; done

# 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810 497_338_3562_333 
# new one 
# 497 5656337      ?
# 346 6254072      
# 1145 7642013     japan 
# 810 7949852      UK  
# 3317 12175858    MADAGASCAR  
# 2597 14470128    borneo 
# 3005 15937346    guinea    
# 154 24790283     canada island
# 573 158907908    greenland 
# 3629 160965130   Australia 
# 4000 360948377  South America    * 
# 4001 578979392  Africa 
# 3753 659333926   north Amarica   * 
# 3562 1519030245  EUROASIA 
# 3767 8275779607  sea 

echo UNIT ${UNIT} TYPE ${N} DIMENSION ${DIM}  STDEV ${RADIUS}

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT/.gislock

export N
export DIM
export UNIT
export GEO
export RADIUS

export DEM=be75_grd_LandEnlarge_${GEO}
export OCCURENCE=occurrence_250m_${GEO}
export STDEV=be75_grd_LandEnlarge_std${RADIUS}_norm_${GEO}
export RPROJ=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK
export RSCRA=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc${UNIT}_${N}_${DIM}_STDEV${RADIUS}
export GISRC=$HOME/.grass7/rc${UNIT}_${N}_${DIM}_STDEV${RADIUS}

rm -fr  $RSCRA/grassdb/loc_river_fill_${GEO}/${UNIT}_${N}_${DIM}_STDEV${RADIUS}
g.mapset  -c  mapset=${UNIT}_${N}_${DIM}_STDEV${RADIUS}  location=loc_river_fill_${GEO}  dbase=$RSCRA/grassdb   --quiet --overwrite 

echo create mapset   ${UNIT}_${N}_${DIM}_STDEV${RADIUS}
cp $RSCRA/grassdb/loc_river_fill_${GEO}/PERMANENT/WIND $RSCRA/grassdb/loc_river_fill_${GEO}/${UNIT}_${N}_${DIM}_STDEV${RADIUS}/WIND

g.mapsets   mapset=${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}   operation=add

rm -f  $RSCRA/grassdb/loc_river_fill_${GEO}/${UNIT}_${N}_${DIM}_STDEV${RADIUS}/.gislock

g.gisenv 

g.region   raster=UNIT${UNIT}   --o 
# g.region   n=41  s=35  w=-90  e=-77  --o   #    for stady area in USA
r.mask -r  --quiet
r.mask     raster=UNIT${UNIT}   --o

echo  carving 
r.mapcalc "${DEM}_carv  = ${DEM}@PERMANENT  -  fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}@fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS} "  --overwrite

echo  procedure to smoth the border 

NEIG=3

echo start r.neighbors 
r.neighbors -c  input=${DEM}_carv  output=${DEM}_carvFilter   method=average  size=$NEIG  selection=${OCCURENCE}_G_null_1@PERMANENT  --overwrite 

echo start r.hydridem                                                                                               # memory=65000 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.hydrodem    input=${DEM}_carvFilter   output=${DEM}_cond   memory=65000  --overwrite 

echo start the output 
r.colors -r  ${DEM}_cond
r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16  input=${DEM}_cond  output=$RPROJ/dem_unit_cond/${DEM}_cond${UNIT}_log${N}_DIM${DIM}_w$NEIG.tif
r.colors -r  ${OCCURENCE} 
r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16  input=${OCCURENCE} output=$RPROJ/GSW_unit/${OCCURENCE}_$UNIT.tif 
                                                                                                                               # memory=65000 
r.watershed -a  -b  elevation=${DEM}_cond   basin=basin  stream=stream   drainage=drainage   accumulation=accumulation   memory=65000  threshold=$TRH  --overwrite

r.colors -r stream
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"       type=UInt32 format=GTiff nodata=0   input=stream  output=$RPROJ/output/stream_unit/idstream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

pkcreatect   -min 0 -max 1 > /dev/shm/color$UNIT.txt
pkgetmask -ct /dev/shm/color$UNIT.txt   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 0.5 -max 9999999999 -data 1 -i $RPROJ/output/stream_unit/idstream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif  -o  $RPROJ/output/stream_unit/bistream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
gdal_edit.py   -a_nodata 0  $RPROJ/output/stream_unit/bistream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
rm -f  /dev/shm/color$UNIT.txt 

r.colors -r basin
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=basin  output=$RPROJ/output/basin_unit/basin${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.order --quiet    stream_rast=stream  direction=drainage accumulation=accumulation  elevation=${DEM}_cond strahler=stream_strahler horton=stream_horton shreve=stream_shreve hack=stream_hack topo=stream_topo memory=65000  --overwrite 
r.colors -r stream_trahler
r.colors -r stream_horton
r.colors -r stream_shreve
r.colors -r stream_hack
r.colors -r stream_topo

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_strahler  output=$RPROJ/output/stream_order_unit/strahler${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_horton   output=$RPROJ/output/stream_order_unit/horton${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_shreve   output=$RPROJ/output/stream_order_unit/shreve${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_hack     output=$RPROJ/output/stream_order_unit/hack${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_topo    output=$RPROJ/output/stream_order_unit/topo${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=drainage basins=lbasin memory=65000
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=lbasin  output=$RPROJ/output/lbasin_unit/lbasin${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
rm -f $RPROJ/output/lbasin_unit/lbasin${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif.aux.xml


sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 
exit 




if [ ${GEO}  = "EUROASIA" ] ; then  

for ZONE in LEFT CENTER RIGHT ; do 

# for ZONE in RIGHT ; do 

if [ $ZONE  = LEFT ]   ; then  g.region  e=53        res=0:00:07.5  ; fi 
if [ $ZONE = CENTER ]  ; then  g.region  w=-20  e=92 res=0:00:07.5  ; fi 
if [ $ZONE = RIGHT ]   ; then  g.region  w=90        res=0:00:07.5  ; fi 

r.watershed  -b  elevation=${DEM}_cond   basin=basin  stream=stream   drainage=drainage   accumulation=accumulation   memory=65000  threshold=$TRH  --overwrite
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=UInt32 format=GTiff nodata=0   input=stream  output=/dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif 
rm -f /dev/shm/stream${UNIT}_log${N}_DIM${DIM}.tif

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct $RSCRA/grassdb/color0_1.txt -ot Byte -min 0.5 -max 9999999999 -data 1 -i  /dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif  -o  $RSCRA/output/stream_unit/stream${UNIT}_${ZONE}log${N}_DIM${DIM}.tif
rm -f   /dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif 

r.mask  raster=stream  --o
r.mapcalc  " ${OCCURENCE}_STRbin =   ${OCCURENCE}_null_1   "   --overwrite 

r.report -n -h  units=c map=${OCCURENCE}_STRbin | awk -v UNIT=$UNIT -v N=$N  -v DIM=$DIM  -F "|"  '{if(NR==5) print $(NF-1), UNIT ,DIM, N }' > $RSCRA/output/txt/stream${UNIT}_${ZONE}_log${N}_DIM${DIM}.txt 

r.mask  raster=UNIT${UNIT}   --o

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=${OCCURENCE}_STRbin  output=$RSCRA/output/stream_unit/streamBIN${UNIT}_${ZONE}_log${N}_DIM${DIM}.tif 

done 
rm -fr  $RSCRA/grassdb/loc_river_fill_${GEO}/${UNIT}_${N}_${DIM} 
fi 
