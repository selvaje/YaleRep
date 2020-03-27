#!/usr/bin/env python
# version 1  
# August 7 2013
#******************************************************************************
#  add addattr-area.py
#
#  Repository: www.spatial-eclogy.net
#  Purpose:  Command line to add attribute area at each polygon in a shapefile.
#            The new attribute name, defined by the user, will be add to the shapefile. 
#            In case the attribute name was already present in the shapefile the new value will be stored
#            The script can be used also to drop a specific item (like  ogrinfo  -al -geom=NO  -sql "ALTER TABLE layername  DROP itemname " input.shp )
#            No new shapefile will be created  
#  Author:   Giuseppe Amatulli, giuseppe.amatulli@gmail.com
#******************************************************************************
#  Copyright (c) 2013, Giuseppe Amatulli, giuseppe.amatulli@gmail.com
# 
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
#******************************************************************************
# addattr-area.py src_shapefile item_name [-drop]
################################################################


from osgeo import ogr
import sys

def Usage():
    print('Usage: addattr-area.py src_shapefile item_name [-drop]')
    print('Use -drop flag to drop an existing item')
    sys.exit( 1 )

input=None
itemname=None
drop=None
itemdrop=None

if len(sys.argv) < 2:
    sys.exit(Usage())

# Parse command line arguments.
i = 1
while i < len(sys.argv):
    arg = sys.argv[i]
    if input is None:
        input = arg
    elif itemname is None:
        itemname = arg
    elif arg == '-drop':
        itemdrop = itemname
    else:
        Usage()
    i = i + 1

if  input is None:
    Usage()

if  itemname is None:
    Usage()

# Open a Shapefile, and get field names
source = ogr.Open(input,1)
layer = source.GetLayer()


# delete the item for the -drop flag and exist. 
# no more action will be executed.
# delete the field if the index of the fild is != -1 
if itemdrop == itemname : 
    if layer.GetLayerDefn().GetFieldIndex(itemname) != -1 :
        layer.DeleteField(layer.GetLayerDefn().GetFieldIndex(itemname)) 
    sys.exit( 1 )

# delete the field if the index of the fild is != -1 
if layer.GetLayerDefn().GetFieldIndex(itemname) != -1 :
    layer.DeleteField(layer.GetLayerDefn().GetFieldIndex(itemname)) 

# add the field

new_field = ogr.FieldDefn(itemname, ogr.OFTReal ) 
layer.CreateField(new_field)

print ('Adding item and calculate the area') 

for poly in xrange(layer.GetFeatureCount()) :
    feature = layer.GetFeature(poly)
    geom=feature.GetGeometryRef()
    area=geom.GetArea()
    feature.SetField(itemname,area)
    if layer.SetFeature(feature) != 0:
        print "Failed to create feature in shapefile.\n"
        sys.exit( 1 )
    feature.Destroy()

# Close the Shapefile
source = None