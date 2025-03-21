#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /home/st929/output/sc50_YEARLY.sh.%A_%a.out
#SBATCH -e /home/st929/output/sc50_YEARLY.sh.%A_%a.err
#SBATCH --job-name=sc50_modeling_python_vrt_prediction.sh
#SBATCH --array=200
#SBATCH --mem=220G
#SBATCH --array=613

#### for TILE  in $(cat ~/tile_list_usa.txt | head -50 | tail -1 ) ; do sbatch --export=TILE=$TILE  /home/st929/scripts/sc50_modeling_python_vrt_prediction_samuel.sh ; done

##### crate an Apptainer container using docker file
##### downlad https://github.com/ec-jrc/jeolib-pyjeo/blob/master/docker/Dockerfile_deb12_pyjeo
##### install localy spython   https://stackoverflow.com/questions/60314664/how-to-build-singularity-container-from-dockerfile
##### spython recipe Dockerfile_deb12_pyjeo.sh &> Dockerfile_deb12_pyjeo.def
##### scp to grace
##### apptainer build  deb12_pyjeo.sif   Dockerfile_deb12_pyjeo.def 
#### wget https://gitlab.com/selvaje74/hydrography.org/-/raw/main/images/hydrography90m/tiles20d/tile_list.txt
module load StdEnv
source ~/bin/gdal3


#export SLURM_ARRAY_TASK_ID=10
export TILE=h10v05 ## testing use

#export TILE=$TILE
#export INTILES=/home/st929/palmer_scratch/input_tile
export INTILES=/gpfs/gibbs/pi/hydro/st929/input_tiles


export INTILE=/gpfs/gibbs/pi/hydro/st929/input_tile
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
export DATE=$DA_TE
export YYYY=$(echo $DA_TE | awk -F "_"  '{ print $1 }')
export MM=$(echo $DA_TE | awk  -F "_"   '{ print $2 }')

echo DA_TE $DA_TE   YYYY  $YYYY MM $MM

export OUTPUT_FILE="/gpfs/gibbs/pi/hydro/st929/output_tile/ALK_${YYYY}_${MM}_${TILE}.tif"

# Check if the output file already exists

#if [ -f $OUTPUT_FILE ]; then

#	echo "Output file $OUTPUT_FILE already exists. Skipping process for TILE $TILE and DATE ${YYYY}_${MM}."

#	exit 0

#fi

# Proceed with processing if the file does not exist

echo "Processing TILE $TILE for DATE ${YYYY}_${MM}..."

