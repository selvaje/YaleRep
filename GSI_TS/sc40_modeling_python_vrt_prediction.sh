#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc40_modeling_python_vrt_prediction.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc40_modeling_python_vrt_prediction.sh.%A_%a.err
#SBATCH --job-name=sc40_modeling_python_vrt_prediction.sh
#SBATCH --array=200
#SBATCH --mem=1200G

##### #SBATCH  --array=4-744 
##### #SBATCH --array=1,116   ##### 20d       h18v04 59 for testing
##### #SBATCH --array=1,544   ##### 10d       h18v04 59 for testing 

###### sbatch --export=TILE=h16v00  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc40_modeling_python_vrt_prediction.sh 
#### for TILE  in $(cat /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/input_tile/tile_list.txt | head -50 | tail -1 ) ; do sbatch --export=TILE=$TILE  /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc40_modeling_python_vrt_prediction.sh ; done

##### crate an Apptainer container using docker file
##### downlad https://github.com/ec-jrc/jeolib-pyjeo/blob/master/docker/Dockerfile_deb12_pyjeo
##### install localy spython   https://stackoverflow.com/questions/60314664/how-to-build-singularity-container-from-dockerfile
##### spython recipe Dockerfile_deb12_pyjeo.sh &> Dockerfile_deb12_pyjeo.def
##### scp to grace
##### apptainer build  deb12_pyjeo.sif   Dockerfile_deb12_pyjeo.def 
#### wget https://gitlab.com/selvaje74/hydrography.org/-/raw/main/images/hydrography90m/tiles20d/tile_list.txt
module load StdEnv
source ~/bin/gdal3

# SLURM_ARRAY_TASK_ID=200
export TILE=$TILE

# export TILE=h16v00

export INTILE=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/input_tile
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

export DA_TE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID) print $1"_"$2 }' $META/date.txt)
export YYYY=$(echo $DA_TE | awk -F "_"  '{ print $1 }')
export MM=$(echo $DA_TE | awk  -F "_"   '{ print $2 }')

echo DA_TE $DA_TE   YYYY  $YYYY MM $MM

export DA_TE1=$(awk -v n=1  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY1=$(echo $DA_TE1  | awk -F "_"  '{ print $1 }')
export MM1=$(echo $DA_TE1    | awk -F "_"  '{ print $2 }')

export DA_TE2=$(awk -v n=2  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY2=$(echo $DA_TE2  | awk -F "_"  '{ print $1 }')
export MM2=$(echo $DA_TE2    | awk -F "_"  '{ print $2 }')

export DA_TE3=$(awk -v n=3  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY3=$(echo $DA_TE3  | awk -F "_"  '{ print $1 }')
export MM3=$(echo $DA_TE3    | awk -F "_"  '{ print $2 }')

rm -f $INTILE/${YYYY}_${MM}_${DA_TE}.txt  $INTILE/${YYYY}_${MM}_${DA_TE}.vrt  $INTILE/${YYYY}_${MM}_${DA_TE}_s.txt 
######## PPT TERRA

### use the colname of selevted variables to build a txt $INTILE/${YYYY}_${MM}_${DA_TE}.txt  path-tif and tif name 
IMP_FILE=stationID_x_y_valueALL_predictors_randX_YcolnamesN300_4leaf_4split_40sample_2RF.txt

# the pos variable identify the position in the column name for a later sorting

for var1 in ppt0 ppt1 ppt2 ppt3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = ppt0  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt    ) ppt0.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt1  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt ) ppt1.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt2  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt ) ppt2.tif | sed '/^$/d'  ; fi
    if [ "$var2" = ppt3  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt ) ppt3.tif | sed '/^$/d'  ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## TMIM TERRA

for var1 in tmin0 tmin1 tmin2 tmin3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmin0  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt ) tmin0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = tmin1  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt ) tmin1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmin2  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt ) tmin2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmin3  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt ) tmin3.tif | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## TMAX TERRA

for var1 in tmax0 tmax1 tmax2 tmax3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmax0  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt ) tmax0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = tmax1  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt ) tmax1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmax2  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt ) tmax2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = tmax3  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt ) tmax3.tif | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## SNOW TERRA   

