#!/bin/bash

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/MNP/sc01_wget_mnp.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/MNP/


DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MNP
cd $DIR

# Total manure nitrogen production in kg N/km**2/yr
wget http://hs.pangaea.de/model/ManNitPro/ManNitPro.zip
unzip -f ManNitPro.zip

# Manure nitrogen applied to cropland and rangeland in kg N/km**2/yr
#wget http://hs.pangaea.de/model/ManNitPro/ManNitProCrpRd.zip
