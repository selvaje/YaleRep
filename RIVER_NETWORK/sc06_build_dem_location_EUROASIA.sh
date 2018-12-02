#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_build_dem_location_EUROASIA.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_build_dem_location_EUROASIA.sh.%J.err 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_build_dem_location_EUROASIA.sh 

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK
export DIRS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

####  comment rm for security   
rm -rf   $DIRS/RIVER_NETWORK/grassdb/loc_river_fill_EUROASIA
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh   $DIRS/grassdb loc_river_fill_EUROASIA  $DIRP/dem_EUROASIA/be75_grd_LandEnlarge_EUROASIA.tif

# rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_EUROASIA/PERMANENT/.gislock
# source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_EUROASIA/PERMANENT 
rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_EUROASIA/PERMANENT/.gislock

r.in.gdal   in=$DIRP/unit/UNIT497_338_3562_333msk.tif     out=UNIT497_338_3562_333   --overwrite    memory=2047 

g.region raster=UNIT497_338_3562_333  --o
r.mask   raster=UNIT497_338_3562_333   --o

# # 100 water ; 0 land ; 255 no data > transformed to 0 
gdal_edit.py  -a_nodata  -1   $DIRP/GSW_unit/occurrence_250m_EUROASIA.tif 
r.in.gdal  in=$DIRP/GSW_unit/occurrence_250m_EUROASIA.tif   out=occurrence_250m_EUROASIA  memory=2047  --overwrite

# # # compute standard deviation 

echo fill one cell gap 
r.mapcalc  " occurrence_250m_EUROASIA_null_1 = if ( occurrence_250m_EUROASIA  == 0 ||  occurrence_250m_EUROASIA  == 255 ,  null()  , 1 )"   --overwrite

echo first filter 

r.mapcalc --o  <<EOF 
filterUL2_EUROASIA = if ((        occurrence_250m_EUROASIA_null_1[-1,1]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&       occurrence_250m_EUROASIA_null_1[1,0]==1 && \
                             isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 ,  null())
filterUL3_EUROASIA = if ((        occurrence_250m_EUROASIA_null_1[-1,1]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0]) && \
                             isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&     occurrence_250m_EUROASIA_null_1[1,-1]==1) , 1 ,  null()) 
filterUL4_EUROASIA = if ((        occurrence_250m_EUROASIA_null_1[-1,1]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0]) && \
                              isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) &&     occurrence_250m_EUROASIA_null_1[0,-1]==1 && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null()) 
filterUC1_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) &&      occurrence_250m_EUROASIA_null_1[0,1]==1  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                               isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&     occurrence_250m_EUROASIA_null_1[1,-1]==1) , 1 , null())
filterUC2_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) &&     occurrence_250m_EUROASIA_null_1[0,1]==1   &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                               isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) &&     occurrence_250m_EUROASIA_null_1[0,-1]==1 && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterUC3_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) &&     occurrence_250m_EUROASIA_null_1[0,1]==1   &&  isnull(occurrence_250m_EUROASIA_null_1[1,1]) && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                                   occurrence_250m_EUROASIA_null_1[-1,-1]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterUR2_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&      occurrence_250m_EUROASIA_null_1[1,1]==1  && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                               isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) &&    occurrence_250m_EUROASIA_null_1[0,-1]==1  && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
EOF

echo second  filter 

r.mapcalc --o  <<EOF 
filterUR3_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&       occurrence_250m_EUROASIA_null_1[1,1]==1 && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                                  occurrence_250m_EUROASIA_null_1[-1,-1]==1  && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterUR4_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&       occurrence_250m_EUROASIA_null_1[1,1]==1  && \
                                    occurrence_250m_EUROASIA_null_1[-1,0]==1  && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                              isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) && isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterRC1_EUROASIA = if ((       occurrence_250m_EUROASIA_null_1[-1,1]==1  && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1])  && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&       occurrence_250m_EUROASIA_null_1[1,0]==1      && \
                             isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&  isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterRC2_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1])  && \
                                     occurrence_250m_EUROASIA_null_1[-1,0]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&       occurrence_250m_EUROASIA_null_1[1,0]==1      && \
                             isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&  isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterRC3_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1])  && \
                               isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&    occurrence_250m_EUROASIA_null_1[1,0]==1   && \  
                               occurrence_250m_EUROASIA_null_1[-1,-1]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&  isnull(occurrence_250m_EUROASIA_null_1[1,-1])) , 1 , null())
