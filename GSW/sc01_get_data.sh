#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_get_data.%J.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_get_data.%J.err

ulimit -c 0

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc01_get_data.sh   


# module load miniconda
# conda create -n minconda_env python requests

# conda activate minconda_env

# python  /project/fas/sbsc/hydro/scripts/GSW/downloadWaterData_PythonV3.py  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/occurrence_download  occurrence  
# python  /project/fas/sbsc/hydro/scripts/GSW/downloadWaterData_PythonV3.py  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/change_download      change
# python  /project/fas/sbsc/hydro/scripts/GSW/downloadWaterData_PythonV3.py  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/extent_download      extent
# python  /project/fas/sbsc/hydro/scripts/GSW/downloadWaterData_PythonV3.py  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/recurrence_download  recurrence
# python  /project/fas/sbsc/hydro/scripts/GSW/downloadWaterData_PythonV3.py  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/seasonality_download seasonality

# conda deactivate
source ~/bin/gdal3

for dir in change transitions extent  occurrence  recurrence seasonality ; do 
export dir=$dir

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/${dir}_download 

wget -nd  -r -A .tif https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GSWE/Aggregated/LATEST/${dir}/tiles

ls /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input/${dir}_download/*.tif | xargs -n 1 -P 4 bash -c $'

gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 $1 $1.new 
mv   ${1}.new ${1}
' _

done 
