## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GEVAPT/sc01_gevapt_wget.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GEVAPT


## wget https://ndownloader.figshare.com/files/13901324

##  wget does not work. Download was done manualy and copied to GRACE:

#Global Reference Evapo-Transpiration (Global-ET0)
## EPT annual
## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/data/GEVAPT/global-et0_annual.tif.zip   jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GEVAPT

#Global Reference Evapo-Transpiration (Global-ET0)
## EPT monthly
## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/data/GEVAPT/global-et0_monthly.tif.zip   jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GEVAPT

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEVAPT
cd $DIR

####    ANNUAL

unzip global-et0_annual.tif.zip

####     MONTHLY

unzip global-et0_monthly.tif.zip
