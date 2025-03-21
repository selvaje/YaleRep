#!/bin/bash
#SBATCH -p day                                                                                                             
#SBATCH -n 1 -c 1 -N 1                                                                                                     
#SBATCH -t 00:30:00                                                                                                     
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_ESA_LC_wget.sh.%A_%a.out                            
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_ESA_LC_wget.sh.%A_%a.err                            


####  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc01_ESA_LC_wget.sh


#--- folder where the API scripts are located
DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ESALC

## folder to download and extract the data
export DIRLC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
cd $DIRLC

# Download can be applied with the ESA API, following the following script files: (only a maximum of 10 files can be downloaded at a time!)

# Here are the instructions to install the CDS API: https://cds.climate.copernicus.eu/api-how-to

# python $DIRAPI/ESAdownload_92_01.py
# python $DIRAPI/ESAdownload_02_11.py
python $DIRAPI/ESAdownload_12_18.py

#--------
# ALternative way to download ESA data
# GLobal land cover maps 1992 - 2015
# wget -- link to download LC maps full 1992-2015 serie as a netcdf file
#ftp://geo10.elie.ucl.ac.be/v207/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7b.nc.zip
#------------

# Extract files
# tar -xzvf $DIRLC/download_92_01.tar.gz $DIRLC
# tar -xzvf $DIRLC/download_22_11.tar.gz $DIRLC
tar -xzvf $DIRLC/download_12_18.tar.gz $DIRLC