export DA_TE1=$(awk -v n=1  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY1=$(echo $DA_TE1  | awk -F "_"  '{ print $1 }')
export MM1=$(echo $DA_TE1    | awk -F "_"  '{ print $2 }')

export DA_TE2=$(awk -v n=2  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY2=$(echo $DA_TE2  | awk -F "_"  '{ print $1 }')
export MM2=$(echo $DA_TE2    | awk -F "_"  '{ print $2 }')

export DA_TE3=$(awk -v n=3  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY3=$(echo $DA_TE3  | awk -F "_"  '{ print $1 }')
export MM3=$(echo $DA_TE3    | awk -F "_"  '{ print $2 }')

export DA_TE4=$(awk -v n=4  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY4=$(echo $DA_TE4  | awk -F "_"  '{ print $1 }')
export MM4=$(echo $DA_TE4    | awk -F "_"  '{ print $2 }')

export DA_TE5=$(awk -v n=5  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY5=$(echo $DA_TE5  | awk -F "_"  '{ print $1 }')
export MM5=$(echo $DA_TE5    | awk -F "_"  '{ print $2 }')

export DA_TE6=$(awk -v n=6  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY6=$(echo $DA_TE5  | awk -F "_"  '{ print $1 }')
export MM6=$(echo $DA_TE5    | awk -F "_"  '{ print $2 }')

export DA_TE7=$(awk -v n=7  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID - n) print $1"_"$2 }' $META/date.txt)
export YYYY7=$(echo $DA_TE7  | awk -F "_"  '{ print $1 }')
export MM7=$(echo $DA_TE7    | awk -F "_"  '{ print $2 }')


######## PPT TERRA
rm -f $INTILE/${YYYY}_${MM}_${DA_TE}.txt  $INTILE/${YYYY}_${MM}_${DA_TE}.vrt  $INTILE/${YYYY}_${MM}_${DA_TE}_s.txt 
######## PPT TERRA

IMP_FILE='/home/st929/project/predictors_used_feature_selection_Yearly_average.csv'
#IMP_FILE='/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py/stationID_x_y_valueALL_predictors_randX_YcolnamesN300_4leaf_4split_40sample_2RF.txt'


for var1 in ppt0 ppt1 ppt2 ppt3 ppt4 ppt5 ppt6 ppt7; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }')
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = ppt0 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY/ppt_${YYYY}_$MM.vrt) ppt0.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt1 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY1/ppt_${YYYY1}_$MM1.vrt) ppt1.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt2 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY2/ppt_${YYYY2}_$MM2.vrt) ppt2.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt3 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY3/ppt_${YYYY3}_$MM3.vrt) ppt3.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt4 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY4/ppt_${YYYY4}_$MM4.vrt) ppt4.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt5 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY5/ppt_${YYYY5}_$MM5.vrt) ppt5.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt6 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY6/ppt_${YYYY6}_$MM6.vrt) ppt6.tif | sed '/^$/d'; fi
	if [ "$var2" = ppt7 ]; then echo $pos $(ls $TERRA/ppt_acc/$YYYY7/ppt_${YYYY7}_$MM7.vrt) ppt7.tif | sed '/^$/d'; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt


######## TMIM TERRA

for var1 in tmin0 tmin1 tmin2 tmin3 tmin4 tmin5 tmin6 tmin7; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }' )
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}' )
	if [ "$var2" = tmin0  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY/tmin_${YYYY}_$MM.vrt ) tmin0.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin1  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY1/tmin_${YYYY1}_$MM1.vrt ) tmin1.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin2  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY2/tmin_${YYYY2}_$MM2.vrt ) tmin2.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin3  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY3/tmin_${YYYY3}_$MM3.vrt ) tmin3.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin4  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY4/tmin_${YYYY4}_$MM4.vrt ) tmin4.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin5  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY5/tmin_${YYYY5}_$MM5.vrt ) tmin5.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin6  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY6/tmin_${YYYY6}_$MM5.vrt ) tmin6.tif | sed '/^$/d'; fi
	if [ "$var2" = tmin7  ] ; then echo $pos $(ls $TERRA/tmin_acc/$YYYY7/tmin_${YYYY7}_$MM5.vrt ) tmin7.tif | sed '/^$/d'; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## TMAX TERRA
######## TMAX TERRA
for var1 in tmax0 tmax1 tmax2 tmax3 tmax4 tmax5 tmax6 tmax7; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }')
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = tmax0 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY/tmax_${YYYY}_$MM.vrt) tmax0.tif | sed '/^$/d' ; fi
	if [ "$var2" = tmax1 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY1/tmax_${YYYY1}_$MM1.vrt) tmax1.tif | sed '/^$/d' ; fi
	if [ "$var2" = tmax2 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY2/tmax_${YYYY2}_$MM2.vrt) tmax2.tif | sed '/^$/d' ; fi
	if [ "$var2" = tmax3 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY3/tmax_${YYYY3}_$MM3.vrt) tmax3.tif | sed '/^$/d' ; fi
	if [ "$var2" = tmax4 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY4/tmax_${YYYY4}_$MM4.vrt) tmax4.tif | sed '/^$/d' ; fi
	if [ "$var2" = tmax5 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY5/tmax_${YYYY5}_$MM5.vrt) tmax5.tif | sed '/^$/d'; fi
	if [ "$var2" = tmax6 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY6/tmax_${YYYY6}_$MM6.vrt) tmax6.tif | sed '/^$/d'; fi
	if [ "$var2" = tmax7 ] ; then echo $pos $(ls $TERRA/tmax_acc/$YYYY7/tmax_${YYYY7}_$MM7.vrt) tmax7.tif | sed '/^$/d'; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## SNOW TERRA
