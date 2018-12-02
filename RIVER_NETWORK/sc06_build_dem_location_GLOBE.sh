# bsub  -q week  -W 48:00  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_build_dem_location_GLOBE.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_build_dem_location_GLOBE.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc04_build_dem_location_GLOBE.sh 

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
# 4000 360948377  South America 
# 4001 578979392  Africa 
# 3753 659333926   north Amarica 
# 3562 1519030245  EUROASIA 
# 3767 8275779607  sea 

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

####  comment rm for securit   
#### rm -rf   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE
#### source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb loc_river_fill_GLOBE  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem/be75_grd_LandEnlarge.tif 

rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2.sh   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT 
rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock

## g.region n=-11.9395833333333 s=-25.6145833333333 w=43.2125 e=50.5020833333333  
g.rename raster=be75_grd_LandEnlarge,be75_grd_LandEnlarge_GLOBE

# # 100 water ; 0 land ; 255 no data > transformed to 0 
gdal_edit.py  -a_nodata  -1   /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence_250m.tif 
r.in.gdal in=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence_250m.tif  out=occurrence_250m_GLOBE  memory=2047  --overwrite

for UNIT in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810   ; do 
r.in.gdal in=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/unit/UNIT${UNIT}msk.tif     out=UNIT$UNIT   --overwrite  
done 

r.in.gdal in=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_noeuroasia.tif   out=UNIT_noeuroasia   --overwrite  

# # compute standard deviation 

r.mask -r  --quiet
r.mask  raster=UNIT_noeuroasia   --o

echo fill one cell gap
r.mapcalc  " occurrence_250m_GLOBE_null_1 = if ( occurrence_250m_GLOBE  == 0 ||  occurrence_250m_GLOBE  == 255 ,  null()  , 1 )"   --overwrite

echo start the first filter 
r.mapcalc --o  <<EOF 
filterUL2_GLOBE = if ((        occurrence_250m_GLOBE_null_1[-1,1]==1 && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&       occurrence_250m_GLOBE_null_1[1,0]==1 && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 ,  null())
filterUL3_GLOBE = if ((        occurrence_250m_GLOBE_null_1[-1,1]==1 && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0]) && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&     occurrence_250m_GLOBE_null_1[1,-1]==1) , 1 ,  null()) 
filterUL4_GLOBE = if ((        occurrence_250m_GLOBE_null_1[-1,1]==1 && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0]) && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) &&     occurrence_250m_GLOBE_null_1[0,-1]==1 && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 ,   null()) 
filterUC1_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) &&      occurrence_250m_GLOBE_null_1[0,1]==1  &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&     occurrence_250m_GLOBE_null_1[1,-1]==1) , 1 , null())
filterUC2_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) &&     occurrence_250m_GLOBE_null_1[0,1]==1   &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) &&     occurrence_250m_GLOBE_null_1[0,-1]==1 && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterUC3_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) &&     occurrence_250m_GLOBE_null_1[0,1]==1   &&  isnull(occurrence_250m_GLOBE_null_1[1,1]) && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                                   occurrence_250m_GLOBE_null_1[-1,-1]==1  && isnull(occurrence_250m_GLOBE_null_1[0,-1]) && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterUR2_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&      occurrence_250m_GLOBE_null_1[1,1]==1  && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) &&    occurrence_250m_GLOBE_null_1[0,-1]==1  && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
EOF

echo start the second filter 
r.mapcalc --o  <<EOF 
filterUR3_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&       occurrence_250m_GLOBE_null_1[1,1]==1 && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                                    occurrence_250m_GLOBE_null_1[-1,-1]==1  && isnull(occurrence_250m_GLOBE_null_1[0,-1]) && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterUR4_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&       occurrence_250m_GLOBE_null_1[1,1]==1  && \
                                    occurrence_250m_GLOBE_null_1[-1,0]==1  && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) && isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterRC1_GLOBE = if ((       occurrence_250m_GLOBE_null_1[-1,1]==1  && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1])  && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&       occurrence_250m_GLOBE_null_1[1,0]==1      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&  isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterRC2_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1])  && \
                                     occurrence_250m_GLOBE_null_1[-1,0]==1 && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&       occurrence_250m_GLOBE_null_1[1,0]==1      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&  isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterRC3_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1])  && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&    occurrence_250m_GLOBE_null_1[1,0]==1   && \  
                               occurrence_250m_GLOBE_null_1[-1,-1]==1 && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&  isnull(occurrence_250m_GLOBE_null_1[1,-1])) , 1 , null())
