# cd  /mnt/data2/scratch/GMTED2010/grassdb 
# ls  /mnt/data2/scratch/GMTED2010/tiles/mn75_grd_tif/?_?.tif  | xargs -n 1  -P 10  bash /mnt/data2/scratch/GMTED2010/scripts/sc2_real-sky-horiz-solar_Monthradiation.sh
# ls  /mnt/data2/scratch/GMTED2010/tiles/mn75_grd_tif/{1_1,1_2,2_1,2_2,1_0,2_0}.tif  | xargs -n 1  -P 10  bash /mnt/data2/scratch/GMTED2010/scripts/sc2_real-sky-horiz-solar_Monthradiation.sh

# alaska and maine 
# ls  /mnt/data2/scratch/GMTED2010/tiles/mn75_grd_tif/{0_0,3_1}.tif  | xargs -n 1  -P 10  bash /mnt/data2/scratch/GMTED2010/scripts/sc2_real-sky-horiz-solar_Monthradiation.sh
# ls  /mnt/data2/scratch/GMTED2010/tiles/mn75_grd_tif/2_1.tif  | xargs -n 1  -P 10  bash /mnt/data2/scratch/GMTED2010/scripts/sc2_real-sky-horiz-solar_Monthradiation.sh
# ls  /mnt/data2/scratch/GMTED2010/tiles/mn75_grd_tif/2_2.tif  | xargs -n 1  -P 10  bash /mnt/data2/scratch/GMTED2010/scripts/sc2_real-sky-horiz-solar_Monthradiation.sh


# for tile  in  /lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/be75_grd_tif/{0_0,3_1,1_1,1_2,2_1,2_2,1_0,2_0}.tif  ; do  qsub -v tile=$tile /home/fas/sbsc/ga254/scripts/gmted2010_rad/scripts_r_sun_om/sc1_Monthradiation_bj.sh  ; done 

# for tile  in /lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/be75_grd_tif/3_1.tif  ; do  bash   /home/fas/sbsc/ga254/scripts/gmted2010_rad/scripts_r_sun_om/sc1_Monthradiation_bj.sh  $tile ; done 

# un tile ha impiegato 6 ore

#PBS -S /bin/bash 
#PBS -q fas_long
#PBS -l walltime=10:00:00  
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o  /scratch/fas/sbsc/ga254/stdout 
#PBS -e  /scratch/fas/sbsc/ga254/stderr

# tile=$1

file=`basename $tile`

export file=`basename $tile`
export filename=`basename $file .tif`

export INTIF_mn30=/lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/mn30_grd_tif
export INTIF=/lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/be75_grd_tif
export INTIFL=/lustre/scratch/client/fas/sbsc/ga254/dataproces/GMTED2010/tiles/
export INDIRG=/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/grassdb
export OUTDIR=/lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/radiation


echo clip the data 

cd $INDIRG 

# clip the 1km dem, use the be75_grd_tif to ensure larger overlap

gdal_translate -projwin  $(getCorners4Gtranslate  $INTIF/$file) $INTIF_mn30/mn30_grd.tif $file

# gdal_translate -srcwin 9000 4200 50 50  $INTIF_mn30/mn30_grd.tif $file  # to create a file test 


echo create location  loc_$filename 


mkdir -p  $INDIRG/loc_tmp/tmp

echo "LOCATION_NAME: loc_tmp"                                                       > $HOME/.grass7/rc_$filename
echo "GISDBASE: /lustre/scratch/client/fas/sbsc/ga254/dataproces/SOLAR/grassdb"    >> $HOME/.grass7/rc_$filename
echo "MAPSET: tmp"                                                                 >> $HOME/.grass7/rc_$filename
echo "GRASS_GUI: text"                                                             >> $HOME/.grass7/rc_$filename


