

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/download


wget https://download.scidb.cn/download?fileId=78439f9e0d497ecf0ea2bc2b45abd1aa -O IndexSpecific.rar
wget https://download.scidb.cn/download?fileId=ef2f26c78a31dac1779973b099c33e8f -O LocationSpecific.rar
wget https://download.scidb.cn/download?fileId=4b7487957460b900348e94e8363ca12e -O StreamflowIndicesTimeSeries.mat
wget https://download.scidb.cn/download?fileId=4790bc32d2289e5c3b4fa6b706a50afd -O CoverageofStations.pdf
wget https://download.scidb.cn/download?fileId=4ba16a699f30d62f792d1763ae4a0dfa -O Readme.txt
wget https://download.scidb.cn/download?fileId=c63419699db1ce06d0193820d55d58be -O Statistics.xlsx
wget https://download.scidb.cn/download?fileId=ac7c495546ee5ca9308e2af8feafeae7 -O station_catalogue.csv

rm StreamflowIndicesTimeSeries.mat
mv IndexSpecific.rar csv
mv LocationSpecific.rar csv

mv Readme.txt  meta 
mv Statistics.xlsx    meta 
mv station_catalogue.csv meta

#### see https://unix.stackexchange.com/questions/690575/extract-rar-file-on-centos-7

wget https://www.rarlab.com/rar/rarlinux-x64-624.tar.gz
tar xzvf rarlinux-x64-624.tar.gz

./rar/unrar x  IndexSpecific.rar

./rar/unrar e  LocationSpecific.rar  LocationSpecific





