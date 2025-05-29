#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00    
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc20_extract_grace.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc20_extract_grace.sh.%A_%a.err
#SBATCH --job-name=sc20_extract_grace.sh
#SBATCH --mem=30G
#SBATCH --array=4-744

####  200 array for the  1974 08
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc20_extract_grace_morevar.sh
#### --array=4-744       ### 744 line last date  2019 12 
#### 1825:1958-01-31    
#### 2532:2016-12-31

## grep CAN /vast/palmer/scratch/sbsc/ga254/stderr/sc20_extract_grace.sh.*_*.err   | awk -F "_" -F "." '{ gsub("_", " " ) ; print  $3 }'   | awk '{ printf("%i," , $2 ) }'
module load StdEnv
ulimit -c 0
source ~/bin/gdal3

find  /tmp/       -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

#  SLURM_ARRAY_TASK_ID=706
GSI_TS=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract 
RAM=/dev/shm
TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
SOILGRIDS2=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
GRWL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
GSW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW
HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
MERIT_DEM=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT

#  41233 x_y_ID.txt    41233 x_y.txt

### ID lon lat = 40165 lon lat after snapping so = 40165 IDraster 


if [ $SLURM_ARRAY_TASK_ID = 4  ] ; then

awk '{if(NR>1) print}' $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt > $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2.txt
awk '{if(NR>1) print}' $GSI_TS/headerFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord.txt >> $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2.txt
echo 999999 -99.999371 39.999434 999999 -11131879.06 4452716.62    >> $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2.txt
sort -k 1,1 $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2.txt > $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2s.txt
else 
sleep 60
fi

export DA_TE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print $1"_"$2 }' $GSI_TS/metadata/date.txt)
export YYYY=$(echo $DA_TE | awk -F "_"  '{ print $1 }')
export MM=$(echo $DA_TE | awk  -F "_"   '{ print $2 }')

echo          DA_TE $DA_TE YYYY $YYYY MM $MM
~/bin/echoerr DA_TE $DA_TE YYYY $YYYY MM $MM

export DA_TE1=$(awk -v n=1  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $GSI_TS/metadata/date.txt)
export YYYY1=$(echo $DA_TE1  | awk -F "_"  '{ print $1 }')
export MM1=$(echo $DA_TE1    | awk -F "_"  '{ print $2 }')

export DA_TE2=$(awk -v n=2  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $GSI_TS/metadata/date.txt)
export YYYY2=$(echo $DA_TE2  | awk -F "_"  '{ print $1 }')
export MM2=$(echo $DA_TE2    | awk -F "_"  '{ print $2 }')

export DA_TE3=$(awk -v n=3  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $GSI_TS/metadata/date.txt)
export YYYY3=$(echo $DA_TE3  | awk -F "_"  '{ print $1 }')
export MM3=$(echo $DA_TE3    | awk -F "_"  '{ print $2 }')

# $13 MEAN ### run only the first time and save the file . I do not use the lon lat from the ID_lonlat_date_Qquantiles.txt bc they are not snap
grep " ${YYYY} ${MM} " $EXTRACT/../quantiles_swap/ID_lonlat_date_Qquantiles.txt | awk '{print $1,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}' | sort -k 1,1  > $EXTRACT/stationID_value_${DA_TE}.txt

# if [ ${DA_TE} = 1974_08 ] ; then
# echo 99999 0.9 9 9 99 99 999 999 9999 9999 99999 99999 >> $EXTRACT/stationID_value_${DA_TE}.txt
# sort $EXTRACT/stationID_value_${DA_TE}.txt > /tmp/stationID_value_${DA_TE}.txt
# mv /tmp/stationID_value_${DA_TE}.txt $EXTRACT/stationID_value_${DA_TE}.txt
# fi

cp $EXTRACT/stationID_value_${DA_TE}.txt $RAM/

echo "ID lon lat IDraster Xcoord Ycoord YYYY MM QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX" > $RAM/stationID_x_y_value_${DA_TE}.txt
join -1 1 -2 1 <(sort -k 1,1 $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2s.txt) <(sort -k 1,1 $RAM/stationID_value_${DA_TE}.txt) | awk -v MM=$MM -v YYYY=$YYYY '{print $1,$2,$3,$4,$5,$6,YYYY,MM,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17}'  >> $RAM/stationID_x_y_value_${DA_TE}.txt

awk -v MM=$MM -v YYYY=$YYYY '{if($1>900000) print $1,$2,$3,$4,$5,$6,YYYY,MM,0,0,0,0,0,0,0,0,0,0,0}' $GSI_TS/snapFlow_txt/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2s.txt   >> $RAM/stationID_x_y_value_${DA_TE}.txt  
awk '{if(NR>1) print $2,$3 }'  $RAM/stationID_x_y_value_${DA_TE}.txt  > $RAM/x_y_${DA_TE}.txt