# path to GRASS settings file
export GISRC=$HOME/.grass7/rc_$filename
export GRASS_PYTHON=python
export GRASS_MESSAGE_FORMAT=plain
export GRASS_PAGER=cat
export GRASS_WISH=wish
export GRASS_ADDON_BASE=$HOME/.grass7/addons
export GRASS_VERSION=7.0.0beta1
export GISBASE=/usr/local/cluster/hpc/Apps/GRASS/7.0.0beta1/grass-7.0.0beta1
export GRASS_PROJSHARE=/usr/local/cluster/hpc/Libs/PROJ/4.8.0/share/proj/
export PROJ_DIR=/usr/local/cluster/hpc/Libs/PROJ/4.8.0

export PATH="$GISBASE/bin:$GISBASE/scripts:$PATH"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$GISBASE/lib"
export GRASS_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export PYTHONPATH="$GISBASE/etc/python:$PYTHONPATH"
export MANPATH=$MANPATH:$GISBASE/man
export GIS_LOCK=$$
export GRASS_OVERWRITE=1

rm -rf  $INDIRG/loc_$filename

echo start importing 
r.in.gdal in=$file  out=$filename  location=loc_$filename

g.mapset mapset=PERMANENT  location=loc_$filename

echo import and set the mask 
r.external  -o input=/lustre/scratch/client/fas/sbsc/ga254/dataproces/GSHHG/GSHHS_tif_1km/land_mask_GSHHS_f_L1.tif output=mask  --overwrite  
r.mask raster=mask

echo calculate r.slope.aspect  
r.slope.aspect elevation=$filename    aspect=aspect_$filename  slope=slope_$filename   # for horizontal surface not usefull

echo calculate horizon

# step 1 in r.sun = horizonstep=15   360/24 = 15 

r.horizon  elevin=$filename   horizonstep=15  horizon=horiz   maxdistance=200000

echo  001 017 033 049 065 081 097 113 129 145 161 177 193 209 225 241 257 273 289 305 321 337 353  | xargs -n 1  -P 8  bash  -c $'

