#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc40_modeling_python_vrt_prediction_nparray.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc40_modeling_python_vrt_prediction_nparray.sh.%A_%a.err
#SBATCH --job-name=sc40_modeling_python_vrt_prediction_nparray.sh
#SBATCH --array=74626-75000
#SBATCH --mem=400G

##### #SBATCH  --array=4-744 
##### #SBATCH --array=1,116   ##### 20d       h18v04 59 for testing
##### #SBATCH --array=1,544   ##### 10d       h19v04 59 for testing  north of italy

###### grep  -n "1974 08" /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date_tile.txt | grep h08v05  --array=74691   missisipi
#####  grep  -n "1974 08" /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date_tile.txt                --array=74626-75000 full globe
###### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc40_modeling_python_vrt_prediction_nparray.sh

###  for n in $(seq 1 780  ) ; do
###    paste -d " " <(awk -v n=$n '{if (NR==n) for (i=1; i<=375; i++) print $1, $2}' $META/date.txt) <(awk '{print $1}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_10d_flow90m_land_dis_noheader.txt )
###  done  > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata/date_tile.txt  

module load StdEnv
source ~/bin/gdal3

export INTILE=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/input_tile
export INTILES=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/input_tile
export QFLOW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/qflow
export QFLOWS=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow
export META=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/metadata
export EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
export RAM=/dev/shm
export TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
export SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
export ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
export GRWL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
export GSW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW
export HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT

export TILE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print $3 }'       $META/date_tile.txt)
export DA_TE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print $1"_"$2 }' $META/date_tile.txt)
export YYYY=$(echo $DA_TE | awk -F "_"  '{ print $1 }')
export MM=$(echo $DA_TE | awk  -F "_"   '{ print $2 }')

echo           ${YYYY}_${MM}_${TILE}
~/bin/echoerr  ${YYYY}_${MM}_${TILE}

DATE_POS=$(grep -n  "$YYYY $MM"  $META/date.txt | cut -d ":" -f1)

export DA_TE1=$(awk -v n=1  -v DATE_POS=$DATE_POS '{ if(NR==DATE_POS - n) print $1"_"$2 }' $META/date.txt)
export YYYY1=$(echo $DA_TE1  | awk -F "_"  '{ print $1 }')
export MM1=$(echo $DA_TE1    | awk -F "_"  '{ print $2 }')

export DA_TE2=$(awk -v n=2  -v DATE_POS=$DATE_POS '{ if(NR==DATE_POS - n) print $1"_"$2 }' $META/date.txt)
export YYYY2=$(echo $DA_TE2  | awk -F "_"  '{ print $1 }')
export MM2=$(echo $DA_TE2    | awk -F "_"  '{ print $2 }')

export DA_TE3=$(awk -v n=3  -v DATE_POS=$DATE_POS '{ if(NR==DATE_POS - n) print $1"_"$2 }' $META/date.txt)
export YYYY3=$(echo $DA_TE3  | awk -F "_"  '{ print $1 }')
export MM3=$(echo $DA_TE3    | awk -F "_"  '{ print $2 }')

rm -f $INTILES/${YYYY}_${MM}_${TILE}.txt  $INTILES/${YYYY}_${MM}_${TILE}.vrt  $INTILES/${YYYY}_${MM}_${TILE}_s.txt 
######## PPT TERRA

### use the colname of selected variables to build a txt $INTILES/${YYYY}_${MM}_${TILE}.txt  path-tif and tif name 
IMP_FILE=stationID_x_y_valueALL_predictors_XcolnamesN300_4leaf_4split_60sample_2RF.txt

# the pos variable identify the position in the column name for a later sorting

for var1 in ppt0 ppt1 ppt2 ppt3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = ppt0  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt    ) ppt0.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt1  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt ) ppt1.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt2  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt ) ppt2.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt3  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt ) ppt3.tif | sed '/^$/d'  ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

######## TMIM TERRA

for var1 in tmin0 tmin1 tmin2 tmin3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmin0  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt ) tmin0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = tmin1  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt ) tmin1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmin2  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt ) tmin2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmin3  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt ) tmin3.tif | sed '/^$/d'        ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

######## TMAX TERRA

for var1 in tmax0 tmax1 tmax2 tmax3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmax0  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt ) tmax0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = tmax1  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt ) tmax1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmax2  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt ) tmax2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmax3  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt ) tmax3.tif | sed '/^$/d'        ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