cp $RAM/stationID_x_y_value_${DA_TE}.txt $EXTRACT

echo gdallocationinfo $RAM/stationID_x_y_value_${DA_TE}.txt 

echo gdallocationinfo a tmin 4 col 
echo "ppt0 ppt1 ppt2 ppt3"  > $RAM/predictors_values_a_${DA_TE}.txt  
time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt      < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt   < $RAM/x_y_${DA_TE}.txt )   >> $RAM/predictors_values_a_${DA_TE}.txt  

sleep 10 
echo gdallocationinfo b tmin 4 col 

echo "tmin0 tmin1 tmin2 tmin3"  > $RAM/predictors_values_b_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_b_${DA_TE}.txt

sleep 10 
echo gdallocationinfo c tmax 4 col  

echo "tmax0 tmax1 tmax2 tmax3"  > $RAM/predictors_values_c_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_c_${DA_TE}.txt

sleep 10
echo gdallocationinfo d swe 4 col

echo "swe0 swe1 swe2 swe3"  > $RAM/predictors_values_d_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt )   >> $RAM/predictors_values_d_${DA_TE}.txt

sleep 10
echo gdallocationinfo f soil 6 col

echo "soil0 soil1 soil2 soil3"  > $RAM/predictors_values_f_${DA_TE}.txt  
time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt )   >> $RAM/predictors_values_f_${DA_TE}.txt

sleep 10 
echo gdallocationinfo g   SOILGRIDS 2 col 

echo "SNDPPT SLTPPT CLYPPT AWCtS WWP"       >  $RAM/predictors_values_g_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/SNDPPT_acc/SNDPPT.vrt      < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/SLTPPT_acc/SLTPPT.vrt      < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/CLYPPT_acc/CLYPPT.vrt      < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/AWCtS_acc/AWCtS.vrt        < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/WWP_acc/WWP.vrt            < $RAM/x_y_${DA_TE}.txt )   >> $RAM/predictors_values_g_${DA_TE}.txt

sleep 10 
echo "sand silt clay"  >  $RAM/predictors_values_h_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS2/sand/sand_acc/sand_0-200cm.vrt   < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS2/silt/silt_acc/silt_0-200cm.vrt   < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS2/clay/clay_acc/clay_0-200cm.vrt   < $RAM/x_y_${DA_TE}.txt )   >> $RAM/predictors_values_h_${DA_TE}.txt

sleep 10
echo gdallocationinfo i GRWL 5 col

echo "GRWLw GRWLr GRWLl GRWLd GRWLc" > $RAM/predictors_values_i_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_water_acc/GRWL_water.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_river_acc/GRWL_river.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_lake_acc/GRWL_lake.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_delta_acc/GRWL_delta.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_canal_acc/GRWL_canal.vrt              < $RAM/x_y_${DA_TE}.txt )      >> $RAM/predictors_values_i_${DA_TE}.txt

sleep 10
echo gdallocationinfo l GSW 5 col

echo "GSWs GSWr GSWo GSWe"   > $RAM/predictors_values_l_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $GSW/seasonality_acc/seasonality.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/recurrence_acc/recurrence.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/occurrence_acc/occurrence.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/extent_acc/extent.vrt                        < $RAM/x_y_${DA_TE}.txt )    >> $RAM/predictors_values_l_${DA_TE}.txt

##### hydrography

echo gdallocationinfo x  hydrography 17  col

touch $RAM/predictors_values_x_${DA_TE}.txt 
time for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt     -e accumulation.vrt  -e cti.vrt -e spi.vrt -e sti.vrt -e stream_diff_dw_near -e stream_dist_proximity -e stream_dist_dw_near   )  ; do 
gdallocationinfo -valonly -geoloc $vrt   < $RAM/x_y_${DA_TE}.txt > $RAM/predictors_values_xx_${DA_TE}.txt  
paste -d " "  $RAM/predictors_values_x_${DA_TE}.txt  $RAM/predictors_values_xx_${DA_TE}.txt > $RAM/predictors_values_xxx_${DA_TE}.txt   
mv $RAM/predictors_values_xxx_${DA_TE}.txt  $RAM/predictors_values_x_${DA_TE}.txt   
done 

for file in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt  -e accumulation.vrt  -e cti.vrt -e spi.vrt -e sti.vrt -e stream_diff_dw_near -e stream_dist_proximity -e stream_dist_dw_near  )  ; do  
echo -n $(basename $file .vrt)" "  
done > $RAM/predictors_values_l_${DA_TE}.txt 
echo "" >> $RAM/predictors_values_l_${DA_TE}.txt 

