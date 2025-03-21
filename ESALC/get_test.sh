#!/bin/bash

### module load miniconda
### conda create -n esaenv python=2.7

module load miniconda

source activate esaenv


## --- folder where the API scripts are located
#DIRAPI=$HOME/Code/GLOWABIO/DataPreparation/ESALC/
DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/

## folder to download and extract the data
#export DIRLC=$HOME/Data/ESALC 
export DIRLC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/ 
cd $DIRLC

# Download can be applied with the ESA API, following the following script files: (only a maximum of 10 files can be downloaded at a time!)
python $DIRAPI/ESAdownload_92_01.py

exit
python $DIRAPI/ESAdownload_02_11.py
python $DIRAPI/ESAdownload_12_18.py

#--------
# ALternative way to download ESA data
# GLobal land cover maps 1992 - 2015
# wget -- link to download LC maps full 1992-2015 serie as a netcdf file
#ftp://geo10.elie.ucl.ac.be/v207/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7b.nc.zip
#------------

# Extract files
tar -xzvf $DIRLC/download_92_01.tar.gz $DIRLC
tar -xzvf $DIRLC/download_22_11.tar.gz $DIRLC
tar -xzvf $DIRLC/download_12_18.tar.gz $DIRLC