dayi=$1
day=$(echo $dayi | awk \'{ print int($1) }\'  ) #   to have the integer value 

echo  processing day $dayi "#################################################################"

# the albedo influence only the reflectance radiation 
echo  import albedo 
r.external  -o input=/lustre/scratch/client/fas/sbsc/ga254/dataproces/MODALB/0.3_5.0.um.00-04.WS.c004.v2.0/AlbMap.WS.c004.v2.0.00-04.${dayi}.0.3_5.0.tif   output=albedo${day}_${filename} --overwrite 
r.mapcalc  " albedo${day}_${filename}_coef =  albedo${day}_${filename}  * 0.001" 

echo  import cloud
# for this case import the same tif  for the full month
# coef_bh 1 no cloud 0 full cloud 
monthc=$( awk -v day=$day \'{ if ($2==day) {print substr($1,0,2) } }\'  /lustre/scratch/client/fas/sbsc/ga254/dataproces/MERRAero/tif_day/MMDD_JD_0JD.txt  ) 

r.external -o input=/lustre/scratch/client/fas/sbsc/ga254/dataproces/CLOUD/month/MCD09_mean_${monthc}.tif   output=cloud${day}_${filename}  --overwrite 
r.mapcalc  " cloud${day}_${filename}_coef = 1 -  ( cloud${day}_${filename} * 0.0001)" 

echo import Aerosol 
# coef_dh 1 no Aerosol 0 full Aerosol  
r.external -o input=/lustre/scratch/client/fas/sbsc/ga254/dataproces/AE_C6_MYD04_L2/temp_smoth_1km/AOD_1km_day${day}.tif  output=aeros${day}_${filename}  --overwrite 

# see http://en.wikipedia.org/wiki/Optical_depth 
# 2.718281828^$B!](B(5000/1000) = 0.006737947
# 2.718281828^$B!](B($B!](B50/1000) = 1.051271096 
# the animation formula is the following 1 - (  2.718281828^(- (aeros${day}_${filename} * 0.001))) "
# for the coef_df take out -1 

r.mapcalc " aeros${day}_${filename}_coef =   (  2.718281828^(- (aeros${day}_${filename} * 0.001))) "

# horizontal clear sky 
# take out aspin=aspect_$filename  slopein=slope_$filename to simulate horizontal behaviur    better specify the slope=0 
# in case of horizontal behaviur the reflectance is = 0 
# also the albedo dose not influence the  global radiation . Better say the albedo influence only the reflectance radiation and it isualy a very small value - between 0 and 1 -  for the horizontal surface 
# in case of not horizontal surface the reflectance paly an important role. 
# indead the glob_HradT_day${day}_month${monthc} = glob_HraAl_day${day}_month${monthc}


# make anonther test with inclined surface

# horizontal aerosl and cloud and albedo 

# transparent = T

r.sun  --o   elev_in=$filename  slope=0.01 \
lin=1   \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradT_day${day}_month${monthc} \
diff_rad=diff_HradT_day${day}_month${monthc} \
beam_rad=beam_HradT_day${day}_month${monthc} \
refl_rad=refl_HradT_day${day}_month${monthc}     # orizontal 0 reflectance 

# albedo - Al

r.sun  --o   elev_in=$filename   slope=0.01  \
lin=1   albedo=albedo${day}_${filename}_coef   \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradAl_day${day}_month${monthc} \
diff_rad=diff_HradAl_day${day}_month${monthc} \
beam_rad=beam_HradAl_day${day}_month${monthc} \
refl_rad=refl_HradAl_day${day}_month${monthc}     # orizontal 0 reflectance 

# ALBEDO CLOUD AEROSOL

r.sun  --o   elev_in=$filename    slope=0.01    \
lin=1   albedo=albedo${day}_${filename}_coef   coef_bh=cloud${day}_${filename}_coef  coef_dh=aeros${day}_${filename}_coef \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradACA_day${day}_month${monthc} \
diff_rad=diff_HradACA_day${day}_month${monthc} \
beam_rad=beam_HradACA_day${day}_month${monthc} \
refl_rad=refl_HradACA_day${day}_month${monthc}     # orizontal 0 reflectance 

# CLOUD AOD 

r.sun  --o   elev_in=$filename    slope=0.01    \
lin=1     coef_bh=cloud${day}_${filename}_coef  coef_dh=aeros${day}_${filename}_coef \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradCA_day${day}_month${monthc} \
diff_rad=diff_HradCA_day${day}_month${monthc} \
beam_rad=beam_HradCA_day${day}_month${monthc} \
refl_rad=refl_HradCA_day${day}_month${monthc}     # orizontal 0 reflectance 

# CLOUD 

r.sun  --o   elev_in=$filename    slope=0.01    \
lin=1   coef_bh=cloud${day}_${filename}_coef \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradC_day${day}_month${monthc} \
diff_rad=diff_HradC_day${day}_month${monthc} \
beam_rad=beam_HradC_day${day}_month${monthc} \
refl_rad=refl_HradC_day${day}_month${monthc}     # orizontal 0 reflectance 

# AOD

r.sun  --o   elev_in=$filename    slope=0.01     \
lin=1  coef_dh=aeros${day}_${filename}_coef \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_HradA_day${day}_month${monthc} \
diff_rad=diff_HradA_day${day}_month${monthc} \
beam_rad=beam_HradA_day${day}_month${monthc} \
refl_rad=refl_HradA_day${day}_month${monthc}     # orizontal 0 reflectance 



# ALBEDO CLOUD AEROSOL not horizontal 

r.sun  --o   elev_in=$filename     asp_in=aspect_$filename  slope_in=slope_$filename      \
lin=1   albedo=albedo${day}_${filename}_coef   coef_bh=cloud${day}_${filename}_coef  coef_dh=aeros${day}_${filename}_coef \
day=$day step=1 horizon=horiz  horizonstep=15   --overwrite  \
glob_rad=glob_radACA_day${day}_month${monthc} \
diff_rad=diff_radACA_day${day}_month${monthc} \
beam_rad=beam_radACA_day${day}_month${monthc} \
refl_rad=refl_radACA_day${day}_month${monthc}     # orizontal 0 reflectance 

g.mremove -f  rast=albedo${day}_${filename}_coef,cloud${day}_${filename}_coef,aeros${day}_${filename}_coef

' _

echo starting to calculate average at montly level

echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs  -n 1   -P 12  bash -c  $'  

month=$1

echo mean compupation aerosol and cloud and albedo  

for INPUT in T Al ACA CA C A ; do 

r.series input=$(g.mlist rast pattern="glob_Hrad${INPUT}_day*_month${month}" sep=,)   output=tglob_Hrad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="diff_Hrad${INPUT}_day*_month${month}" sep=,)   output=tdiff_Hrad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="beam_Hrad${INPUT}_day*_month${month}" sep=,)   output=tbeam_Hrad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="refl_Hrad${INPUT}_day*_month${month}" sep=,)   output=trefl_Hrad${INPUT}_m$month   method=average  --overwrite 

