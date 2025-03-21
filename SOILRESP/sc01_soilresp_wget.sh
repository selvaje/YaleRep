## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/SOILRESP/sc01_soilresp_wget.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILRESP

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILRESP
cd $DIR

wget http://cse.ffpri.affrc.go.jp/shojih/data/files/RS_mon_Hashimoto2015.nc