for var1 in swe0 swe1 swe2 swe3 swe4 swe5 swe6 swe7; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }')
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = swe0 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY/swe_${YYYY}_$MM.vrt) swe0.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe1 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY1/swe_${YYYY1}_$MM1.vrt) swe1.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe2 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY2/swe_${YYYY2}_$MM2.vrt) swe2.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe3 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY3/swe_${YYYY3}_$MM3.vrt) swe3.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe4 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY4/swe_${YYYY4}_$MM4.vrt) swe4.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe5 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY5/swe_${YYYY5}_$MM5.vrt) swe5.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe6 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY6/swe_${YYYY6}_$MM6.vrt) swe6.tif | sed '/^$/d' ; fi
	if [ "$var2" = swe7 ] ; then echo $pos $(ls $TERRA/swe_acc/$YYYY7/swe_${YYYY7}_$MM7.vrt) swe7.tif | sed '/^$/d' ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

######## SOIL TERRA
for var1 in soil0 soil1 soil2 soil3 soil4 soil5 soil6 soil7; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }')
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = soil0 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY/soil_${YYYY}_$MM.vrt) soil0.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil1 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY1/soil_${YYYY1}_$MM1.vrt) soil1.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil2 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY2/soil_${YYYY2}_$MM2.vrt) soil2.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil3 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY3/soil_${YYYY3}_$MM3.vrt) soil3.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil4 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY4/soil_${YYYY4}_$MM4.vrt) soil4.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil5 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY5/soil_${YYYY5}_$MM5.vrt) soil5.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil6 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY4/soil_${YYYY6}_$MM6.vrt) soil6.tif | sed '/^$/d' ; fi
	if [ "$var2" = soil7 ] ; then echo $pos $(ls $TERRA/soil_acc/$YYYY7/soil_${YYYY7}_$MM7.vrt) soil7.tif | sed '/^$/d' ; fi
done >> $INTILE/${YYYY}_${MM}_${DATE}.txt

