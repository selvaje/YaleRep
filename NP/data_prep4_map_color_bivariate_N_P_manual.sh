
# aggregate to 10k 
pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9 -nodata -1 -f mean  -d 10 -dy 10  -dx 10 -i  ${dirUS}/${croppedfig} -o ${dirUS}/${filtered10k}.tif

# filling the white spots

#change all the value > 0 to 1 and the -1 = 0 
pkgetmask -min 0 -max 100000 -i  ${dirUS}/${filtered10k}.tif -o   ${dirUS}/${filtered10k}_bin.tif

#clumping identify uniq poligons and give an id 
oft-clump -i ${dirUS}/${filtered10k}_bin.tif  -o ${dirUS}/${filtered10k}_clump.tif 

#get the histogram 
 pkstat --hist -i   ${dirUS}/${filtered10k}_clump.tif  >  ${dirUS}/${filtered10k}_clump.dat

#assign for each pixel id the number of pixel per pologon 
pkreclass -code  ${dirUS}/${filtered10k}_clump.dat  -i  ${dirUS}/${filtered10k}_clump.tif  -o  ${dirUS}/${filtered10k}_clump_size.tif

#set all the poligons with > less then 3 to 0 and more than 3 to 1 
pkgetmask -min 0 -max 3.5  -data 0 -nodata 1 -i   ${dirUS}/${filtered10k}_clump_size.tif  -o ${dirUS}/${filtered10k}_clump_tofill.tif

#use the o value to interpolate. All the areas smaller than 3 pixels will be fill in
 pkfillnodata  -m  ${dirUS}/${filtered10k}_clump_tofill.tif -d 3   -i  ${dirUS}/${filtered10k}.tif  -o  ${dirUS}/${filtered10k}_clump_filled.tif

# feeding the 10k tif to the bivariate code
