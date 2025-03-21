#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc20_extract_grace.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc20_extract_grace.sh.%A_%a.err
#SBATCH --job-name=sc20_extract_grace.sh
#SBATCH --mem=28G
#SBATCH --array=335

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc20_extract_grace.sh
#### --array=6-708
#### 1825:1958-01-31    
#### 2532:2016-12-31

## grep CAN /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_extract_grace.sh.*.err  | awk -F "_" -F "." '{ gsub("_", " " ) ; print  $3 }'   | awk '{ printf("%i," , $2 ) }'

ulimit -c 0
source ~/bin/gdal3

find  /tmp/       -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

### create data.txt only once 
##### grep "^[0-9][0-9][0-9][0-9]"-  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly/* | awk  '{gsub("," , " " ) ;  gsub(":" , " " ) ;   { print $2 }  }' | sort | uniq -c  > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/metadata/date.txt

#  SLURM_ARRAY_TASK_ID=706
SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
RAM=/dev/shm
TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
GRWL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
GSW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW
HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT

if [ $SLURM_ARRAY_TASK_ID = 6  ] ; then 
awk '{  if ($4!=2) print $3 , $1 , $2 }' $SNAP/snapFlow/x_y_snapFlowFinal_*.txt | sort -k 1,1 >  $SNAP/snapFlow/ID_x_y_snapFlowFinal.txt
else 
sleep 30
fi

DATE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824) print $2 }' $SNAP/metadata/date.txt)
DA_TE=$(echo $DATE | awk -F - '{ print $1"_"$2 }')
YYYY=$(echo $DATE | awk -F - '{ print $1 }')
MM=$(echo $DATE | awk -F - '{ print $2 }')

echo $DATE 