export YYY=1992
######## LAND COVER
for var1 in LC10 LC11 LC12 LC20 LC30 LC40 LC50 LC60 LC61 LC62 LC70 LC71 LC72 LC80 LC81 LC90 LC100 LC110 LC120 LC121 LC122 LC130 LC140 LC150 LC152 LC153 LC160 LC170 LC180 LC190 LC200 LC201 LC202 LC210 LC220; do
	var2=$(grep -w $var1 $IMP_FILE | awk '{ print $1 }')  ## 0917 2024 -w  ensure LC20 and LC200 won'd intefere
	pos=$(grep -n -w $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = LC10 ] ; then echo $pos $(ls $ESALC/LC10_acc/$YYY/LC10_Y${YYY}.vrt) LC10.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC11 ] ; then echo $pos $(ls $ESALC/LC11_acc/$YYY/LC11_Y${YYY}.vrt) LC11.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC12 ] ; then echo $pos $(ls $ESALC/LC12_acc/$YYY/LC12_Y${YYY}.vrt) LC12.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC20 ] ; then echo $pos $(ls $ESALC/LC20_acc/$YYY/LC20_Y${YYY}.vrt) LC20.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC30 ] ; then echo $pos $(ls $ESALC/LC30_acc/$YYY/LC30_Y${YYY}.vrt) LC30.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC40 ] ; then echo $pos $(ls $ESALC/LC40_acc/$YYY/LC40_Y${YYY}.vrt) LC40.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC50 ] ; then echo $pos $(ls $ESALC/LC50_acc/$YYY/LC50_Y${YYY}.vrt) LC50.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC60 ] ; then echo $pos $(ls $ESALC/LC60_acc/$YYY/LC60_Y${YYY}.vrt) LC60.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC61 ] ; then echo $pos $(ls $ESALC/LC61_acc/$YYY/LC61_Y${YYY}.vrt) LC61.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC62 ] ; then echo $pos $(ls $ESALC/LC62_acc/$YYY/LC62_Y${YYY}.vrt) LC62.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC70 ] ; then echo $pos $(ls $ESALC/LC70_acc/$YYY/LC70_Y${YYY}.vrt) LC70.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC71 ] ; then echo $pos $(ls $ESALC/LC71_acc/$YYY/LC71_Y${YYY}.vrt) LC71.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC72 ] ; then echo $pos $(ls $ESALC/LC72_acc/$YYY/LC72_Y${YYY}.vrt) LC72.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC80 ] ; then echo $pos $(ls $ESALC/LC80_acc/$YYY/LC80_Y${YYY}.vrt) LC80.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC81 ] ; then echo $pos $(ls $ESALC/LC81_acc/$YYY/LC81_Y${YYY}.vrt) LC81.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC90 ] ; then echo $pos $(ls $ESALC/LC90_acc/$YYY/LC90_Y${YYY}.vrt) LC90.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC100 ] ; then echo $pos $(ls $ESALC/LC100_acc/$YYY/LC100_Y${YYY}.vrt) LC100.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC110 ] ; then echo $pos $(ls $ESALC/LC110_acc/$YYY/LC110_Y${YYY}.vrt) LC110.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC120 ] ; then echo $pos $(ls $ESALC/LC120_acc/$YYY/LC120_Y${YYY}.vrt) LC120.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC121 ] ; then echo $pos $(ls $ESALC/LC121_acc/$YYY/LC121_Y${YYY}.vrt) LC121.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC122 ] ; then echo $pos $(ls $ESALC/LC122_acc/$YYY/LC122_Y${YYY}.vrt) LC122.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC130 ] ; then echo $pos $(ls $ESALC/LC130_acc/$YYY/LC130_Y${YYY}.vrt) LC130.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC140 ] ; then echo $pos $(ls $ESALC/LC140_acc/$YYY/LC140_Y${YYY}.vrt) LC140.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC150 ] ; then echo $pos $(ls $ESALC/LC150_acc/$YYY/LC150_Y${YYY}.vrt) LC150.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC152 ] ; then echo $pos $(ls $ESALC/LC152_acc/$YYY/LC152_Y${YYY}.vrt) LC152.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC153 ] ; then echo $pos $(ls $ESALC/LC153_acc/$YYY/LC153_Y${YYY}.vrt) LC153.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC160 ] ; then echo $pos $(ls $ESALC/LC160_acc/$YYY/LC160_Y${YYY}.vrt) LC160.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC170 ] ; then echo $pos $(ls $ESALC/LC170_acc/$YYY/LC170_Y${YYY}.vrt) LC170.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC180 ] ; then echo $pos $(ls $ESALC/LC180_acc/$YYY/LC180_Y${YYY}.vrt) LC180.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC190 ] ; then echo $pos $(ls $ESALC/LC190_acc/$YYY/LC190_Y${YYY}.vrt) LC190.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC200 ] ; then echo $pos $(ls $ESALC/LC200_acc/$YYY/LC200_Y${YYY}.vrt) LC200.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC201 ] ; then echo $pos $(ls $ESALC/LC201_acc/$YYY/LC201_Y${YYY}.vrt) LC201.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC202 ] ; then echo $pos $(ls $ESALC/LC202_acc/$YYY/LC202_Y${YYY}.vrt) LC202.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC210 ] ; then echo $pos $(ls $ESALC/LC210_acc/$YYY/LC210_Y${YYY}.vrt) LC210.tif | sed '/^$/d' ; fi
	if [ "$var2" = LC220 ] ; then echo $pos $(ls $ESALC/LC220_acc/$YYY/LC220_Y${YYY}.vrt) LC220.tif | sed '/^$/d' ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

######## SOILGRID

