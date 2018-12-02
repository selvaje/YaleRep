
# 
# username: esacci_sm_v042
# password: Sk8CpRbcolod


# Protocol: SFTP
# LogonType: Normal
# Server: ftp.geo.tuwien.ac.at
# Port: 22

# guide at http://esa-soilmoisture-cci.org/sites/default/files/documents/M6/ESA_CCI_SM_PSD_D1.2.1_version_4.2.pdf 

cd /project/fas/sbsc/ga254/dataproces/SOILMOIST
sftp   esacci_sm_v042@ftp.geo.tuwien.ac.at:/_down/alldata_7zip_compressed/ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED_1978-2016-v04.2.zip .

unzip ESACCI-SOILMOISTURE-L3S-SSMV-COMBINED_1978-2016-v04.2.zip 
