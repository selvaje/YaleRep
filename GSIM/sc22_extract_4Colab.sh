

####  
### seq can go from 1 to 708 . it identify the date inside the GSIM/metadata/date.txt
seq 16 18 | xargs -n 1 -P 2 bash -c $'

ID=$1

GDRIVE=/gdrive/MyDrive/dataproces

DATE=$(awk -v ID=$ID \'{ if(NR==ID+1824) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE=$(echo $DATE | awk -F - \'{ print $1"_"$2 }\')
YYYY=$(echo $DATE | awk -F - \'{ print $1 }\')
MM=$(echo $DATE | awk -F - \'{ print $2 }\')

echo $DATE 

DATE1=$(awk -v n=1  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE1=$(echo $DATE1 | awk -F - \'{ print $1"_"$2 }\')
YYYY1=$(echo $DATE1  | awk -F - \'{ print $1 }\')
MM1=$(echo $DATE1    | awk -F - \'{ print $2 }\')

DATE2=$(awk -v n=2  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE2=$(echo $DATE2 | awk -F - \'{ print $1"_"$2 }\')
YYYY2=$(echo $DATE2  | awk -F - \'{ print $1 }\')
MM2=$(echo $DATE2    | awk -F - \'{ print $2 }\')

DATE3=$(awk -v n=3  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE3=$(echo $DATE3 | awk -F - \'{ print $1"_"$2 }\')
YYYY3=$(echo $DATE3  | awk -F - \'{ print $1 }\')
MM3=$(echo $DATE3    | awk -F - \'{ print $2 }\')

DATE4=$(awk -v n=4  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE4=$(echo $DATE4 | awk -F - \'{ print $1"_"$2 }\')
YYYY4=$(echo $DATE4  | awk -F - \'{ print $1 }\')
MM4=$(echo $DATE4    | awk -F - \'{ print $2 }\')

DATE5=$(awk -v n=5  -v ID=$ID \'{ if(NR==ID+1824-n) print $2 }\' /gdrive/MyDrive/dataproces/GSIM/metadata/date.txt)
DA_TE5=$(echo $DATE5 | awk -F - \'{ print $1"_"$2 }\')
YYYY5=$(echo $DATE5  | awk -F - \'{ print $1 }\')
MM5=$(echo $DATE5    | awk -F - \'{ print $2 }\')

echo $DA_TE  $YYYY $MM  $DA_TE1 $YYYY1 $MM1 $DA_TE2 $YYYY2 $MM2 $DA_TE3 $YYYY3 $MM3 $DA_TE4 $YYYY4 $MM4 $DA_TE5 $YYYY5 $MM5

paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt      < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt   < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt   < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt   < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY4/ppt_${YYYY4}_$MM4.vrt   < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/ppt_acc/$YYYY5/ppt_${YYYY5}_$MM5.vrt   < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  > $GDRIVE/GSIM/gdallocationinfo/predictors_values_a_${DA_TE}.txt
paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt    < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY4/tmin_${YYYY4}_$MM4.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmin_acc/$YYYY5/tmin_${YYYY5}_$MM5.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) > $GDRIVE/GSIM/gdallocationinfo/predictors_values_b_${DA_TE}.txt
paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt    < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY4/tmax_${YYYY4}_$MM4.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/TERRA/tmax_acc/$YYYY5/tmax_${YYYY5}_$MM5.vrt < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) > $GDRIVE/GSIM/gdallocationinfo/predictors_values_c_${DA_TE}.txt
paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt       < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt     < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt     < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt     < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/SOILGRIDS/WWP_acc/WWP_WeigAver.vrt           < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  > $GDRIVE/GSIM/gdallocationinfo/predictors_values_d_${DA_TE}.txt

paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRAND/${YYYY}_acc/GRanD_${YYYY}.vrt          < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_canal_acc/GRWL_canal.vrt           < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_delta_acc/GRWL_delta.vrt           < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_lake_acc/GRWL_lake.vrt             < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_river_acc/GRWL_river.vrt           < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GRWL/GRWL_water_acc/GRWL_water.vrt           < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  > $GDRIVE/GSIM/gdallocationinfo/predictors_values_e_${DA_TE}.txt

paste -d " " \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/extent_acc/extent.vrt                    < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/occurrence_acc/occurrence.vrt            < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/recurrence_acc/recurrence.vrt            < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $GDRIVE/GSW/seasonality_acc/seasonality.vrt          < $GDRIVE/GSIM/x_y_date/x_y_${DA_TE}.txt )  > $GDRIVE/GSIM/gdallocationinfo/predictors_values_f_${DA_TE}.txt

paste -d " " $GDRIVE/GSIM/x_y_mean/stationID_x_y_value_${DA_TE}.txt $GDRIVE/GSIM/gdallocationinfo/predictors_values_{a,b,c,d,e,f}_${DA_TE}.txt > $GDRIVE/GSIM/gdallocationinfo/stationID_x_y_value_predictors_${DA_TE}.txt 
rm $GDRIVE/GSIM/gdallocationinfo/predictors_values_*_${DA_TE}.txt 

' _ 