for var1 in swe0 swe1 swe2 swe3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = swe0  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt ) swe0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = swe1  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt ) swe1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = swe2  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt ) swe2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = swe3  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt ) swe3.tif | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## SOIL TERRA   

for var1 in soil0 soil1 soil2 soil3 ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = soil0  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt ) soil0.tif | sed '/^$/d'           ; fi
    if [ "$var2" = soil1  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt ) soil1.tif | sed '/^$/d'        ; fi
    if [ "$var2" = soil2  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt ) soil2.tif | sed '/^$/d'        ; fi
    if [ "$var2" = soil3  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt ) soil3.tif | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## SOILGRID

for var1 in AWCtS CLYPPT SLTPPT SNDPPT WWP ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = AWCtS   ] ; then echo $pos $(ls $SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt ) AWCtS.tif  | sed '/^$/d'          ; fi
    if [ "$var2" = CLYPPT  ] ; then echo $pos $(ls $SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt ) CLYPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = SLTPPT  ] ; then echo $pos $(ls $SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt ) SLTPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = SNDPPT  ] ; then echo $pos $(ls $SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt ) SNDPPT.tif | sed '/^$/d'        ; fi
    if [ "$var2" = WWP     ] ; then echo $pos $(ls $SOILGRIDS/WWP_acc/WWP_WeigAver.vrt ) WWP.tif | sed '/^$/d'              ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

######## GRWL 

for var1 in GRWLw GRWLr GRWLl GRWLd GRWLc  ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GRWLw  ] ; then echo $pos $(ls $GRWL/GRWL_water_acc/GRWL_water.vrt ) GRWLw.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLr  ] ; then echo $pos $(ls $GRWL/GRWL_river_acc/GRWL_river.vrt ) GRWLr.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLl  ] ; then echo $pos $(ls $GRWL/GRWL_lake_acc/GRWL_lake.vrt   ) GRWLl.tif | sed '/^$/d'        ; fi
    if [ "$var2" = GRWLd  ] ; then echo $pos $(ls $GRWL/GRWL_delta_acc/GRWL_delta.vrt ) GRWLd.tif | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLc  ] ; then echo $pos $(ls $GRWL/GRWL_canal_acc/GRWL_canal.vrt ) GRWLc.tif | sed '/^$/d'      ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

#####  GSW

for var1 in GSWs GSWr GSWo GSWe ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GSWs  ] ; then echo $pos $(ls $GSW/seasonality_acc/seasonality.vrt ) GSWs.itf | sed '/^$/d' ; fi
    if [ "$var2" = GSWr  ] ; then echo $pos $(ls $GSW/recurrence_acc/recurrence.vrt ) GSWr.tif | sed '/^$/d'   ; fi
    if [ "$var2" = GSWo  ] ; then echo $pos $(ls $GSW/occurrence_acc/occurrence.vrt ) GSWo.tif | sed '/^$/d'   ; fi
    if [ "$var2" = GSWe  ] ; then echo $pos $(ls $GSW/extent_acc/extent.vrt ) GSWe.tif | sed '/^$/d'            ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

##### hydrography  #### the cti has negative values.

for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt -e order_vect.vrt  -e channel -e order -e accumulation  )  ; do 
name_imp=$(basename $vrt .vrt  )
name_tif=$(grep ${name_imp}  $EXTRACT/$IMP_FILE )
name_pos=$(grep -n ${name_imp}  $EXTRACT/$IMP_FILE | awk -F : '{print $1}'   )
if [[ !  -z  $name_tif   ]] ;  then
    echo $name_pos $( ls  $HYDRO/hydrography90m_v.1.0/*/${name_tif}_tiles20d/${name_tif}.vrt 2> /dev/null )  ${name_tif}.tif   | sed '/^$/d'
fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

##### positive accumulation

for var1 in accumulation ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = accumulation  ] ; then echo $pos $(ls $HYDRO/flow_tiles/all_tif_pos_dis.vrt )  accumulation.tif  ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

###### elevation 

for var1 in elev ; do
    var2=$(grep $var1 $EXTRACT/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = elev  ] ; then echo $pos $(ls $MERIT/input_tif/all_tif.vrt) elev.tif ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

#### geomorpho 

for vrt in $( ls $MERIT/geomorphometry_90m_wgs84/*/all_*_90M.vrt | grep -v -e all_aspect_90M.vrt  -e all_cti_90M.vrt -e all_spi_90M.vrt  )  ; do
name_imp=$(basename $vrt _90M.vrt | sed 's/all_//g' ) #  sed 's/-/_/g' 
name_tif=$(grep ${name_imp}$  $EXTRACT/$IMP_FILE ) #  sed 's/_/-/g' 
name_pos=$(grep -n ${name_imp}$  $EXTRACT/$IMP_FILE | awk -F : '{print $1}'   )
# echo ${name_imp} ${name_tif}
if [[ !  -z  $name_tif   ]] ;  then
    echo $name_pos $( ls  $MERIT/geomorphometry_90m_wgs84/${name_tif}/all_${name_tif}_90M.vrt  2> /dev/null )  ${name_tif}.tif   ;
