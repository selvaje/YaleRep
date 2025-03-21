#!/bin/bash

# copy to grace
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/SOILMOIST/sc01_wget_esasoil.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILMOIST



#User: esacci_sm_v047
#Password: zN1xr3apWhEE

#Protocol: SFTP
#LogonType: Normal
#Server: ftp.geo.tuwien.ac.at
#Port: 22

#Directory: _down

# guide at http://esa-soilmoisture-cci.org/sites/default/files/documents/M6/ESA_CCI_SM_PSD_D1.2.1_version_4.2.pdf

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILMOIST

sftp  esacci_sm_v047@ftp.geo.tuwien.ac.at:/_down/3_alldata_7zip_compressed/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED_1978-2019-v04.7.zip .

unzip ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED_1978-2019-v04.7.zip 
