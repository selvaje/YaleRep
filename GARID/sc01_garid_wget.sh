## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GARID/sc01_garid_wget.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GARID


######    UPDATE  #####################################
######            #####################################

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GARID
cd $DIR

## Global Aridity Index (Global-Aridity_ET0)
## AI annual
wget https://ndownloader.figshare.com/files/14118800
unzip 14118800
