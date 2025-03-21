#!/bin/bash

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/HydroLAKES/sc01_wget_hydroLakes.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

wget https://97dc600d3ccc765f840c-d5a4231de41cd7a15e06ac00b0bcc552.ssl.cf5.rackcdn.com/HydroLAKES_polys_v10_shp.zip

unzip HydroLAKES_polys_v10_shp.zip
