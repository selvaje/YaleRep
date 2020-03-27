cd /gpfs/loomis/home.grace/sbsc/ga254/src/OpenForisToolkit-1.25.8

source ~/bin/gdal
source ~/bin/pktools


EXE_path=/gpfs/loomis/home.grace/sbsc/ga254/bin

libgsl=`gsl-config --libs`
gslflags=`gsl-config --cflags`
libgdal=`gdal-config --libs`
gdalflags=`gdal-config --cflags`

echo "Installing new versions of additional c and python libs"\

for file in lib/c/*.c ; do 
    name=$(basename $file .c)
    gcc --shared -o $EXE_path/$name".so" $file 
done


echo "Installing new versions of executables"



for file in c/*.c ; do 

    echo $file

    name=`basename $file .c`

    # echo gcc -o $EXE_path/$name $file $gdalflags $libgdal $gslflags $libgsl 

    gcc  -o $EXE_path/$name $file $gdalflags $libgdal $gslflags $libgsl  

done 

# wget http://foris.fao.org/static/geospatialtoolkit/releases/OpenForisToolkit.run