######## SNOW TERRA   

for var1 in swe0 swe1 swe2 swe3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = swe0  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt ) swe0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = swe1  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt ) swe1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = swe2  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt ) swe2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = swe3  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt ) swe3.tif | sed '/^$/d'        ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

######## SOIL TERRA   

for var1 in soil0 soil1 soil2 soil3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = soil0  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt ) soil0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = soil1  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt ) soil1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = soil2  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt ) soil2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = soil3  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt ) soil3.tif | sed '/^$/d'        ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

######## SOILGRID

for var1 in AWCtS CLYPPT SLTPPT SNDPPT WWP ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = AWCtS   ] ; then echo $pos $(ls $SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt ) AWCtS.tif  | sed '/^$/d'          ; fi
    if [ "$var2" = CLYPPT  ] ; then echo $pos $(ls $SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt ) CLYPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = SLTPPT  ] ; then echo $pos $(ls $SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt ) SLTPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = SNDPPT  ] ; then echo $pos $(ls $SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt ) SNDPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = WWP     ] ; then echo $pos $(ls $SOILGRIDS/WWP_acc/WWP_WeigAver.vrt ) WWP.tif | sed '/^$/d'              ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt 

######## GRWL 

for var1 in GRWLw GRWLr GRWLl GRWLd GRWLc  ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GRWLw  ] ; then echo $pos $(ls $GRWL/GRWL_water_acc/GRWL_water.vrt ) GRWLw.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLr  ] ; then echo $pos $(ls $GRWL/GRWL_river_acc/GRWL_river.vrt ) GRWLr.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLl  ] ; then echo $pos $(ls $GRWL/GRWL_lake_acc/GRWL_lake.vrt   ) GRWLl.tif | sed '/^$/d'        ; fi
    if [ "$var2" = GRWLd  ] ; then echo $pos $(ls $GRWL/GRWL_delta_acc/GRWL_delta.vrt ) GRWLd.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLc  ] ; then echo $pos $(ls $GRWL/GRWL_canal_acc/GRWL_canal.vrt ) GRWLc.tif | sed '/^$/d'      ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt 

#####  GSW

for var1 in GSWs GSWr GSWo GSWe ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GSWs  ] ; then echo $pos $(ls $GSW/seasonality_acc/seasonality.vrt ) GSWs.itf | sed '/^$/d' ; fi
    if [ "$var2" = GSWr  ] ; then echo $pos $(ls $GSW/recurrence_acc/recurrence.vrt ) GSWr.tif | sed '/^$/d'   ; fi
    if [ "$var2" = GSWo  ] ; then echo $pos $(ls $GSW/occurrence_acc/occurrence.vrt ) GSWo.tif | sed '/^$/d'   ; fi
    if [ "$var2" = GSWe  ] ; then echo $pos $(ls $GSW/extent_acc/extent.vrt ) GSWe.tif | sed '/^$/d'            ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt 

##### hydrography  #### the cti has negative values.

for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt -e order_vect.vrt  -e channel -e order -e accumulation  )  ; do 
name_imp=$(basename $vrt .vrt  )
name_tif=$(grep ${name_imp}  $EXTRACT/$IMP_FILE )
name_pos=$(grep -n ${name_imp}  $EXTRACT/$IMP_FILE | awk -F : '{print $1}'   )
if [[ !  -z  $name_tif   ]] ;  then
    echo $name_pos $( ls  $HYDRO/hydrography90m_v.1.0/*/${name_tif}_tiles20d/${name_tif}.vrt 2> /dev/null )  ${name_tif}.tif   | sed '/^$/d'
fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

##### positive accumulation

for var1 in accumulation ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }')
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}')
    if [ "$var2" = accumulation  ] ; then echo $pos $(ls $HYDRO/flow_tiles/all_tif_pos_dis.vrt )  accumulation.tif  ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

###### elevation 

for var1 in ELEV ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = ELEV  ] ; then echo $pos $(ls $MERIT/input_tif/all_tif.vrt) ELEV.tif ; fi
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

#### geomorpho 

for vrt in $( ls $MERIT/geomorphometry_90m_wgs84/*/all_*_90M_dis.vrt | grep -v -e all_aspect_90M_dis.vrt  -e all_cti_90M_dis.vrt -e all_spi_90M_dis.vrt  )  ; do
name_imp=$(basename $vrt _90M_dis.vrt | sed 's/all_//g' ) #  sed 's/-/_/g' 
name_tif=$(grep ${name_imp}$  $EXTRACT/$IMP_FILE ) #  sed 's/_/-/g' 
name_pos=$(grep -n ${name_imp}$  $EXTRACT/$IMP_FILE | awk -F : '{print $1}'   )
# echo ${name_imp} ${name_tif}
if [[ !  -z  $name_tif   ]] ;  then
    echo $name_pos $( ls  $MERIT/geomorphometry_90m_wgs84/${name_tif}/all_${name_tif}_90M_dis.vrt  2> /dev/null )  ${name_tif}.tif   ;