for var1 in AWCtS CLYPPT SLTPPT SNDPPT WWP ; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }' )
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}' )
	if [ "$var2" = AWCtS   ] ; then echo $pos $(ls $SOILGRIDS/AWCtS_acc/AWCtS_WeigAver.vrt ) AWCtS.tif  | sed '/^$/d'          ; fi
	if [ "$var2" = CLYPPT  ] ; then echo $pos $(ls $SOILGRIDS/CLYPPT_acc/CLYPPT_WeigAver.vrt ) CLYPPT.tif | sed '/^$/d'        ; fi
	if [ "$var2" = SLTPPT  ] ; then echo $pos $(ls $SOILGRIDS/SLTPPT_acc/SLTPPT_WeigAver.vrt ) SLTPPT.tif | sed '/^$/d'        ; fi
	if [ "$var2" = SNDPPT  ] ; then echo $pos $(ls $SOILGRIDS/SNDPPT_acc/SNDPPT_WeigAver.vrt ) SNDPPT.tif | sed '/^$/d'        ; fi
	if [ "$var2" = WWP     ] ; then echo $pos $(ls $SOILGRIDS/WWP_acc/WWP_WeigAver.vrt ) WWP.tif | sed '/^$/d'              ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

######## GRWL 

for var1 in GRWLw GRWLr GRWLl GRWLd GRWLc  ; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }' )
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}' )
	if [ "$var2" = GRWLw  ] ; then echo $pos $(ls $GRWL/GRWL_water_acc/GRWL_water.vrt ) GRWLw.tif | sed '/^$/d'      ; fi
	if [ "$var2" = GRWLr  ] ; then echo $pos $(ls $GRWL/GRWL_river_acc/GRWL_river.vrt ) GRWLr.tif | sed '/^$/d'      ; fi
	if [ "$var2" = GRWLl  ] ; then echo $pos $(ls $GRWL/GRWL_lake_acc/GRWL_lake.vrt   ) GRWLl.tif | sed '/^$/d'        ; fi
	if [ "$var2" = GRWLd  ] ; then echo $pos $(ls $GRWL/GRWL_delta_acc/GRWL_delta.vrt ) GRWLd.tif | sed '/^$/d'      ; fi
	if [ "$var2" = GRWLc  ] ; then echo $pos $(ls $GRWL/GRWL_canal_acc/GRWL_canal.vrt ) GRWLc.tif | sed '/^$/d'      ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

#####  GSW

for var1 in GSWs GSWr GSWo GSWe ; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }' )
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}' )
	if [ "$var2" = GSWs  ] ; then echo $pos $(ls $GSW/seasonality_acc/seasonality.vrt ) GSWs.tif | sed '/^$/d' ; fi
	if [ "$var2" = GSWr  ] ; then echo $pos $(ls $GSW/recurrence_acc/recurrence.vrt ) GSWr.tif | sed '/^$/d'   ; fi
	if [ "$var2" = GSWo  ] ; then echo $pos $(ls $GSW/occurrence_acc/occurrence.vrt ) GSWo.tif | sed '/^$/d'   ; fi
	if [ "$var2" = GSWe  ] ; then echo $pos $(ls $GSW/extent_acc/extent.vrt ) GSWe.tif | sed '/^$/d'            ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt 

##### hydrography  #### the cti has negative values.