DATE1=$(awk -v n=1  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE1=$(echo $DATE1 | awk -F - '{ print $1"_"$2 }')
YYYY1=$(echo $DATE1  | awk -F - '{ print $1 }')
MM1=$(echo $DATE1    | awk -F - '{ print $2 }')

DATE2=$(awk -v n=2  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE2=$(echo $DATE2 | awk -F - '{ print $1"_"$2 }')
YYYY2=$(echo $DATE2  | awk -F - '{ print $1 }')
MM2=$(echo $DATE2    | awk -F - '{ print $2 }')

DATE3=$(awk -v n=3  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE3=$(echo $DATE3 | awk -F - '{ print $1"_"$2 }')
YYYY3=$(echo $DATE3  | awk -F - '{ print $1 }')
MM3=$(echo $DATE3    | awk -F - '{ print $2 }')

DATE4=$(awk -v n=4  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE4=$(echo $DATE4 | awk -F - '{ print $1"_"$2 }')
YYYY4=$(echo $DATE4  | awk -F - '{ print $1 }')
MM4=$(echo $DATE4    | awk -F - '{ print $2 }')

DATE5=$(awk -v n=5  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE5=$(echo $DATE5 | awk -F - '{ print $1"_"$2 }')
YYYY5=$(echo $DATE5  | awk -F - '{ print $1 }')
MM5=$(echo $DATE5    | awk -F - '{ print $2 }')


# $13 MEAN ### run only the first time and save the file 
grep ^${YYYY}-${MM} /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly/*.mon | awk '{gsub("/"," "); gsub(":"," "); gsub(","," "); gsub(".mon"," "); if($13!="NA") {print $11, $13 , $14 , $15 , $16 , $17 , $18 , $19 , $20 }}' | sort -k 1,1  > $EXTRACT/stationID_value_${DA_TE}.txt

cp $EXTRACT/stationID_value_${DA_TE}.txt $RAM/

# "date", "MEAN","SD", "CV", "IQR", "MIN", "MAX", "MIN7", "MAX7",

echo "ID date lon lat MEAN SD CV IQR MIN MAX MIN7 MAX7" > $RAM/stationID_x_y_value_${DA_TE}.txt
join -1 1 -2 1 $SNAP/snapFlow/ID_x_y_snapFlowFinal.txt $RAM/stationID_value_${DA_TE}.txt | awk -v DATE=$DATE '{print $1,DATE ,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'  >> $RAM/stationID_x_y_value_${DA_TE}.txt
awk '{if(NR>1) print $3, $4   }'  $RAM/stationID_x_y_value_${DA_TE}.txt  > $RAM/x_y_${DA_TE}.txt

cp $RAM/stationID_x_y_value_${DA_TE}.txt $EXTRACT

paste -d " " $EXTRACT/stationID_x_y_value_${DA_TE}.txt <( awk '{ print $1="", $2="",$3="", $4="",$5="",$0}' $EXTRACT/stationID_x_y_value_predictors_${DA_TE}.txt ) | sed 's/  */ /g' > $EXTRACT/stationID_x_y_valueALL_predictors_${DA_TE}.txt   

exit 

echo gdallocationinfo $RAM/stationID_x_y_value_${DA_TE}.txt 

echo "ppt0 ppt1 ppt2 ppt3 ppt4 ppt5"  > $RAM/predictors_values_a_${DA_TE}.txt  
time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt      < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY4/ppt_${YYYY4}_$MM4.vrt   < $RAM/x_y_${DA_TE}.txt )  \
<( gdallocationinfo -valonly -geoloc $TERRA/ppt_acc/$YYYY5/ppt_${YYYY5}_$MM5.vrt   < $RAM/x_y_${DA_TE}.txt ) >> $RAM/predictors_values_a_${DA_TE}.txt  

sleep 10 
echo gdallocationinfo b tmin 6 col 

echo "tmin0 tmin1 tmin2 tmin3 tmin4 tmin5"  > $RAM/predictors_values_b_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY4/tmin_${YYYY4}_$MM4.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmin_acc/$YYYY5/tmin_${YYYY5}_$MM5.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_b_${DA_TE}.txt

sleep 10 
echo gdallocationinfo c tmax 6 col  

echo "tmax0 tmax1 tmax2 tmax3 tmax4 tmax5"  > $RAM/predictors_values_c_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY4/tmax_${YYYY4}_$MM4.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/tmax_acc/$YYYY5/tmax_${YYYY5}_$MM5.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_c_${DA_TE}.txt

sleep 10
echo gdallocationinfo d swe 6 col

echo "swe0 swe1 swe2 swe3 swe4 swe5"  > $RAM/predictors_values_d_${DA_TE}.txt  

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY4/swe_${YYYY4}_$MM4.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/swe_acc/$YYYY5/swe_${YYYY5}_$MM5.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_d_${DA_TE}.txt

sleep 10
echo gdallocationinfo f soil 6 col

echo "soil0 soil1 soil2 soil3 soil4 soil5"  > $RAM/predictors_values_f_${DA_TE}.txt  
time paste -d " " \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt    < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY4/soil_${YYYY4}_$MM4.vrt < $RAM/x_y_${DA_TE}.txt ) \
<( gdallocationinfo -valonly -geoloc $TERRA/soil_acc/$YYYY5/soil_${YYYY5}_$MM5.vrt < $RAM/x_y_${DA_TE}.txt )  >> $RAM/predictors_values_f_${DA_TE}.txt

sleep 10 
echo gdallocationinfo g   SOILGRIDS 5 col 

echo "AWCtS CLYPPT SLTPPT SNDPPT WWP"  >  $RAM/predictors_values_g_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt            < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt            < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt            < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $SOILGRIDS/WWP_acc/WWP_WeigAver.vrt                  < $RAM/x_y_${DA_TE}.txt )    >> $RAM/predictors_values_g_${DA_TE}.txt


sleep 10
echo gdallocationinfo h GRWL 5 col

echo "GRWLw GRWLr GRWLl GRWLd GRWLc" > $RAM/predictors_values_h_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_water_acc/GRWL_water.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_river_acc/GRWL_river.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_lake_acc/GRWL_lake.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_delta_acc/GRWL_delta.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GRWL/GRWL_canal_acc/GRWL_canal.vrt              < $RAM/x_y_${DA_TE}.txt )      >> $RAM/predictors_values_h_${DA_TE}.txt

sleep 10
echo gdallocationinfo i GSW 5 col

echo "GSWs GSWr GSWo GSWe"   > $RAM/predictors_values_i_${DA_TE}.txt

time paste -d " " \
<( gdallocationinfo -valonly -geoloc $GSW/seasonality_acc/seasonality.vrt              < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/recurrence_acc/recurrence.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/occurrence_acc/occurrence.vrt                < $RAM/x_y_${DA_TE}.txt )   \
<( gdallocationinfo -valonly -geoloc $GSW/extent_acc/extent.vrt                        < $RAM/x_y_${DA_TE}.txt )    >> $RAM/predictors_values_i_${DA_TE}.txt

##### hydrography

touch $RAM/predictors_values_x_${DA_TE}.txt 
time for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt  -e order_vect.vrt  -e channel -e order     )  ; do 
gdallocationinfo -valonly -geoloc $vrt   < $RAM/x_y_${DA_TE}.txt > $RAM/predictors_values_xx_${DA_TE}.txt  
paste -d " "  $RAM/predictors_values_x_${DA_TE}.txt  $RAM/predictors_values_xx_${DA_TE}.txt > $RAM/predictors_values_xxx_${DA_TE}.txt   
mv $RAM/predictors_values_xxx_${DA_TE}.txt  $RAM/predictors_values_x_${DA_TE}.txt   
done 

