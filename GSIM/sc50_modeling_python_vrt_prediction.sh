#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc50_modeling_python_vrt_prediction.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc50_modeling_python_vrt_prediction.sh.%A_%a.err
#SBATCH --job-name=sc50_modeling_python_vrt_prediction.sh
#SBATCH --array=200
#SBATCH --mem=50G

##### #SBATCH  --array=6-708 
##### #SBATCH --array=1,116   #####       h18v04 59 for testing 


###### sbatch --export=TILE=h18v04  /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc50_modeling_python_vrt_prediction.sh 
#### for TILE  in $(cat /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/input_tile/tile_list.txt | head -50 | tail -1 ) ; do sbatch --export=TILE=$TILE  /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc50_modeling_python_vrt_prediction.sh ; done

##### crate an Apptainer container using docker file
##### downlad https://github.com/ec-jrc/jeolib-pyjeo/blob/master/docker/Dockerfile_deb12_pyjeo
##### install localy spython   https://stackoverflow.com/questions/60314664/how-to-build-singularity-container-from-dockerfile
##### spython recipe Dockerfile_deb12_pyjeo.sh &> Dockerfile_deb12_pyjeo.def
##### scp to grace
##### apptainer build  deb12_pyjeo.sif   Dockerfile_deb12_pyjeo.def 
#### wget https://gitlab.com/selvaje74/hydrography.org/-/raw/main/images/hydrography90m/tiles20d/tile_list.txt
module load StdEnv
source ~/bin/gdal3

export DATE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824) print $2 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/metadata/date.txt )
export TILE=$TILE

export DATE=1974-08-31
export TILE=h16v00

export INTILE=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/input_tile
export SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping
export EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
export RAM=/dev/shm
export TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
export SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
export ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
export GRWL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
export GSW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW
export HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT

export DA_TE=$(echo $DATE | awk -F - '{ print $1"_"$2 }')
export  YYYY=$(echo $DATE | awk -F - '{ print $1 }')
export    MM=$(echo $DATE | awk -F - '{ print $2 }')

echo $DATE 

DATE1=$(grep -B 1 $DATE $SNAP/metadata/date.txt | awk '{ if (NR==1) print $2 }' ) 
DA_TE1=$(echo $DATE1 | awk -F - '{ print $1"_"$2 }')
YYYY1=$(echo $DATE1  | awk -F - '{ print $1 }')
MM1=$(echo $DATE1    | awk -F - '{ print $2 }')

DATE2=$(grep -B 2 $DATE $SNAP/metadata/date.txt | awk '{ if (NR==1) print $2 }' ) 
DA_TE2=$(echo $DATE2 | awk -F - '{ print $1"_"$2 }')
YYYY2=$(echo $DATE2  | awk -F - '{ print $1 }')
MM2=$(echo $DATE2    | awk -F - '{ print $2 }')

DATE3=$(grep -B 3 $DATE $SNAP/metadata/date.txt | awk '{ if (NR==1) print $2 }' ) 
DA_TE3=$(echo $DATE3 | awk -F - '{ print $1"_"$2 }')
YYYY3=$(echo $DATE3  | awk -F - '{ print $1 }')
MM3=$(echo $DATE3    | awk -F - '{ print $2 }')

DATE4=$(grep -B 4 $DATE $SNAP/metadata/date.txt | awk '{ if (NR==1) print $2 }' ) 
DA_TE4=$(echo $DATE4 | awk -F - '{ print $1"_"$2 }')
YYYY4=$(echo $DATE4  | awk -F - '{ print $1 }')
MM4=$(echo $DATE4    | awk -F - '{ print $2 }')

DATE5=$(grep -B 5 $DATE $SNAP/metadata/date.txt | awk '{ if (NR==1) print $2 }' ) 
DA_TE5=$(echo $DATE5 | awk -F - '{ print $1"_"$2 }')
YYYY5=$(echo $DATE5  | awk -F - '{ print $1 }')
MM5=$(echo $DATE5    | awk -F - '{ print $2 }')