filterRL2_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) &&       occurrence_250m_GLOBE_null_1[0,1]==1 &&  isnull(occurrence_250m_GLOBE_null_1[1,1])  && \
                                isnull(occurrence_250m_GLOBE_null_1[-1,0]) && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&     occurrence_250m_GLOBE_null_1[1,-1]==1) , 1 , null())
filterRL3_GLOBE = if ((   isnull(occurrence_250m_GLOBE_null_1[-1,1]) && isnull(occurrence_250m_GLOBE_null_1[0,1])  &&  isnull(occurrence_250m_GLOBE_null_1[1,1])  && \
                                    occurrence_250m_GLOBE_null_1[-1,0]==1 && isnull(occurrence_250m_GLOBE_null_1[0,0])  &&  isnull(occurrence_250m_GLOBE_null_1[1,0])      && \
                               isnull(occurrence_250m_GLOBE_null_1[-1,-1]) && isnull(occurrence_250m_GLOBE_null_1[0,-1]) &&     occurrence_250m_GLOBE_null_1[1,-1]==1 ) , 1 , null())
EOF


r.mapcalc " occurrence_250m_GLOBE_fill_null_1   = if (( if ( isnull(filterRC1_GLOBE), 0 , 1) +  if ( isnull(filterRC2_GLOBE), 0 , 1) +  if ( isnull(filterRC3_GLOBE), 0 , 1) +  if ( isnull(filterRL2_GLOBE), 0 , 1) +  if ( isnull(filterRL3_GLOBE), 0 , 1) +  if ( isnull(filterUC1_GLOBE), 0 , 1) +  if ( isnull(filterUC2_GLOBE), 0 , 1) +  if ( isnull(filterUC3_GLOBE), 0 , 1) +  if ( isnull(filterUL2_GLOBE), 0 , 1) +  if ( isnull(filterUL3_GLOBE), 0 , 1) +  if ( isnull(filterUL4_GLOBE), 0 , 1) +  if ( isnull(filterUR2_GLOBE), 0 , 1) +  if ( isnull(filterUR3_GLOBE), 0 , 1) +  if ( isnull(filterUR4_GLOBE), 0 , 1)) > 0 , 1 , null()) " 

g.remove -f type=rast  pattern=filter*_GLOBE

# create null and value to be sure that the 0 is not used in the filter 
r.mapcalc  " occurrence_250m_GLOBE_null_value = if ( occurrence_250m_GLOBE  == 0 ||  occurrence_250m_GLOBE  == 255 ,  null()  , occurrence_250m_GLOBE  )"   --overwrite

# filter only the cels tha have been added                         
r.neighbors  input=occurrence_250m_GLOBE_null_value  output=occurrence_250m_GLOBE_null_value_F   method=average  size=3  selection=occurrence_250m_GLOBE_fill_null_1     --overwrite

g.remove -f type=rast name=occurrence_250m_GLOBE_fill_null_1 

# use the fill occurence to produel null and 1 value 
r.mapcalc  " occurrence_250m_GLOBE_null_1 = if (  occurrence_250m_GLOBE_null_value_F < 101    ,  1  , null() )"   --overwrite

echo r.grow world   
r.grow  input=occurrence_250m_GLOBE_null_1   output=occurrence_250m_GLOBE_G_null_1_2    radius=1.01  new=1 old=2             --overwrite 
r.mapcalc  " occurrence_250m_GLOBE_G_null_1  = if ( occurrence_250m_GLOBE_G_null_1_2 == 1   , 1  , null()  )"                --overwrite  # use later on to smoth the border 
g.remove -f  type=rast  name=occurrence_250m_GLOBE_G_null_1_2

r.mapcalc  " occurrence_250m_GLOBE_value_0  = if (  isnull(occurrence_250m_GLOBE_null_value_F) ,  0  ,  occurrence_250m_GLOBE_null_value_F  )"   --overwrite
g.remove -f type=rast name=occurrence_250m_GLOBE_null_value_F