r.mapcalc   "glob_Hrad${INPUT}_m$month  = float (  tglob_Hrad${INPUT}_m$month )"
r.mapcalc   "diff_Hrad${INPUT}_m$month  = float (  tdiff_Hrad${INPUT}_m$month )"
r.mapcalc   "beam_Hrad${INPUT}_m$month  = float (  tbeam_Hrad${INPUT}_m$month )"
r.mapcalc   "refl_Hrad${INPUT}_m$month  = float (  trefl_Hrad${INPUT}_m$month )"

g.remove rast=tglob_Hrad${INPUT}_m$month
g.remove rast=tdiff_Hrad${INPUT}_m$month
g.remove rast=tbeam_Hrad${INPUT}_m$month
g.remove rast=trefl_Hrad${INPUT}_m$month

r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=glob_Hrad${INPUT}_m$month    output=$OUTDIR/glob_Hrad/glob_Hrad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=diff_Hrad${INPUT}_m$month    output=$OUTDIR/diff_Hrad/diff_Hrad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=beam_Hrad${INPUT}_m$month    output=$OUTDIR/beam_Hrad/beam_Hrad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=refl_Hrad${INPUT}_m$month    output=$OUTDIR/refl_Hrad/refl_Hrad${INPUT}_month$month"_"$file


if [ ${filename:0:1} -eq 0 ] ; then 
# this was inserted becouse the r.out.gdal of the 0_? was overpassing the -180 border and it was attach the tile to the right border 

# aerosol and cloud

gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/glob_Hrad/glob_Hrad${INPUT}_month$month"_"$file  $OUTDIR/glob_Hrad/glob_Hrad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/diff_Hrad/diff_Hrad${INPUT}_month$month"_"$file  $OUTDIR/diff_Hrad/diff_Hrad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/beam_Hrad/beam_Hrad${INPUT}_month$month"_"$file  $OUTDIR/beam_Hrad/beam_Hrad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/refl_Hrad/refl_Hrad${INPUT}_month$month"_"$file  $OUTDIR/refl_Hrad/refl_Hrad${INPUT}_month$month"_"$file"_tmp"

mv $OUTDIR/glob_Hrad/glob_Hrad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/glob_Hrad/glob_Hrad${INPUT}_month$month"_"$file
mv $OUTDIR/diff_Hrad/diff_Hrad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/diff_Hrad/diff_Hrad${INPUT}_month$month"_"$file
mv $OUTDIR/beam_Hrad/beam_Hrad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/beam_Hrad/beam_Hrad${INPUT}_month$month"_"$file
mv $OUTDIR/refl_Hrad/refl_Hrad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/refl_Hrad/refl_Hrad${INPUT}_month$month"_"$file

fi