rm $INTILE/${YYYY}_${MM}_${DATE}.txt
######## PPT TERRA

IMP_FILE=stationID_x_y_valueALL_predictors_randX9583643_S3YimportanceN300_5leaf_5split_4sample_2RF.txt

for var1 in ppt0 ppt1 ppt2 ppt3 ppt4 ppt5 ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = ppt0  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt    ) | sed '/^$/d'  ; fi
    if [ "$var2" = ppt1  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt ) | sed '/^$/d'  ; fi
    if [ "$var2" = ppt2  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt ) | sed '/^$/d'  ; fi
    if [ "$var2" = ppt3  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt ) | sed '/^$/d'  ; fi
    if [ "$var2" = ppt4  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY4/ppt_${YYYY4}_$MM4.vrt ) | sed '/^$/d'  ; fi
    if [ "$var2" = ppt5  ] ; then echo $pos $(ls $TERRA/ppt_acc/$YYYY1/ppt_${YYYY5}_$MM5.vrt ) | sed '/^$/d'  ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## TMIM TERRA

for var1 in tmin0 tmin1 tmin2 tmin3 tmin4 tmin5 ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmin0  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt ) | sed '/^$/d'           ; fi
    if [ "$var2" = tmin1  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmin2  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmin3  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmin4  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY4/tmin_${YYYY4}_$MM4.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmin5  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY1/tmin_${YYYY5}_$MM5.vrt ) | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## TMAX TERRA

for var1 in tmax0 tmax1 tmax2 tmax3 tmax4 tmax5 ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = tmax0  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt ) | sed '/^$/d'           ; fi
    if [ "$var2" = tmax1  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmax2  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmax3  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmax4  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY4/tmax_${YYYY4}_$MM4.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = tmax5  ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY1/tmax_${YYYY5}_$MM5.vrt ) | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## SNOW TERRA   

for var1 in swe0 swe1 swe2 swe3 swe4 swe5 ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = swe0  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt ) | sed '/^$/d'           ; fi
    if [ "$var2" = swe1  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = swe2  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = swe3  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = swe4  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY4/swe_${YYYY4}_$MM4.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = swe5  ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY1/swe_${YYYY5}_$MM5.vrt ) | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## SOIL TERRA   

for var1 in soil0 soil1 soil2 soil3 soil4 soil5 ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = soil0  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt ) | sed '/^$/d'           ; fi
    if [ "$var2" = soil1  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = soil2  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = soil3  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = soil4  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY4/soil_${YYYY4}_$MM4.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = soil5  ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY1/soil_${YYYY5}_$MM5.vrt ) | sed '/^$/d'        ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## SOILGRID

for var1 in AWCtS CLYPPT SLTPPT SNDPPT WWP ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = AWCtS   ] ; then echo $pos $(ls $SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt ) | sed '/^$/d'          ; fi
    if [ "$var2" = CLYPPT  ] ; then echo $pos $(ls $SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = SLTPPT  ] ; then echo $pos $(ls $SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = SNDPPT  ] ; then echo $pos $(ls $SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = WWP     ] ; then echo $pos $(ls $SOILGRIDS/WWP_acc/WWP_WeigAver.vrt ) | sed '/^$/d'              ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt 

######## GRWL 

for var1 in GRWLw GRWLr GRWLl GRWLd GRWLc  ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GRWLw  ] ; then echo $pos $(ls $GRWL/GRWL_water_acc/GRWL_water.vrt ) | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLr  ] ; then echo $pos $(ls $GRWL/GRWL_river_acc/GRWL_river.vrt ) | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLl  ] ; then echo $pos $(ls $GRWL/GRWL_lake_acc/GRWL_lake.vrt ) | sed '/^$/d'        ; fi
    if [ "$var2" = GRWLd  ] ; then echo $pos $(ls $GRWL/GRWL_delta_acc/GRWL_delta.vrt ) | sed '/^$/d'      ; fi
    if [ "$var2" = GRWLc  ] ; then echo $pos $(ls $GRWL/GRWL_canal_acc/GRWL_canal.vrt ) | sed '/^$/d'      ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt 

