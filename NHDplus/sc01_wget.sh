# bsub -W 24:00  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc01_wget.sh

# code interpretation 
# http://nhd.usgs.gov/userGuide/Robohelpfiles/NHD_User_Guide/Feature_Catalog/Hydrography_Dataset/Complete_FCode_List.html 
# http://nhd.usgs.gov/NHDv2.2_poster_052714.pdf 
# cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/NHD/zip
# wget ftp://rockyftp.cr.usgs.gov/vdelivery/Datasets/Staged/Hydrography/NHD/State/HighResolution/Shape/NHD_H_*_Shape.zip

# download nhdplus database 

cd /project/fas/sbsc/ga254/dataproces/NHDplus/download 

# echo download the shape file 

# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCI/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusGB/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusGL/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusHI/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMA/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusNE/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPN/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusRG/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSR/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusTX/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusXML/NHDPlusV21_*_*_NHDSnapshot_*.7z

# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCO/NHDPlus14/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCO/NHDPlus15/NHDPlusV21_*_*_NHDSnapshot_*.7z

# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus05//NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus06/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus07/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus08/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus10L/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus10U/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus11/NHDPlusV21_*_*_NHDSnapshot_*.7z

# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22AS/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22GU/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22MP/NHDPlusV21_*_*_NHDSnapshot_*.7z


# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03N/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03S/NHDPlusV21_*_*_NHDSnapshot_*.7z
# wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03W/NHDPlusV21_*_*_NHDSnapshot_*.7z

echo download the attribute 

wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCA/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCI/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusGB/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusGL/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusHI/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMA/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusNE/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPN/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusRG/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSR/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusTX/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusXML/NHDPlusV21_*_*_NHDPlusAttributes_*.7z

wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCO/NHDPlus14/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusCO/NHDPlus15/NHDPlusV21_*_*_NHDPlusAttributes_*.7z

wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus05//NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus06/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus07/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus08/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus10L/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus10U/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusMS/NHDPlus11/NHDPlusV21_*_*_NHDPlusAttributes_*.7z

wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22AS/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22GU/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusPI/NHDPlus22MP/NHDPlusV21_*_*_NHDPlusAttributes_*.7z

wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03N/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03S/NHDPlusV21_*_*_NHDPlusAttributes_*.7z
wget ftp://www.horizon-systems.com/NHDPlus/NHDPlusV21/Data/NHDPlusSA/NHDPlus03W/NHDPlusV21_*_*_NHDPlusAttributes_*.7z

