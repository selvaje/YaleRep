
# BBE ? 
# DSSR 
# EMT 
# FAPAR
# GPP
# LAI
# PAR

YYYY=1982
RAM=/dev/shm 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/LAI/hdf/GLASS01B02.V04.A1982001.2017269.hdf  /$RAM/GLASS01B02.V04.A1982001.2017269.tif 

rm -r $RAM/loc_$YYYY
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh    $RAM loc_$YYYY   $RAM/GLASS01B02.V04.A1982001.2017269.tif  

g.remove -f type=rast name=GLASS01B02.V04.A1982001.2017269

for file in  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/LAI/hdf/*.hdf  ; do 
cp $file $RAM
filename=$(basename $file .hdf )
r.external  input=$RAM/$filename.hdf      output=$filename   --overwrite 
done 
# g.extension extension=r.hants
g.list type=raster pattern="GLASS01B02.V04.A19820??.2017269" output=filelist.csv  
/gpfs/loomis/home.grace/fas/sbsc/ga254/.grass7/addons/bin/r.hants file=filelist.csv  nf=3 dod=5 delta=0.1 base_period=13


exit 

r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9"   hdf_hants 
rm -r $RAM/loc_$YYYY  rm -r $RAM/*.hdf