#####  GSW

for var1 in GSWs GSWr GSWo GSWe ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = GSWs  ] ; then echo $pos $(ls $GSW/seasonality_acc/seasonality.vrt ) | sed '/^$/d' ; fi
    if [ "$var2" = GSWr  ] ; then echo $pos $(ls $GSW/recurrence_acc/recurrence.vrt ) | sed '/^$/d'   ; fi
    if [ "$var2" = GSWo  ] ; then echo $pos $(ls $GSW/occurrence_acc/occurrence.vrt ) | sed '/^$/d'   ; fi
    if [ "$var2" = GSWe  ] ; then echo $pos $(ls $GSW/extent_acc/extent.vrt ) | sed '/^$/d'            ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt 

##### hydrography

for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt -e order_vect.vrt  -e channel -e order  )  ; do 
name_imp=$(basename $vrt .vrt  )
name_tif=$(grep "${name_imp} " $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
name_pos=$(grep -n "${name_imp} " $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}'   )
echo $name_pos $( ls  $HYDRO/hydrography90m_v.1.0/*/${name_tif}_tiles20d/${name_tif}.vrt 2> /dev/null ) | sed '/^$/d'
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

###### elevation 

for var1 in ELEV ; do
    var2=$(grep $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' )
    pos=$(grep -n $var1 $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}' )
    if [ "$var2" = ELEV  ] ; then echo $pos $(ls $MERIT/input_tif/all_tif.vrt) ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

#### geomorpho 

for vrt in $( ls   $MERIT/geomorphometry_90m_wgs84/*/all_*_90M.vrt | grep -v -e all_aspect_90M.vrt  -e all_cti_90M.vrt -e all_spi_90M.vrt  )  ; do
name_imp=$(basename $vrt _90M.vrt | sed 's/all_//g' | sed 's/-/_/g'  )
name_tif=$(grep "${name_imp} " $EXTRACT/../extract4mod/$IMP_FILE | awk '{ print $1 }' | sed 's/_/-/g')
name_pos=$(grep -n "${name_imp} " $EXTRACT/../extract4mod/$IMP_FILE | awk -F : '{print $1}'   )
# echo ${name_imp} ${name_tif}
echo $name_pos $( ls  $MERIT/geomorphometry_90m_wgs84/${name_tif}/all_${name_tif}_90M.vrt  2> /dev/null ) | sed '/^$/d' 
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

sort -k 1,1 -g $INTILE/${YYYY}_${MM}_${DATE}.txt |  awk '{print $2  }'     > $INTILE/${YYYY}_${MM}_${DATE}_s.txt

gdalbuildvrt -overwrite -separate -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_$TILE.tif) -input_file_list  $INTILE/${YYYY}_${MM}_${DATE}_s.txt   $INTILE/${YYYY}_${MM}_${DATE}.vrt

# mkdir -p $INTILE/${DATE}_${TILE}
# cat $INTILE/${YYYY}_${MM}_${DATE}_s.txt  | xargs -n 1 -P 10 bash -c $' 
# file=$1
# filename=$( echo $(basename  $file .vrt) | sed  -e \'s/all_//g\'    )
# export GDAL_CACHEMAX=1000
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $(getCorners4Gtranslate /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_$TILE.tif) $file  $INTILE/${DATE}_${TILE}/$filename.tif 
# ' _

##### pyjeo in apptainer  use 1.26.2 numpy   python Python 3.11.2    numpy 1.26.2 
##### conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts  python=3.11.2  numpy=1.26.2  scipy=1.11.4 pandas=2.1.3  matplotlib=3.8.2  scikit-learn dill 
##### to add packeg
##### conda activate env_gsi_ts 
##### conda install dill