fi 
done >> $INTILES/${YYYY}_${MM}_${TILE}.txt

sort -k 1,1 -g $INTILES/${YYYY}_${MM}_${TILE}.txt |  awk '{print $2  }'     > $INTILES/${YYYY}_${MM}_${TILE}_s.txt

echoerr string ${YYYY} ${MM} ${TILE}  
echo string ${YYYY} ${MM} ${TILE}

gdalbuildvrt -overwrite -separate -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$TILE.tif) -input_file_list  $INTILES/${YYYY}_${MM}_${TILE}_s.txt   $INTILES/${YYYY}_${MM}_${TILE}.vrt

rm -r $INTILES/${DA_TE}_${TILE}
mkdir -p $INTILES/${DA_TE}_${TILE} 
cat $INTILES/${YYYY}_${MM}_${TILE}.txt  | xargs -n 3  -P 10 bash -c $' 
file=$2
fileout=$3
export GDAL_CACHEMAX=10000
##  add for testing  -srcwin 0 0 5000 5000
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$TILE.tif) $file $INTILES/${DA_TE}_${TILE}/$fileout 
' _

gdalbuildvrt -overwrite -separate -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$TILE.tif)   $INTILES/${YYYY}_${MM}_${TILE}/${YYYY}_${MM}.vrt    $(for file in $(cat $EXTRACT/$IMP_FILE) ; do  ls ${INTILES}/${YYYY}_${MM}_${TILE}/$file.tif  ; done)

#### predictor validation extracted table vs tif extracted
if [ $TILE = "h08v05" ] ; then 
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
grep -n 99999  stationID_x_y_valueALL_predictors_YTrainN300_4leaf_4split_60sample_2RF.txt
head -8663928  stationID_x_y_valueALL_predictors_XTrainN300_4leaf_4split_60sample_2RF.txt | tail -1   # predictors at 99999 location 

gdallocationinfo -valonly -geoloc   /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/input_tile/1974_08_h08v05/1974_08.vrt  -99.999371 39.999434 
paste -d " " \
      <( gdallocationinfo -valonly -geoloc   /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/input_tile/1974_08_h08v05/1974_08.vrt  -99.999371 39.999434) \
      <(head -8663928  stationID_x_y_valueALL_predictors_XTrainN300_4leaf_4split_60sample_2RF.txt    | tail -1 | awk '{for (i=1; i<=NF; i++) printf "%s\n", $i}'  ) \
      stationID_x_y_valueALL_predictors_XcolnamesN300_4leaf_4split_60sample_2RF.txt
fi

mkdir -p ${QFLOWS}/${YYYY}_${MM}

module purge
apptainer exec --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH",DA_TE=$DA_TE,TILE=$TILE,INTILE=$INTILE,YYYY=$YYYY,MM=$MM /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif bash -c "

python3 -c '
import os, sys  , glob
import pandas as pd
import numpy as np
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python311.zip\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/lib-dynload\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/site-packages\")
from numpy import savetxt
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor

import dill 
import pyjeo as pj