for vrt in $( ls $HYDRO/hydrography90m_v.1.0/*/*/*.vrt | grep -v -e basin.vrt -e depression.vrt -e direction.vrt -e outlet.vrt -e regional_unit.vrt -e segment.vrt -e sub_catchment.vrt -e order_vect.vrt -e order_vect.vrt  -e channel -e order -e accumulation  )  ; do 
	name_imp=$(basename $vrt .vrt  )
	name_tif=$(grep ${name_imp}  $IMP_FILE )
	name_pos=$(grep -n ${name_imp}  $IMP_FILE | awk -F : '{print $1}'   )
	if [[ !  -z  $name_tif   ]] ;  then
		echo $name_pos $( ls  $HYDRO/hydrography90m_v.1.0/*/${name_tif}_tiles20d/${name_tif}.vrt 2> /dev/null )  ${name_tif}.tif   | sed '/^$/d'
	fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

##### positive accumulation

for var1 in accumulation ; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }')
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}')
	if [ "$var2" = accumulation  ] ; then echo $pos $(ls $HYDRO/flow_tiles/all_tif_pos_dis.vrt )  accumulation.tif  ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

###### elevation 

for var1 in ELEV ; do
	var2=$(grep $var1 $IMP_FILE | awk '{ print $1 }' )
	pos=$(grep -n $var1 $IMP_FILE | awk -F : '{print $1}' )
	if [ "$var2" = ELEV  ] ; then echo $pos $(ls $MERIT/input_tif/all_tif.vrt) ELEV.tif ; fi
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt

#### geomorpho 

for vrt in $( ls $MERIT/geomorphometry_90m_wgs84/*/all_*_90M.vrt | grep -v -e all_aspect_90M.vrt  -e all_cti_90M.vrt -e all_spi_90M.vrt  )  ; do
	name_imp=$(basename $vrt _90M.vrt | sed 's/all_//g' ) #  sed 's/-/_/g' 
	name_tif=$(grep ${name_imp}$  $IMP_FILE ) #  sed 's/_/-/g' 
	name_pos=$(grep -n ${name_imp}$  $IMP_FILE | awk -F : '{print $1}'   )
	# echo ${name_imp} ${name_tif}
	if [[ !  -z  $name_tif   ]] ;  then
		echo $name_pos $( ls  $MERIT/geomorphometry_90m_wgs84/${name_tif}/all_${name_tif}_90M.vrt  2> /dev/null )  ${name_tif}.tif   ;
	fi 
done >> $INTILE/${YYYY}_${MM}_${DA_TE}.txt





sort -k 1,1 -g $INTILE/${YYYY}_${MM}_${DATE}.txt |  awk '{print $2  }'     > $INTILE/${YYYY}_${MM}_${DATE}_s.txt

echo TILE $TILE DATE $DATE
gdalbuildvrt -overwrite -separate -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$TILE.tif) -input_file_list  $INTILES/${YYYY}_${MM}_${TILE}_s.txt   $INTILES/${YYYY}_${MM}_${TILE}.vrt


## new 0916

rm -r $INTILES/${DA_TE}_${TILE}
mkdir -p $INTILES/${DA_TE}_${TILE}
cat $INTILE/${YYYY}_${MM}_${DA_TE}.txt | xargs -n 3 -P 10 bash -c $'
file=$2
fileout=$3
export GDAL_CACHEMAX=10000
##  add for testing  -srcwin 0 0 5000 5000
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_$TILE.tif) $file $INTILES/${DA_TE}_${TILE}/$fileout
' _


##### pyjeo in apptainer  use 1.26.2 numpy   python Python 3.11.2    numpy 1.26.2 
##### conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts  python=3.11.2  numpy=1.26.2  scipy=1.11.4 pandas=2.1.3  matplotlib=3.8.2  scikit-learn dill 
##### to add packeg
##### conda activate env_gsi_ts 
##### conda install dill
# Stop script before module purge
#echo "Stopping script before module purge"
#exit 0  # This will stop the script from executing further




module purge
apptainer exec --env=PATH="/home/st929/pyjeovenv/bin:$PATH",DA_TE=$DA_TE,TILE=$TILE,INTILE=$INTILE,DA_TE=$DA_TE,YYYY=$YYYY,MM=$MM /home/st929/pyjeo2_modified.sif bash -c "

python3 -c \"
print('start python')
# Append paths for the required Python environment
import os
import sys
import glob
import pandas as pd
import numpy as np
#sys.path.append('/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python311.zip')
#sys.path.append('/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11')
#sys.path.append('/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/lib-dynload')
#sys.path.append('/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsi_ts/lib/python3.11/site-packages')
# Import necessary packages
from numpy import savetxt
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
import dill 
import pyjeo as pj
import joblib
print('module loaded')