module purge
apptainer exec --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH",DATE=$DATE,TILE=$TILE,INTILE=$INTILE,DA_TE=$DA_TE,YYYY=$YYYY,MM=$MM /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif bash -c "




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

DATE=(os.environ[\"DATE\"])
TILE=(os.environ[\"TILE\"])
INTILE=(os.environ[\"INTILE\"])

DA_TE=(os.environ[\"DA_TE\"])
YYYY=(os.environ[\"YYYY\"])
MM=(os.environ[\"MM\"])

print(DATE)
print(TILE)
print(INTILE)

jim = pj.Jim(rf\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/input_tile/1974-08-31_h16v00/ppt_1974_08.tif\")

jim_stak = pj.Jim(otype=\"GDT_Float32\", ncol = 5000 , nrow = 5000 )

print(jim_stak.properties.imageInfo())

tif_files = glob.glob(rf\"{INTILE}/{DATE}_{TILE}/*.tif\") 
column_names=[]
for file in tif_files:
    print(rf\"{file}\")
    filename = os.path.splitext(os.path.basename(rf\"{file}\"))[0]
    print(rf\"{filename}\") 
    # jim = pj.Jim(rf\"{file}\")
    # print(jim.properties.imageInfo())
    # exec(f\"{filename} = jim\")    #### assign variable name to the object 
    jim_stak.geometry.stackPlane(pj.Jim(file))
    jim_stak.properties.setDimension(filename, \"plane\", append = True)
    column_names.append(filename) 

print(column_names)   

print(type(column_names))

print(jim_stak.properties.imageInfo())

### from jim stak object to np array
x = jim_stak.np()

# Create a structured array with column names and default data type (float)
# dtype = [(name, 'float') for name in column_names]
# structured_x = np.zeros(x.shape[0], dtype=dtype)

# Fill in the structured array with values from the original array X

# x_transposed = x.T
# for i, name in enumerate(column_names):
#     structured_x[name][:] = x_transposed[:, i]

print(structured_x)

x = x.reshape(jim_stak.properties.nrOfPlane(), jim_stak.properties.nrOfRow() * jim_stak.properties.nrOfCol()).T

##### create an empity image 
jim_flow = pj.Jim(ncol=jim_stak.properties.nrOfCol(), nrow=jim_stak.properties.nrOfRow(), otype=\"GDT_Float32\")
jim_flows = pj.geometry.stackPlane( jim_flow , jim_flow , jim_flow ) 
jim_flows.properties.copyGeoReference(jim_stak)

fin=\"/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract4mod/stationID_x_y_valueALL_predictors_randX9583643_S3YmodelN300_5leaf_5split_4sample_2RF.pkl\"
dill.load_session(fin)
dir()

print(\"model prediction\")

jim_flows.np()[:] = RFreg.predict(structured_x).astype(np.dtype(\"float\")).reshape(3 ,  jim_stak.properties.nrOfRow() , jim_stak.properties.nrOfCol()) 


print (\"write to output\")
jim_flows.io.write(\"/home/ga254/test.tif\", co = [\"COMPRESS=LZW\", \"TILED=YES\"])


'

"

exit 

#### apptainer run  --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH" /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif bash
#### apptainer exec --env=PATH="/home/ga254/project/python_env/pyjeo/bin:$PATH" /gpfs/gibbs/project/sbsc/ga254/python_env/deb12_pyjeo_fullbuild.sif  python3 -c "import pyjeo as pj; jim = pj.Jim(ncol = 10, nrow = 10, nband = 3); print(jim.properties.nrOfBand())"


exit



for file in full_tif/*.tif ; do gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9   -srcwin 0  5000 5000 5000  $file $(basename $file ) ; done