cat  $RAM/predictors_values_x_${DA_TE}.txt >>  $RAM/predictors_values_l_${DA_TE}.txt
rm   $RAM/predictors_values_xx_${DA_TE}.txt      $RAM/predictors_values_x_${DA_TE}.txt

###### positive accumulation. 
echo "accumulation"   >   $RAM/predictors_values_t_${DA_TE}.txt
gdallocationinfo -valonly -geoloc $HYDRO/flow_tiles/all_tif_pos_dis.vrt  < $RAM/x_y_${DA_TE}.txt >> $RAM/predictors_values_t_${DA_TE}.txt

echo "cti spi sti" >   $RAM/predictors_values_u_${DA_TE}.txt
time paste -d " " \
<( gdallocationinfo -valonly -geoloc $HYDRO/CompUnit_stream_indices_tiles20d/all_tif_cti2_dis.vrt      < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $HYDRO/CompUnit_stream_indices_tiles20d/all_tif_spi2_dis.vrt      < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $HYDRO/CompUnit_stream_indices_tiles20d/all_tif_sti2_dis.vrt      < $RAM/x_y_${DA_TE}.txt )    >> $RAM/predictors_values_u_${DA_TE}.txt

###### elevation 

echo gdallocationinfo m elevation  1  col

echo "elev"   >   $RAM/predictors_values_m_${DA_TE}.txt
gdallocationinfo -valonly -geoloc $MERIT_DEM/elv/all_tif_dis.vrt  < $RAM/x_y_${DA_TE}.txt >> $RAM/predictors_values_m_${DA_TE}.txt

#### geomorpho
echo gdallocationinfo x  geomorpho90m 22  col

touch $RAM/predictors_values_z_${DA_TE}.txt
for vrt in $(ls $MERIT/geomorphometry_90m_wgs84/*/all_*_90M_dis.vrt | grep -v -e all_aspect_90M_dis.vrt  -e all_cti_90M_dis.vrt -e all_spi_90M_dis.vrt -e all_geom_90M_dis.vrt )  ; do
gdallocationinfo -valonly -geoloc $vrt   < $RAM/x_y_${DA_TE}.txt > $RAM/predictors_values_zz_${DA_TE}.txt
paste -d " "  $RAM/predictors_values_z_${DA_TE}.txt  $RAM/predictors_values_zz_${DA_TE}.txt > $RAM/predictors_values_zzz_${DA_TE}.txt
mv $RAM/predictors_values_zzz_${DA_TE}.txt  $RAM/predictors_values_z_${DA_TE}.txt
done

for file in $(ls $MERIT/geomorphometry_90m_wgs84/*/all_*_90M_dis.vrt | grep -v -e all_aspect_90M_dis.vrt -e all_cti_90M_dis.vrt -e all_spi_90M_dis.vrt -e all_geom_90M_dis.vrt   ) ; do  
filename=$(basename $file _90M_dis.vrt); echo -n ${filename:4}" " 
done > $RAM/predictors_values_n_${DA_TE}.txt
echo "" >> $RAM/predictors_values_n_${DA_TE}.txt 

cat  $RAM/predictors_values_z_${DA_TE}.txt >>  $RAM/predictors_values_n_${DA_TE}.txt
rm   $RAM/predictors_values_zz_${DA_TE}.txt      $RAM/predictors_values_z_${DA_TE}.txt

echo marege all 

#### head -2 $RAM/stationID_x_y_value_${DA_TE}.txt $RAM/predictors_values_?_${DA_TE}.txt

paste -d " " $RAM/stationID_x_y_value_${DA_TE}.txt $RAM/predictors_values_?_${DA_TE}.txt | sed 's/  / /g' > $EXTRACT/stationID_x_y_value_predictors_${DA_TE}.txt

rm -f $RAM/*_${DA_TE}.txt

exit 

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then 
cd $EXTRACT/ 
sleep 3000
## copy the headear 
head -1 $EXTRACT/stationID_x_y_value_predictors_1958_04.txt   > $EXTRACT/stationID_x_y_valueALL_predictors.txt

### 72300000.000 & 61202000.000  is for QMAX value   in total 2 lines             | awk '{ if (NF==93) print }'
### -9999999  soil  layers
### -2147483648       ###  65535 there value for this but prob is 
### remove space in the midle ## remove space in the end  
grep -h -v -e ID -e "\-2147483648 " -e "\-9999999 " -e "72300000.000" -e "61202000.000" $EXTRACT/stationID_x_y_value_predictors_????_??.txt | awk '{ if (NF==105) print }' | sed  's/  / /g'  | sed 's/ *$//'   >>  $EXTRACT/stationID_x_y_valueALL_predictors.txt
fi 


exit








