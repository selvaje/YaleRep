cd /lustre0/scratch/ga254/dem_bj/SOLAR/validation/uoregon/MonthCUM

for file in *GHI*.txt ; do 
filename=`basename $file .txt`
echo $filename $(awk '{if (NR>9 && NR<22 ) printf ("%i " ,  $NF )}' $file)
done > code_ghi.txt

for file in *DHI*.txt ; do 
filename=`basename $file .txt`
echo $filename $(awk '{if (NR>9 && NR<22 ) printf ("%i " ,  $NF )}' $file)
done > code_dhi.txt

for file in *DNI*.txt ; do 
filename=`basename $file .txt`
echo $filename $(awk '{if (NR>9 && NR<22 ) printf ("%i " ,  $NF )}' $file)
done > code_dni.txt