fi 
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

sort -k 1,1 -g $INTILE/${YYYY}_${MM}_${DA_TE}.txt |  awk '{print $2  }'     > $INTILE/${YYYY}_${MM}_${DA_TE}_s.txt

gdalbuildvrt -overwrite -separate -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_pos_$TILE.tif) -input_file_list  $INTILE/${YYYY}_${MM}_${DA_TE}_s.txt   $INTILE/${YYYY}_${MM}_${DA_TE}.vrt

rm -r $INTILE/${DA_TE}_${TILE}
mkdir -p $INTILE/${DA_TE}_${TILE}
cat $INTILE/${YYYY}_${MM}_${DA_TE}.txt  | xargs -n 3  -P 4 bash -c $' 
file=$2
fileout=$3
export GDAL_CACHEMAX=10000
##  add for testing  -srcwin 0 0 5000 5000
gdal_translate  -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $(getCorners4Gtranslate /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_$TILE.tif) $file  $INTILE/${DA_TE}_${TILE}/$fileout 
' _

##### pyjeo in apptainer  use 1.26.2 numpy   python Python 3.11.2    numpy 1.26.2 
##### conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts  python=3.11.2  numpy=1.26.2  scipy=1.11.4 pandas=2.1.3  matplotlib=3.8.2  scikit-learn dill 
##### to add packeg
##### conda activate env_gsi_ts 
##### conda install dill

module purge
apptainer exec --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH",DA_TE=$DA_TE,TILE=$TILE,INTILE=$INTILE,DA_TE=$DA_TE,YYYY=$YYYY,MM=$MM /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif bash -c "