for file in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt )  ; do  
echo -n $(basename $file .vrt)" "  
done > $RAM/predictors_values_l_${DA_TE}.txt 
echo "" >> $RAM/predictors_values_l_${DA_TE}.txt 

cat  $RAM/predictors_values_x_${DA_TE}.txt >>  $RAM/predictors_values_l_${DA_TE}.txt
rm   $RAM/predictors_values_xx_${DA_TE}.txt      $RAM/predictors_values_x_${DA_TE}.txt

###### elevation 

echo "ELEV"   >   $RAM/predictors_values_m_${DA_TE}.txt
gdallocationinfo -valonly -geoloc $MERIT/input_tif/all_tif.vrt  < $RAM/x_y_${DA_TE}.txt >> $RAM/predictors_values_m_${DA_TE}.txt

#### geomorpho

touch $RAM/predictors_values_z_${DA_TE}.txt
time for vrt in $( ls   $MERIT/geomorphometry_90m_wgs84/*/all_*_90M.vrt | grep -v -e all_aspect_90M.vrt  -e all_cti_90M.vrt -e all_spi_90M.vrt  )  ; do
gdallocationinfo -valonly -geoloc $vrt   < $RAM/x_y_${DA_TE}.txt > $RAM/predictors_values_zz_${DA_TE}.txt
paste -d " "  $RAM/predictors_values_z_${DA_TE}.txt  $RAM/predictors_values_zz_${DA_TE}.txt > $RAM/predictors_values_zzz_${DA_TE}.txt
mv $RAM/predictors_values_zzz_${DA_TE}.txt  $RAM/predictors_values_z_${DA_TE}.txt
done

for file in $( ls  $MERIT/geomorphometry_90m_wgs84/*/all_*_90M.vrt | grep -v -e all_aspect_90M.vrt -e all_cti_90M.vrt -e all_spi_90M.vrt   ) ; do  
filename=$(basename $file _90M.vrt); echo -n ${filename:4}" " 
done > $RAM/predictors_values_n_${DA_TE}.txt
echo "" >> $RAM/predictors_values_n_${DA_TE}.txt 

cat  $RAM/predictors_values_z_${DA_TE}.txt >>  $RAM/predictors_values_n_${DA_TE}.txt
rm   $RAM/predictors_values_zz_${DA_TE}.txt      $RAM/predictors_values_z_${DA_TE}.txt

echo marege all 

paste -d " " $RAM/stationID_x_y_value_${DA_TE}.txt $RAM/predictors_values_?_${DA_TE}.txt | sed  's/  / /g' > $EXTRACT/stationID_x_y_value_predictors_${DA_TE}.txt

rm -f $RAM/*_${DA_TE}.txt

exit 

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then 
cd $EXTRACT/ 
sleep 3000
echo "ID date lon lat MEAN SD CV IQR MIN MAX MIN7 MAX7 ppt0 ppt1 ppt2 ppt3 ppt4 ppt5 tmin0 tmin1 tmin2 tmin3 tmin4 tmin5 tmax0 tmax1 tmax2 tmax3 tmax4 tmax5 swe0 swe1 swe2 swe3 swe4 swe5 soil0 soil1 soil2 soil3 soil4 soil5 AWCtS CLYPPT SLTPPT SNDPPT WWP GRWLw GRWLr GRWLl GRWLd GRWLc GSWs GSWr GSWo GSWe cti spi sti channel_curv_cel channel_dist_dw_seg channel_dist_up_cel channel_dist_up_seg channel_elv_dw_cel channel_elv_dw_seg channel_elv_up_cel channel_elv_up_seg channel_grad_dw_seg channel_grad_up_cel channel_grad_up_seg outlet_diff_dw_scatch outlet_dist_dw_scatch stream_diff_dw_near stream_diff_up_farth stream_diff_up_near stream_dist_dw_near stream_dist_proximity stream_dist_up_farth stream_dist_up_near order_hack order_horton order_shreve order_strahler order_topo slope_curv_max_dw_cel slope_curv_min_dw_cel slope_elv_dw_cel slope_grad_dw_cel accumulation ELEV aspect-cosine aspect-sine convergence dev-magnitude dev-scale dx dxx dxy dy dyy eastness elev-stdev geom northness pcurv rough-magnitude roughness rough-scale slope tcurv tpi tri vrm"  > $EXTRACT/stationID_x_y_valueALL_predictors.txt
                                                                             ### remove space in the midle ## remove space in the end
grep -h -v ID  $EXTRACT/stationID_x_y_valueALL_predictors_????_??.txt | grep -v "\-9999999" | sed  's/  / /g'  | sed 's/ *$//'  >>  $EXTRACT/stationID_x_y_valueALL_predictors.txt
fi


exit 

rm  stationID_x_y_value_predictors_2016_12.txt   just the header check 



