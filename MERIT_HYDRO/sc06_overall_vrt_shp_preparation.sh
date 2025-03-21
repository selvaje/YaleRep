

### bash  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc06_overall_vrt_shp_preparation.sh 

source  ~/bin/gdal3
source  ~/bin/pktools 

export HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

### displacement tiles n65w180  n65w175 n65w170 n60w180  n60w175 n70w180 

echo elv dep msk are upa  | xargs -n 1 -P 4 bash -c $' 

MAP=$1
GDAL_CACHEMAX=2000
if [ $MAP = "elv"   ]  ; then ND=-9999 ; fi 
if [ $MAP = "are"   ]  ; then ND=-9999 ; fi 
if [ $MAP = "upa"   ]  ; then ND=-9999 ; fi 
if [ $MAP = "msk"   ]  ; then ND=0 ; fi 
if [ $MAP = "dep"   ]  ; then ND=0 ; fi 

### without displacement 
gdalbuildvrt -overwrite  -srcnodata  $ND -vrtnodata  $ND  $HYDRO/$MAP/all_tif.vrt   $HYDRO/$MAP/{s,n}??{w,e}???_$MAP.tif
rm  -f   $HYDRO/$MAP/all_tif_shp.* 
gdaltindex $HYDRO/$MAP/all_tif_shp.shp  $HYDRO/$MAP/{s,n}??{w,e}???_$MAP.tif

#### with displacement 
gdalbuildvrt -overwrite  -srcnodata $ND -vrtnodata $ND $HYDRO/$MAP/all_tif_dis.vrt $(ls $HYDRO/$MAP/{s,n}??{w,e}???_$MAP.tif | grep -v n65w180 | grep -v n65w175 | grep -v n65w170 | grep -v n60w180 | grep -v n60w175 | grep -v n70w180)  $(ls $HYDRO/$MAP/{n65w180,n65w175,n65w170,n60w180,n60w175,n70w180}_${MAP}_{dis,msk}.tif 2>/dev/null  )

rm  -f   $HYDRO/$MAP/all_tif_dis_shp.*
gdaltindex $HYDRO/$MAP/all_tif_dis_shp.shp  $(ls $HYDRO/$MAP/{s,n}??{w,e}???_$MAP.tif | grep -v n65w180 | grep -v n65w175 | grep -v n65w170 | grep -v n60w180 | grep -v n60w175 | grep -v n70w180)  $(ls $HYDRO/$MAP/{n65w180,n65w175,n65w170,n60w180,n60w175,n70w180}_${MAP}_{dis,msk}.tif 2>/dev/null ) 

' _

exit 