# Load environment variables
DA_TE = os.environ['DA_TE']
TILE = os.environ['TILE']
INTILE = os.environ['INTILE']
INTILES = os.environ['INTILES']
YYYY = os.environ['YYYY']
YYYY = os.environ['YYYY']
MM = os.environ['MM']

# Print the environment variables to confirm they are loaded correctly
print(DA_TE)
print(TILE)
print(INTILE)

# Load the column names to load the tif in the same order
predictors_path = '/home/st929/project/predictors_used_feature_selection_Yearly_average.csv'

predictors = pd.read_csv(predictors_path, header=None)
# Extract the feature names from the predictors DataFrame

feature_names = predictors.iloc[:, 0].tolist()  # Assuming the first column contains the feature names
# Initialize list for stacking arrays

tif_arrays = []
# Iterate through the rows of the predictors DataFrame
predictors_no_year = predictors.drop(predictors.index[-1])  ## first remove last variable YYYY
# Loop through each row in the predictors DataFrame, excluding the 'YYYY' column
for index, row in predictors_no_year.iterrows():
	# Construct the tif_file name from the row (no need to exclude 'YYYY' as it's already dropped)
	tif_file = ' '.join(row.values.astype(str))  # Join the values as strings with space
	file_path = rf'{INTILES}/{YYYY}_{MM}_{TILE}/{tif_file}.tif'
	print(file_path)  # Optional: Print the file path for debugging
	# Load the TIFF file directly as a float64 numpy array
	tif_data = pj.Jim(file_path).np().astype(np.float64)
	# Append the TIFF data array to the list
	tif_arrays.append(tif_data)
	print('jim_loaded')

# Add the year layer after all TIFF files are loaded
year = int(YYYY)  # Convert the 'YYYY' environment variable to an integer
print('year', year)

# Assuming all TIFF files have the same shape as the first one
if tif_arrays:  # Ensure there's at least one TIFF loaded
	# Create a year layer filled with the year number (same dimensions as the first TIFF file)
	year_layer = np.full(tif_arrays[0].shape, year, dtype=np.float64)

	# Append the year layer to the list
	tif_arrays.append(year_layer)
	print('year_layer_added')
	# Create a year layer filled with the year number (same dimensions as the first TIFF file)

# Stack all the arrays along a new axis (e.g., axis 0 for a new dimension)
x = np.stack(tif_arrays, axis=0)
print(f'Dimensions of x: {x.shape}')
print(x[:5])

# Reshape the data
x_reshaped = x.reshape(len(tif_arrays), tif_arrays[0].shape[0] * tif_arrays[0].shape[1]).T
print(f'Dimensions of x_reshaped: {x_reshaped.shape}')


# Create an empty image with a single plane
jim_flow = pj.Jim(ncol=tif_arrays[0].shape[1], nrow=tif_arrays[0].shape[0], otype='GDT_Float32')

# Load the mask
msk = pj.Jim(rf'/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk_10d/msk_{TILE}.tif')
jim_flow.properties.copyGeoReference(msk)



# Load the RF model
RFreg = joblib.load('/home/st929/project/featureselection_model_Yearly_average.pkl')

# Perform prediction on the reshaped input array
predictions = RFreg.predict(x_reshaped).astype(np.float32)
reshaped_predictions = predictions.reshape(tif_arrays[0].shape[0], tif_arrays[0].shape[1])

# Assign the reshaped predictions to jim_flow
jim_flow.np()[:] = reshaped_predictions
# Write the single-band output to a TIFF file
jim_flow.io.write(rf'/gpfs/gibbs/pi/hydro/st929/output_tile/ALK_{YYYY}_{MM}_{TILE}.tif', co=['COMPRESS=LZW', 'TILED=YES', 'BIGTIFF=YES'])
print(f'File written: ALK_{YYYY}_{MM}_{TILE}.tif')
\"
"
### validation
echo "Stopping script before validation"
exit 0
