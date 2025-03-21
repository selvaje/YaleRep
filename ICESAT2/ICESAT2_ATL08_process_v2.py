#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
---------------------------------------------------------------------------------------------------
ICESat-2 Band/Layer Subsetting and Export to GeoJSON and TXT Script
Author: Zhipeng Tang
Last Updated: 09/12/2020
---------------------------------------------------------------------------------------------------
"""

import os
import h5py
import pandas as pd
from shapely.geometry import Polygon
import geopandas as gp
import argparse
import sys
import numpy as np

# --------------------------COMMAND LINE ARGUMENTS AND ERROR HANDLING---------------------------- #
# Set up argument and error handling
parser = argparse.ArgumentParser(description='Performs Spatial/Band Subsetting and Conversion to GeoJSON for GEDI L1-L2 files')
parser.add_argument('--dir', required=True, help='Local directory containing GEDI files to be processed')
parser.add_argument('--input', required=True, help='Input .h5 files to be processed')
parser.add_argument('--sds', required=False, help='Specific science datasets (SDS) to include in the output GeoJSON \(see README for a list of available SDS and a list of default SDS returned for each product).')
parser.add_argument('--opd', required=False, help='output folder of GeoJSON')
args = parser.parse_args()

# --------------------------------SET ARGUMENTS TO VARIABLES------------------------------------- #
# Options include a GeoJSON or a list of bbox coordinates
ROI = '90, -180, -90, 180'  

# Convert to Shapely polygon for geojson, .shp or bbox
if ROI.endswith('json') or ROI.endswith('.shp'):
    try:
        ROI = gp.GeoDataFrame.from_file(ROI)
        ROI.crs = 'EPSG:4326'
        if len(ROI) > 1:
            print('Multi-feature polygon detected. Only the first feature will be used to subset the GEDI data.')
        ROI = ROI.geometry[0]
    except:
        print('error: unable to read input geojson file or the file was not found')
        sys.exit(2)
else:
    ROI = ROI.split(',')
    ROI = [float(r) for r in ROI]
    try:
        ROI = Polygon([(ROI[1], ROI[0]), (ROI[3], ROI[0]), (ROI[3], ROI[2]), (ROI[1], ROI[2])]) 
        # ROI.crs = 'EPSG:4326'
    except:
        print('error: unable to read input bounding box coordinates, the required format is: ul_lat,ul_lon,lr_lat,lr_lon')
        sys.exit(2)

# Keep the exact input geometry for the final clip to ROI
finalClip = gp.GeoDataFrame([1], geometry=[ROI], crs='EPSG:4326')    

# Format and set input/working directory from user-defined arg
if args.dir[-1] != '/' and args.dir[-1] != '\\':
    inDir = args.dir.strip("'").strip('"') + os.sep
else:
    inDir = args.dir

# Find input directory
try:
    os.chdir(inDir)
except FileNotFoundError:
    print('error: input directory (--dir) provided does not exist or was not found')
    sys.exit(2)

if args.input is not None:
    FILE_NAME = args.input
else:
    FILE_NAME = [o for o in os.listdir() if o.endswith('.h5') and 'ATL08' in o]

# Define additional layers to subset if provided    
if args.sds is not None:
    layerSubset = args.sds.split(',')
else:
    layerSubset = None

if args.opd[-1] != '/' and args.opd[-1] != '\\':
    outDir = args.opd.strip("'").strip('"') + os.sep
else:
    outDir = os.path.normpath((os.path.split(inDir)[0] + os.sep + 'output')) + os.sep

# -------------------------------------SET UP WORKSPACE------------------------------------------ #
# Create and set output directory
# outDir = os.path.normpath((os.path.split(inDir)[0] + os.sep + 'output')) + os.sep
if not os.path.exists(outDir):
    os.makedirs(outDir)


# FILE_NAME = 'icesat2/ATL08_20191025063228_04330507_003_01.h5'
#FILE_NAME = [FILE_NAME]
print(f"{FILE_NAME}")

# group = ['/gt1l', '/gt1r', '/gt2l', '/gt2r', '/gt3l', '/gt3r']

group = ['/gt1r', '/gt2r', '/gt3r']  # only with strong beams

try:
    with h5py.File(FILE_NAME, mode='r') as f:
        icesatDF = pd.DataFrame()

        for g in group:


            # Ground Track L1
            latitude = f[g+'/land_segments/latitude'][:]

            longitude = f[g+'/land_segments/longitude'][:]

            # canopy canopy98:98% height max_canopy: RH100 median_canopy:PH50 min_canopy:minimum canopy

            #centroid_hei = f[g+'/land_segments/canopy/centroid_height']
            #max_canopy = f[g+'/land_segments/canopy/h_max_canopy']
            #median_canopy = f[g+'/land_segments/canopy/h_median_canopy']
            #landsat_f = f[g+'/land_segments/canopy/landsat_flag'] only one value
            # canopy_photons = f[g+'/land_segments/canopy/subset_can_flag'][:] (n * 5) vector
            # canopy_perc_abs = f[g+'/land_segments/canopy/canopy_h_metrics_abs'][:]

            canopy98 = f[g+'/land_segments/canopy/h_canopy'][:]
            min_canopy = f[g+'/land_segments/canopy/h_min_canopy'][:]
            canopy_f = f[g+'/land_segments/canopy/canopy_flag'][:] 
            night_f = f[g+'/land_segments/night_flag'][:] 
            sd_canopy = f[g+'/land_segments/canopy/toc_roughness'][:]  
            canopy_perc = f[g+'/land_segments/canopy/canopy_h_metrics'][:]

            # get the rh_25, rh_50, rh_60, rh_70, rh_75, rh_80, rh_85, rh_90, rh_95
            col_name = ['rh_25', 'rh_50', 'rh_60', 'rh_70', 'rh_75', 'rh_80', 'rh_85', 'rh_90', 'rh_95']
            canopy_perc_df = pd.DataFrame(np.array(canopy_perc).reshape(len(canopy_perc),9), columns = col_name)
            # 
            # geoDF = pd.DataFrame({'latitude': latitude, 'longitude': longitude, 'min_canopy': min_canopy, 'canopy_f': canopy_f, 'quality_f': quality_f, 'night_f': night_f, 'canopy_photons': canopy_photons, 'sd_canopy': sd_canopy})
            geoDF = pd.DataFrame({'latitude': latitude, 'longitude': longitude, 'rh_98': canopy98, 'min_canopy': min_canopy, 'canopy_f': canopy_f, 'night_f': night_f, 'sd_canopy': sd_canopy})
            geoDF = pd.concat([geoDF, canopy_perc_df], axis=1)
            geoDF = gp.GeoDataFrame(geoDF, geometry=gp.points_from_xy(geoDF.longitude, geoDF.latitude))

            # Clip to only include points within the user-defined bounding box
            # geoDF = geoDF[geoDF['geometry'].within(ROI.envelope)]

            # filter by flag
            geoDF = geoDF.where(geoDF['canopy_f'].ne(0)) 
            geoDF = geoDF.where(geoDF['sd_canopy'] <= 7)
            geoDF = geoDF.where(geoDF['rh_98'] > 0)
            # geoDF = geoDF.where(geoDF['min_canopy']<1000)
            geoDF = geoDF.dropna()

            icesatDF = icesatDF.append(geoDF)
            del geoDF

        # Convert to geodataframe and add crs
        icesatDF = gp.GeoDataFrame(icesatDF)
        icesatDF.crs = 'EPSG:4326'  

        icesatDF = icesatDF.drop(columns=['geometry', 'canopy_f', 'sd_canopy'])

        # check if icesatDF is empty
        if len(icesatDF) == 0:
            print("No points were founded!")
            sys.exit(3)
        else:

            # --------------------------------EXPORT AS TXT---------------------------------------------- #
          # Check for empty output dataframe
            try:    
                fmt = (len(icesatDF.columns)-5) * ['%.2f']
                fmt[0:0] = ['%.8g', '%.8g', '%.2f', '%.2f', '%d']
                
                np.savetxt(f"{outDir}{FILE_NAME.replace('.h5', '_detailed.txt')}", icesatDF.values, fmt=fmt)
                print(f"{FILE_NAME.replace('.h5', '_detailed.txt')} saved at: {outDir}")
            except ValueError:
                print(f"{FILE_NAME} intersects the bounding box of the input ROI, but no shots intersect final clipped ROI.")
                
except:
    sys.exit(4)