filterRL2_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) &&       occurrence_250m_EUROASIA_null_1[0,1]==1 &&  isnull(occurrence_250m_EUROASIA_null_1[1,1])  && \
                                isnull(occurrence_250m_EUROASIA_null_1[-1,0]) && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                               isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&     occurrence_250m_EUROASIA_null_1[1,-1]==1) , 1 , null())
filterRL3_EUROASIA = if ((   isnull(occurrence_250m_EUROASIA_null_1[-1,1]) && isnull(occurrence_250m_EUROASIA_null_1[0,1])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,1])  && \
                                    occurrence_250m_EUROASIA_null_1[-1,0]==1 && isnull(occurrence_250m_EUROASIA_null_1[0,0])  &&  isnull(occurrence_250m_EUROASIA_null_1[1,0])      && \
                              isnull(occurrence_250m_EUROASIA_null_1[-1,-1]) && isnull(occurrence_250m_EUROASIA_null_1[0,-1]) &&     occurrence_250m_EUROASIA_null_1[1,-1]==1 ) , 1 , null())
EOF


r.mapcalc " occurrence_250m_EUROASIA_fill_null_1   = if (( if ( isnull(filterRC1_EUROASIA), 0 , 1) +  if ( isnull(filterRC2_EUROASIA), 0 , 1) +  if ( isnull(filterRC3_EUROASIA), 0 , 1) +  if ( isnull(filterRL2_EUROASIA), 0 , 1) +  if ( isnull(filterRL3_EUROASIA), 0 , 1) +  if ( isnull(filterUC1_EUROASIA), 0 , 1) +  if ( isnull(filterUC2_EUROASIA), 0 , 1) +  if ( isnull(filterUC3_EUROASIA), 0 , 1) +  if ( isnull(filterUL2_EUROASIA), 0 , 1) +  if ( isnull(filterUL3_EUROASIA), 0 , 1) +  if ( isnull(filterUL4_EUROASIA), 0 , 1) +  if ( isnull(filterUR2_EUROASIA), 0 , 1) +  if ( isnull(filterUR3_EUROASIA), 0 , 1) +  if ( isnull(filterUR4_EUROASIA), 0 , 1)) > 0 , 1 , null()) " 

# g.remove -f type=rast  pattern=filter*_EUROASIA

# create null and value to be sure that the 0 is not used in the filter 
r.mapcalc  " occurrence_250m_EUROASIA_null_value = if ( occurrence_250m_EUROASIA  == 0 ||  occurrence_250m_EUROASIA  == 255 ,  null()  , occurrence_250m_EUROASIA  )"   --overwrite

# filter only the cels tha have been added                         
r.neighbors  input=occurrence_250m_EUROASIA_null_value  output=occurrence_250m_EUROASIA_null_value_F   method=average  size=3  selection=occurrence_250m_EUROASIA_fill_null_1     --overwrite

g.remove -f type=rast name=occurrence_250m_EUROASIA_fill_null_1 

# use the fill occurence to produel null and 1 value 
r.mapcalc  " occurrence_250m_EUROASIA_null_1 = if (  occurrence_250m_EUROASIA_null_value_F < 101    ,  1  , null() )"   --overwrite

echo r.grow world   
r.grow  input=occurrence_250m_EUROASIA_null_1   output=occurrence_250m_EUROASIA_G_null_1_2    radius=1.01  new=1 old=2             --overwrite 
r.mapcalc  " occurrence_250m_EUROASIA_G_null_1  = if ( occurrence_250m_EUROASIA_G_null_1_2 == 1   , 1  , null()  )"                --overwrite  # use later on to smoth the border 
g.remove -f  type=rast  name=occurrence_250m_EUROASIA_G_null_1_2

r.mapcalc  " occurrence_250m_EUROASIA_value_0  = if (  isnull(occurrence_250m_EUROASIA_null_value_F) ,  0  ,  occurrence_250m_EUROASIA_null_value_F  )"   --overwrite
g.remove -f type=rast name=occurrence_250m_EUROASIA_null_value_F

sbatch   --export=N=200,DIM=120,GLOBE="EUROASIA",RADIUS=151  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc20_crete_carving_layer_inmapset_EUROASIA.sh  