g.mremove -f  "glob_Hrad${INPUT}_day*_month*"
g.mremove -f  "diff_Hrad${INPUT}_day*_month*"
g.mremove -f  "beam_Hrad${INPUT}_day*_month*"
g.mremove -f  "refl_Hrad${INPUT}_day*_month*"

done 

# only of the no horizontal 

for INPUT in ACA ; do 

r.series input=$(g.mlist rast pattern="glob_rad${INPUT}_day*_month${month}" sep=,)  output=tglob_rad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="diff_rad${INPUT}_day*_month${month}" sep=,)   output=tdiff_rad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="beam_rad${INPUT}_day*_month${month}" sep=,)   output=tbeam_rad${INPUT}_m$month   method=average  --overwrite 
r.series input=$(g.mlist rast pattern="refl_rad${INPUT}_day*_month${month}" sep=,)   output=trefl_rad${INPUT}_m$month   method=average  --overwrite 

r.mapcalc   "glob_rad${INPUT}_m$month  = float (  tglob_rad${INPUT}_m$month )"
r.mapcalc   "diff_rad${INPUT}_m$month  = float (  tdiff_rad${INPUT}_m$month )"
r.mapcalc   "beam_rad${INPUT}_m$month  = float (  tbeam_rad${INPUT}_m$month )"
r.mapcalc   "refl_rad${INPUT}_m$month  = float (  trefl_rad${INPUT}_m$month )"

g.remove rast=tglob_rad${INPUT}_m$month
g.remove rast=tdiff_rad${INPUT}_m$month
g.remove rast=tbeam_rad${INPUT}_m$month
g.remove rast=trefl_rad${INPUT}_m$month

r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=glob_rad${INPUT}_m$month    output=$OUTDIR/glob_rad/glob_rad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=diff_rad${INPUT}_m$month    output=$OUTDIR/diff_rad/diff_rad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=beam_rad${INPUT}_m$month    output=$OUTDIR/beam_rad/beam_rad${INPUT}_month$month"_"$file
r.out.gdal -c type=Float32  nodata=-1  createopt="COMPRESS=LZW,ZLEVEL=9"  input=refl_rad${INPUT}_m$month    output=$OUTDIR/refl_rad/refl_rad${INPUT}_month$month"_"$file


if [ ${filename:0:1} -eq 0 ] ; then 
# this was inserted becouse the r.out.gdal of the 0_? was overpassing the -180 border and it was attach the tile to the right border 

# aerosol and cloud

gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/glob_rad/glob_rad${INPUT}_month$month"_"$file  $OUTDIR/glob_rad/glob_rad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/diff_rad/diff_rad${INPUT}_month$month"_"$file  $OUTDIR/diff_rad/diff_rad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/beam_rad/beam_rad${INPUT}_month$month"_"$file  $OUTDIR/beam_rad/beam_rad${INPUT}_month$month"_"$file"_tmp"
gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_ullr   $(getCorners4Gtranslate $INTIF/$file)  $OUTDIR/refl_rad/refl_rad${INPUT}_month$month"_"$file  $OUTDIR/refl_rad/refl_rad${INPUT}_month$month"_"$file"_tmp"

mv $OUTDIR/glob_rad/glob_rad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/glob_rad/glob_rad${INPUT}_month$month"_"$file
mv $OUTDIR/diff_rad/diff_rad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/diff_rad/diff_rad${INPUT}_month$month"_"$file
mv $OUTDIR/beam_rad/beam_rad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/beam_rad/beam_rad${INPUT}_month$month"_"$file
mv $OUTDIR/refl_rad/refl_rad${INPUT}_month$month"_"$file"_tmp" $OUTDIR/refl_rad/refl_rad${INPUT}_month$month"_"$file

fi

g.mremove -f  "glob_rad${INPUT}_day*_month*"
g.mremove -f  "diff_rad${INPUT}_day*_month*"
g.mremove -f  "beam_rad${INPUT}_day*_month*"
g.mremove -f  "refl_rad${INPUT}_day*_month*"

done 


' _ 


checkjob -v $PBS_JOBID

exit 