DA_TE=(os.environ[\"DA_TE\"])
TILE=(os.environ[\"TILE\"])
INTILE=(os.environ[\"INTILE\"])
INTILES=(os.environ[\"INTILES\"])
QFLOWS=(os.environ[\"QFLOWS\"])

DA_TE=(os.environ[\"DA_TE\"])
YYYY=(os.environ[\"YYYY\"])
MM=(os.environ[\"MM\"])

print(DA_TE)
print(TILE)
print(INTILE)
# load the column name to load the tif in the same order 
predictors = pd.read_csv(\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_XcolnamesN300_4leaf_4split_60sample_2RF.txt\", header=None)

# Extract the feature names from the predictors DataFrame
feature_names = predictors.iloc[:, 0].tolist()  # Assuming the first column contains the feature names

# Initialize list for stacking arrays
tif_arrays = []
tif_order = []

# Loop over all the rows (starting from the first one)

# opsit order 
# for index, row in predictors.iloc[::-1].iterrows():

# direct order 
for index, row in predictors.iterrows():
    tif_file = \" \".join(row.values.astype(str))
    file_path = rf\"{INTILES}/{YYYY}_{MM}_{TILE}/{tif_file}.tif\"
    print(file_path)
    # import the tif  diretly as float64

    tif_data = pj.Jim(file_path).np().astype(np.float64)

    # Append the array to the list
    tif_arrays.append(tif_data)

    # Store the corresponding tif file path (or feature name) for later comparison
    tif_order.append(tif_file)

# Stack all the arrays along a new axis (e.g., axis 0 for a new dimension)
x = np.stack(tif_arrays, axis=0)
print(f\"Dimensions of x: {x.shape}\")

####   ### nrow=tif_arrays[0].shape[0]   ncol=tif_arrays[0].shape[1] 
x_reshaped = x.reshape(len(tif_arrays), tif_arrays[0].shape[0]  * tif_arrays[0].shape[1] ).T  

print(f\"Dimensions of x_reshaped: {x_reshaped.shape}\")
print(x_reshaped[0, :31]) # first  row = to gdallocationinfo 0 0
print(x_reshaped[1, :31]) # second row = to gdallocationinfo 1 0

# expr 3774 * 8567  32331858
print(x_reshaped[32331857, :31]) # first  row = to gdallocationinfo 0 0

# Check if the order of tif_order matches the order of feature_names
if tif_order == feature_names:
    print(\"Order of TIFF files matches the order in the predictors object.\")
else:
    print(\"Order mismatch between TIFF files and predictors object!\")
    # Optional: Print the mismatched orders for debugging
    print(f\"TIFF order: {tif_order}\")
    print(f\"Predictor order: {feature_names}\")

##### create an empity image 
jim_flow  = pj.Jim(ncol=tif_arrays[0].shape[1], nrow=tif_arrays[0].shape[0], otype=\"GDT_Float32\")
jim_flows = pj.geometry.stackPlane(*[jim_flow for _ in range(11)])

msk = pj.Jim(rf\"/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_{TILE}.tif\")
jim_flows.properties.copyGeoReference(msk)

### load the RF model trained 
with open(\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_YmodelN300_4leaf_4split_60sample_2RF.pkl\" , \"rb\") as f:
     RFreg = dill.load(f)

print(RFreg)

print(\"model prediction\")

## make the prediction for the 11 planes, and reshape

# Perform prediction on the structured array
predictions = RFreg.predict(x_reshaped).astype(np.dtype(\"float32\"))  # change to float64  in case response  out of this range Integer -16777216  16777216  

# Reshape predictions to the correct shape: (nrOfRow, nrOfCol, 11 planes)
reshaped_predictions = predictions.reshape(tif_arrays[0].shape[0], tif_arrays[0].shape[1] , 11)

# Ensure the shape matches the expected output: (11 planes, nrOfRow, nrOfCol)
reshaped_predictions = reshaped_predictions.transpose(2, 0, 1)

# Assign the reshaped predictions to jim_flows.np()
jim_flows.np()[:] = reshaped_predictions.astype(np.float32) # change to float64  in case response  out of this range Integer -16777216  16777216  
jim_flows.geometry.plane2band()

# Write the multi-band output to a TIFF file

print (\"write to output\")
jim_flows.io.write(rf\"{QFLOWS}/{YYYY}_{MM}/Qflow_{YYYY}_{MM}_{TILE}.tif\", co = [\"COMPRESS=LZW\",\"TILED=YES\",\"BIGTIFF=YES\"])

'

"
## to enforce integer extend 
source ~/bin/gdal3
gdal_edit.py -a_ullr $(getCorners4Gtranslate ${QFLOWS}/${YYYY}_${MM}/Qflow_${YYYY}_${MM}_${TILE}.tif) ${QFLOWS}/${YYYY}_${MM}/Qflow_${YYYY}_${MM}_${TILE}.tif
gdalinfo -mm ${QFLOWS}/${YYYY}_${MM}/Qflow_${YYYY}_${MM}_${TILE}.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > ${QFLOWS}/${YYYY}_${MM}/Qflow_${YYYY}_${MM}_${TILE}.mm


exit
### validation  by y

echo "ID YYYY MM lon lat QMINo Q10o Q20o Q30o Q40o Q50o Q60o Q70o Q80o Q90o QMAXo QMINt Q10t Q20t Q30t Q40t Q50t Q60t Q70t Q80t Q90t QMAXt" > /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_obs_predict_1974_08.txt
paste -d " "  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_YTestN300_4leaf_4split_60sample_2RF.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_YpredictTestN300_4leaf_4split_60sample_2RF.txt | grep "1974 8" >> /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_obs_predict_1974_08.txt


echo "ID YYYY MM lon lat QMINo Q10o Q20o Q30o Q40o Q50o Q60o Q70o Q80o Q90o QMAXo QMINt Q10t Q20t Q30t Q40t Q50t Q60t Q70t Q80t Q90t QMAXt" > /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt
paste -d " "  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_YTrainN300_4leaf_4split_60sample_2RF.txt /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_YpredictTrainN300_4leaf_4split_60sample_2RF.txt | grep "1974 8" >> /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt


### validation at global level
gdalbuildvrt    -overwrite  /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_all.vrt /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/*.tif 

echo  "ID YYYY MM lon lat QMINo Q10o Q20o Q30o Q40o Q50o Q60o Q70o Q80o Q90o QMAXo QMINt Q10t Q20t Q30t Q40t Q50t Q60t Q70t Q80t Q90t QMAXt QMINr Q10r Q20r Q30r Q40r Q50r Q60r Q70r Q80r Q90r QMAXr" > /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_predR_preT_1974_08.txt
paste -d " " \
      <(awk '{ if (NR>1) print}' /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_obs_predict_1974_08.txt ) \
      <(gdallocationinfo  -geoloc -valonly /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_all.vrt < <(awk '{ if (NR>1 ) print $4 , $5   }'  /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_obs_predict_1974_08.txt) | awk  'ORS=NR%11?FS:RS' ) \
      >> /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/test_obs_predT_preR_1974_08.txt

echo  "ID YYYY MM lon lat QMINo Q10o Q20o Q30o Q40o Q50o Q60o Q70o Q80o Q90o QMAXo QMINt Q10t Q20t Q30t Q40t Q50t Q60t Q70t Q80t Q90t QMAXt QMINr Q10r Q20r Q30r Q40r Q50r Q60r Q70r Q80r Q90r QMAXr" > /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_predR_preT_1974_08.txt
paste -d " " \
      <(awk '{ if (NR>1) print}' /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt  ) \
      <(gdallocationinfo  -geoloc -valonly /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_all.vrt < <(awk '{ if (NR>1 ) print $4 , $5   }'  /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt) | awk  'ORS=NR%11?FS:RS' ) \
      >> /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predT_preR_1974_08.txt

###  for the h08v05 tile 

echo  "ID YYYY MM lon lat QMINo Q10o Q20o Q30o Q40o Q50o Q60o Q70o Q80o Q90o QMAXo QMINt Q10t Q20t Q30t Q40t Q50t Q60t Q70t Q80t Q90t QMAXt QMINr Q10r Q20r Q30r Q40r Q50r Q60r Q70r Q80r Q90r QMAXr" > /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_predR_preT_1974_08_h08v05.txt

paste -d " "  <( awk '{ if (NR>1) print}'   /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt) <(gdallocationinfo  -geoloc -valonly /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_h08v05.tif  < <(awk '{ if (NR>1 ) print $4 , $5   }'  /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predict_1974_08.txt) |   | awk  'ORS=NR%11?FS:RS' )  >> /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/train_obs_predT_preR_1974_08_h08v05.txt


### validation  by y at a specific point
grep ^99999   /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/t*_obs_predict_1974_08.txt
gdallocationinfo  -geoloc -valonly /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_all.vrt -99.999371 39.999434

grep ^8723   /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/rastpredict_val/t*_obs_predict_1974_08.txt 
gdallocationinfo  -geoloc -valonly /vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS/qflow/1974_08/Qflow_1974_08_all.vrt -118.522087 45.682919 
### validation  by x

