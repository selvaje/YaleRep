#!/usr/bin/env python

################################################################

# calculate  unique combination between values in 2 tif  
# useful fol accuracy matrix or category  maps comparison

try:
    from osgeo import gdal
    from osgeo.gdalconst import *
    gdal.TermProgress = gdal.TermProgress_nocb
except ImportError:
    import gdal
    from gdalconst import *

import numpy  as  np

import sys

from time import clock, time


# =============================================================================
def Usage():
    print('Usage: count_unique.py [-input1_no_data nodata_value] [-input2_no_data nodata_value]')
    print('                       input1.tif input2.tif output.txt')
    print('')
    sys.exit( 1 )

# =============================================================================

# =============================================================================
# 	Mainline
# =============================================================================

src_input1 = None
src_input2 = None
dst_file = None

input1_no_data = None 
input2_no_data = None

gdal.AllRegister()
argv = gdal.GeneralCmdLineProcessor(sys.argv)
if argv is None:
    sys.exit( 0 )

# Parse command line arguments.
i = 1
while i < len(argv):
    arg = argv[i]
    if arg == '-input1_no_data':
        input1_no_data = (int(argv[i+1]))
        i = i + 1
    elif arg == '-input2_no_data':
        input2_no_data = (int(argv[i+1]))
        i = i + 1
    elif src_input1 is None:
        src_input1 = arg
    elif src_input2 is None:
        src_input2 = arg
    elif dst_file is None:
        dst_file = arg
    else:
        Usage()
    i = i + 1

if  src_input1 is None:
        Usage()

if  src_input2 is None:
        Usage()

if  dst_file is None:
        Usage()

# register all of the GDAL drivers
gdal.AllRegister()

# Open source files. 
dsInput1 = gdal.Open( src_input1  )
if dsInput1 is None:
    print('Could not open %s.' % src_input1 )
    sys.exit( 1 )

dsInput2 = gdal.Open( src_input2  )
if  dsInput2 is None:
    print('Could not open %s.' % src_input2 )
    sys.exit( 1 )

# setting the no data if is user defined or geotif defined
if input1_no_data == None: 
    no_data_input1 = dsInput1.GetRasterBand(1).GetNoDataValue()
else:
    no_data_input1 = input1_no_data 
if input2_no_data == None: 
    no_data_input2 = dsInput2.GetRasterBand(1).GetNoDataValue()
else:
    no_data_input2 = input2_no_data

rows = dsInput1.RasterYSize
cols = dsInput1.RasterXSize

start = time()

unique_c=dict()

for irows in range(rows):
    Input1=dsInput1.GetRasterBand(1).ReadAsArray(0,irows,cols,1)
    Input2=dsInput2.GetRasterBand(1).ReadAsArray(0,irows,cols,1)
    for icols in range(cols):
        if Input1[0,icols] != no_data_input1  :
            if Input2[0,icols]!= no_data_input2 :
                row = Input1[0,icols],Input2[0,icols]
                if row in unique_c:
                    unique_c[row] += 1
                else:
                    unique_c[row] = 1

output = open(dst_file, "w")
for (a, b), c in unique_c.items():
    output.write("%i %i %i\n" % (a,b,c))
output.close()

elapsed = (time() - start)

print(elapsed , "loop in the rows ")