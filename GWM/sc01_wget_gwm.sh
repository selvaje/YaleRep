#!/bin/bash

####  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GWM/sc01_wget_gwm.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GWM

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GWM
cd $DIR

wget http://hs.pangaea.de/Maps/TootchifatidehiA-etal_2018/TIFF.zip  ####   15.05.2020
unzip TIFF.zip
mv TIFF/FWD .
mv TIFF/CW-TCI .
mv TIFF/CW-WTD .
rm -r TIFF