python3 -c '
import os, sys  , glob
import pandas as pd
import numpy as np
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python311.zip\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/lib-dynload\")
sys.path.append(\"/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/site-packages\")
from numpy import savetxt
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.feature_selection import RFECV
from sklearn.feature_selection import RFE
from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.metrics import mean_squared_error
from scipy import stats
from scipy.stats import pearsonr
from sklearn.metrics import r2_score
import dill 
import pyjeo as pj

DA_TE=(os.environ[\"DA_TE\"])
TILE=(os.environ[\"TILE\"])
INTILE=(os.environ[\"INTILE\"])

DA_TE=(os.environ[\"DA_TE\"])
YYYY=(os.environ[\"YYYY\"])
MM=(os.environ[\"MM\"])

print(DA_TE)
print(TILE)
print(INTILE)
# load the column name to load the tif in the same order 
predictors = pd.read_csv(\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_randX_YcolnamesN300_4leaf_4split_40sample_2RF.txt\", header=None)

firsttif=\" \".join(predictors.iloc[0].values.astype(str))

# load the first tif, but probably is not needed
jim = pj.Jim(rf\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/input_tile/1974_08_h16v00/{firsttif}.tif\")

jim_stak = pj.Jim(otype=\"GDT_Float32\", ncol = 24000, nrow = 24000)    #  full tiff  24000, 24000 

print(jim_stak.properties.imageInfo())

column_names=[]
### start to load from the second tif. Anyway prob it need to start form 0
for index, row in predictors.iloc[1:].iterrows():
    tif_file = \" \".join(row.values.astype(str))
    file_path = rf\"{INTILE}/{DA_TE}_{TILE}/{tif_file}.tif\"
    print(rf\"{file_path}\")
    filename = os.path.splitext(os.path.basename(file_path))[0]
    print(rf\"{filename}\")
    # Stack the planes in jim_stak
    jim_stak.geometry.stackPlane(pj.Jim(file_path, otype=\"GDT_Float32\" ))    
    # Set the dimension properties
    jim_stak.properties.setDimension(filename, \"plane\", append=True)
        
    # Append the filename to column_names
    column_names.append(filename)

print(column_names)   
print(type(column_names))
print(jim_stak.properties.imageInfo())
print(jim.xr())
### from jim stak object to np array
x = jim_stak.np()

# Create a structured array with column names and default data type (float)
# dtype = [(name, 'float') for name in column_names]
# structured_x = np.zeros(x.shape[0], dtype=dtype)

# Fill in the structured array with values from the original array X

# x_transposed = x.T
# for i, name in enumerate(column_names):
#     structured_x[name][:] = x_transposed[:, i]
# print(structured_x)

#### 11 plane 
x = x.reshape(jim_stak.properties.nrOfPlane(), jim_stak.properties.nrOfRow() * jim_stak.properties.nrOfCol()).T

##### create an empity image 
jim_flow = pj.Jim(ncol=jim_stak.properties.nrOfCol(), nrow=jim_stak.properties.nrOfRow(), otype=\"GDT_Float32\")
jim_flows = pj.geometry.stackPlane(jim_flow , jim_flow , jim_flow ,jim_flow , jim_flow , jim_flow , jim_flow , jim_flow , jim_flow ,  jim_flow , jim_flow ) 
jim_flows.properties.copyGeoReference(jim_stak)

### load the RF model trained 
with open(\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_randX_YmodelN300_4leaf_4split_40sample_2RF.pkl\" , \"rb\") as f:
     RFreg = dill.load(f)

print(RFreg)

print(\"model prediction\")

## make the prediction for the 11 planes, and reshape
## jim_flows.np()[:] = RFreg.predict(x).astype(np.dtype(\"float\")).reshape( 11 , jim_stak.properties.nrOfRow() , jim_stak.properties.nrOfCol()  ) 

# Perform prediction on the structured array
predictions = RFreg.predict(x).astype(np.dtype(\"float\"))

# Reshape predictions to the correct shape: (nrOfRow, nrOfCol, 11 planes)
reshaped_predictions = predictions.reshape(jim_stak.properties.nrOfRow(), jim_stak.properties.nrOfCol(), 11)

# Before transposing, the predictions array is reshaped into (nrOfRow, nrOfCol, 11). This means:
# Axis 0 corresponds to the number of rows (nrOfRow).
# Axis 1 corresponds to the number of columns (nrOfCol).
# Axis 2 corresponds to the 11 planes.
# What transpose(2, 0, 1) does:
# The transpose function reorders the axes of the array, where:
# 2 becomes the first axis (planes),
# 0 becomes the second axis (rows),
# 1 becomes the third axis (columns).
# Thus, the shape changes from (nrOfRow, nrOfCol, 11) to (11, nrOfRow, nrOfCol).

# Ensure the shape matches the expected output: (11 planes, nrOfRow, nrOfCol)
reshaped_predictions = reshaped_predictions.transpose(2, 0, 1)

# Assign the reshaped predictions to jim_flows.np()
jim_flows.np()[:] = reshaped_predictions.astype(np.float32)
jim_flows.geometry.plane2band()

# Write the multi-band output to a TIFF file

print (\"write to output\")
jim_flows.io.write(\"/home/ga254/test_h18v04.tif\", co = [\"COMPRESS=LZW\",\"TILED=YES\",\"BIGTIFF=YES\"])

'

"

exit 

#### apptainer run  --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH" /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif bash
#### apptainer exec --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH" /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif  python3 ###   -c "import pyjeo as pj; jim = pj.Jim(ncol = 10, nrow = 10, nband = 3); print(jim.properties.nrOfBand())"


exit



for file in original/*.tif ; do gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9   -srcwin 0  5000 5000 5000  $file $(basename $file ) ; done


