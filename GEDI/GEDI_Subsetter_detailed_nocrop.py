#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
---------------------------------------------------------------------------------------------------
GEDI Spatial and Band/Layer Subsetting and Export to GeoJSON Script
Author: Cole Krehbiel
Last Updated: 05/19/2020
See README for additional information:
https://git.earthdata.nasa.gov/projects/LPDUR/repos/gedi-subsetter/browse/
---------------------------------------------------------------------------------------------------
"""
# Import necessary libraries
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
parser.add_argument('--beams', required=False, help='Specific beams to be included in the output GeoJSON (default is all beams) \
                    BEAM0000,BEAM0001,BEAM0010,BEAM0011 are Coverage Beams. BEAM0101,BEAM0110,BEAM1000,BEAM1011 are Full Power Beams.')
parser.add_argument('--sds', required=False, help='Specific science datasets (SDS) to include in the output GeoJSON \
                    (see README for a list of available SDS and a list of default SDS returned for each product).')
parser.add_argument('--opd', required=False, help='output folder of GeoJSON')
args = parser.parse_args()

ROI = '85, -180, -60, 180'

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
        ROI.crs = 'EPSG:4326'
    except:
        print('error: unable to read input bounding box coordinates, the required format is: ul_lat,ul_lon,lr_lat,lr_lon')
        sys.exit(2)

# Keep the exact input geometry for the final clip to ROI
finalClip = gp.GeoDataFrame([1], geometry=[ROI], crs='EPSG:4326')    

# --------------------------------SET ARGUMENTS TO VARIABLES------------------------------------- #
# Options include a GeoJSON or a list of bbox coordinates
ROI = '85, -180, -60, 180'

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
        ROI.crs = 'EPSG:4326'
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

# Define beam subset if provided or default to all beams        
if args.input is not None:
    gediFiles = args.input
else:
    gediFiles = [o for o in os.listdir() if o.endswith('.h5') and 'GEDI' in o]

if args.beams is not None:
    beamSubset = args.beams.split(',')
else:
    beamSubset = ['BEAM0000', 'BEAM0001', 'BEAM0010', 'BEAM0011', 'BEAM0101', 'BEAM0110', 'BEAM1000', 'BEAM1011']

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

# Create list of GEDI HDF-EOS5 files in the directory
#gediFiles = [o for o in os.listdir() if o.endswith('.h5') and 'GEDI' in o]

# --------------------DEFINE PRESET BAND/LAYER SUBSETS ------------------------------------------ #
# Default layers to be subset and exported, see README for information on how to add additional layers
l1bSubset = [ '/geolocation/latitude_bin0', '/geolocation/longitude_bin0', '/channel', '/shot_number',
             '/rxwaveform','/rx_sample_count', '/stale_return_flag', '/tx_sample_count', '/txwaveform',
             '/geolocation/degrade', '/geolocation/delta_time', '/geolocation/digital_elevation_model',
              '/geolocation/solar_elevation',  '/geolocation/local_beam_elevation',  '/noise_mean_corrected',
             '/geolocation/elevation_bin0', '/geolocation/elevation_lastbin', '/geolocation/surface_type']
#l2aSubset = ['/lat_lowestmode', '/lon_lowestmode', 'geolocation/degrade_flag',
            # '/digital_elevation_model', '/elev_lowestmode', '/quality_flag', '/rh', '/sensitivity']        

l2aSubset = ['/lat_lowestmode', '/lon_lowestmode', '/channel', '/shot_number', '/degrade_flag', 
             '/digital_elevation_model', '/elev_lowestmode', '/quality_flag', '/sensitivity',  
             '/elevation_bias_flag', 'geolocation/rh_a1', 'geolocation/rh_a2', 'geolocation/rh_a3',
             'geolocation/rh_a4', 'geolocation/rh_a5', 'geolocation/rh_a6', '/surface_flag', '/solar_elevation', 'geolocation/quality_flag_a1', 'geolocation/quality_flag_a2', 'geolocation/quality_flag_a3', 'geolocation/quality_flag_a4', 'geolocation/quality_flag_a5', 'geolocation/quality_flag_a6', 'geolocation/sensitivity_a1', 'geolocation/sensitivity_a2', 'geolocation/sensitivity_a3', 'geolocation/sensitivity_a4', 'geolocation/sensitivity_a5', 'geolocation/sensitivity_a6' ] 

l2bSubset = ['/geolocation/lat_lowestmode', '/geolocation/lon_lowestmode', '/channel', '/geolocation/shot_number',
             '/cover', '/cover_z', '/fhd_normal', '/pai', '/pai_z',  '/rhov',  '/rhog',
             '/pavd_z', '/l2a_quality_flag', '/l2b_quality_flag', '/rh100', '/sensitivity',  
             '/stale_return_flag', '/surface_flag', '/geolocation/degrade_flag',  '/geolocation/solar_elevation',
             '/geolocation/delta_time', '/geolocation/digital_elevation_model', '/geolocation/elev_lowestmode']
 
# -------------------IMPORT GEDI FILES AS GEODATAFRAMES AND CLIP TO ROI-------------------------- #   
# Loop through each GEDI file and export as a point geojson
l = 0
gediFiles = [gediFiles]
for g in gediFiles:
    l += 1
    print(f"Processing file: {g} ({l}/{len(gediFiles)})")
    gedi = h5py.File(g, 'r')      # Open file
    gediName = g.split('.h5')[0]  # Keep original filename
    gedi_objs = []            
    gedi.visit(gedi_objs.append)  # Retrieve list of datasets  

    # Search for relevant SDS inside data file
    gediSDS = [str(o) for o in gedi_objs if isinstance(gedi[o], h5py.Dataset)] 
    
    # Define subset of layers based on product
    if 'GEDI01_B' in g:
        sdsSubset = l1bSubset
    elif 'GEDI02_A' in g:
        sdsSubset = l2aSubset 
    else:
        sdsSubset = l2bSubset
    
    # Append additional datasets if provided
    if layerSubset is not None:
        [sdsSubset.append(y) for y in layerSubset]
    
    # Subset to the selected datasets
    gediSDS = [c for c in gediSDS if any(c.endswith(d) for d in sdsSubset)]
        
    # Get unique list of beams and subset to user-defined subset or default (all beams)
    beams = []
    for h in gediSDS:
        beam = h.split('/', 1)[0]
        if beam not in beams and beam in beamSubset:
            beams.append(beam)

    gediDF = pd.DataFrame()  # Create empty dataframe to store GEDI datasets    
    del beam, gedi_objs, h
    
    # Loop through each beam and create a geodataframe with lat/lon for each shot, then clip to ROI
    for b in beams:
        beamSDS = [s for s in gediSDS if b in s]
        
        # Search for latitude, longitude, and shot number SDS
        lat = [l for l in beamSDS if sdsSubset[0] in l][0]  
        lon = [l for l in beamSDS if sdsSubset[1] in l][0]
        shot = f'{b}/shot_number'          
        
        # Open latitude, longitude, and shot number SDS
        shots = gedi[shot][()]
        lats = gedi[lat][()]
        lons = gedi[lon][()]
        
        # Append BEAM, shot number, latitude, longitude and an index to the GEDI dataframe
        geoDF = pd.DataFrame({'BEAM': len(shots) * [b], shot.split('/', 1)[-1].replace('/', '_'): shots,
                              'Latitude':lats, 'Longitude':lons, 'index': np.arange(0, len(shots), 1)})
        
        # Convert lat/lon coordinates to shapely points and append to geodataframe
        geoDF = gp.GeoDataFrame(geoDF, geometry=gp.points_from_xy(geoDF.Longitude, geoDF.Latitude))
        
        # Clip to only include points within the user-defined bounding box
        geoDF = geoDF[geoDF['geometry'].within(ROI.envelope)]    
        gediDF = gediDF.append(geoDF)
        del geoDF
    
    # Convert to geodataframe and add crs
    gediDF = gp.GeoDataFrame(gediDF)
    gediDF.crs = 'EPSG:4326'
    
    if gediDF.shape[0] == 0:
        print(f"No intersecting shots were found between {g} and the region of interest submitted.")
        continue
    del lats, lons, shots
    
# --------------------------------OPEN SDS AND APPEND TO GEODATAFRAME---------------------------- #
    beamsDF = pd.DataFrame()  # Create dataframe to store SDS
    j = 0
    
    # Loop through each beam and extract subset of defined SDS
    for b in beams:
        beamDF = pd.DataFrame()
        beamSDS = [s for s in gediSDS if b in s and not any(s.endswith(d) for d in sdsSubset[0:3])]
        shot = f'{b}/shot_number'
        
        try:
            # set up indexes in order to retrieve SDS data only within the clipped subset from above
            mindex = min(gediDF[gediDF['BEAM'] == b]['index'])
            maxdex = max(gediDF[gediDF['BEAM'] == b]['index']) + 1
            shots = gedi[shot][mindex:maxdex]
        except ValueError:
            print(f"No intersecting shots found for {b}")
            continue
        # Loop through and extract each SDS subset and add to DF
        for s in beamSDS:
            j += 1
            sName = s.split('/', 1)[-1].replace('/', '_')

            # Datasets with consistent structure as shots
            if gedi[s].shape == gedi[shot].shape:
                beamDF[sName] = gedi[s][mindex:maxdex]  # Subset by index
            
            # Datasets with a length of one 
            elif len(gedi[s][()]) == 1:
                beamDF[sName] = [gedi[s][()][0]] * len(shots) # create array of same single value
            
            # Multidimensional datasets
            elif len(gedi[s].shape) == 2 and 'surface_type' not in s: 
                allData = gedi[s][()][mindex:maxdex]
                
                if sName != 'rh':  ## this is six algorithems 
                    # For each additional dimension, create a new output column to store those data
                    for i in range(gedi[s].shape[1]):
                        step = []
                        for a in allData:
                            step.append(a[i])
                        beamDF[f"{sName}_{i}"] = step
                else:
                    beamDF[sName] = allData[:,0]
            
            # Waveforms
            elif s.endswith('waveform') or s.endswith('pgap_theta_z'):
                waveform = []
                
                if s.endswith('waveform'):
                    # Use sample_count and sample_start_index to identify the location of each waveform
                    start = gedi[f'{b}/{s.split("/")[-1][:2]}_sample_start_index'][mindex:maxdex]
                    count = gedi[f'{b}/{s.split("/")[-1][:2]}_sample_count'][mindex:maxdex]
                
                # for pgap_theta_z, use rx sample start index and count to subset
                else:
                    # Use sample_count and sample_start_index to identify the location of each waveform
                    start = gedi[f'{b}/rx_sample_start_index'][mindex:maxdex]
                    count = gedi[f'{b}/rx_sample_count'][mindex:maxdex]
                wave = gedi[s][()]
                
                # in the dataframe, each waveform will be stored as a list of values
                for k in range(len(start)):
                    singleWF = wave[int(start[k] - 1): int(start[k] - 1 + count[k])]
                    waveform.append(','.join([str(q) for q in singleWF]))
                beamDF[sName] = waveform
            
            # Surface type 
            elif s.endswith('surface_type'):
                surfaces = ['land', 'ocean', 'sea_ice', 'land_ice', 'inland_water']
                allData = gedi[s][()]
                for i in range(gedi[s].shape[0]):
                    beamDF[f'{surfaces[i]}'] = allData[i][mindex:maxdex]
                del allData
            else:
                print(f"SDS: {s} not found")
            print(f"Processing {j} of {len(beamSDS) * len(beams)}: {s}")
            
        beamsDF = beamsDF.append(beamDF)
    del beamDF, beamSDS, beams, gedi, gediSDS, shots, sdsSubset

    select = ['shot_number', 'geolocation_rh_a1_95', 'geolocation_rh_a2_95', 'geolocation_rh_a3_95', 'geolocation_rh_a4_95', 'geolocation_rh_a5_95', 'geolocation_rh_a6_95', 'digital_elevation_model', 'elev_lowestmode', 'geolocation_quality_flag_a1', 'geolocation_quality_flag_a2', 'geolocation_quality_flag_a3', 'geolocation_quality_flag_a4', 'geolocation_quality_flag_a5', 'geolocation_quality_flag_a6','geolocation_sensitivity_a1', 'geolocation_sensitivity_a2', 'geolocation_sensitivity_a3', 'geolocation_sensitivity_a4', 'geolocation_sensitivity_a5', 'geolocation_sensitivity_a6', 'degrade_flag', 'solar_elevation']

    for i in range(0, 92, 5):
        select.extend(['geolocation_rh_a1_'+ str(i),'geolocation_rh_a2_'+ str(i),'geolocation_rh_a3_'+ str(i), 'geolocation_rh_a4_'+ str(i),'geolocation_rh_a5_'+ str(i),'geolocation_rh_a6_'+ str(i)])

    select.extend(['geolocation_rh_a1_100', 'geolocation_rh_a2_100', 'geolocation_rh_a3_100', 'geolocation_rh_a4_100', 'geolocation_rh_a5_100', 'geolocation_rh_a6_100'])

    beamsDF = beamsDF[select]
    outDF = pd.merge(gediDF, beamsDF, left_on='shot_number', right_on=[sn for sn in beamsDF.columns if sn.endswith('shot_number')][0])
    # outDF.index = outDF['index']

    del gediDF, beamsDF
    print('doing the gp.overlay!')  

    outDF = outDF.replace({'BEAM' : { 'BEAM0000' : 1, 'BEAM0001' : 2, 'BEAM0010' : 3,  'BEAM0011' : 4,
                                     'BEAM0101' : 5, 'BEAM0110' : 6, 'BEAM1000' : 7, 'BEAM1011' : 8}})
    
    lennn = len(outDF)
    

    # Add two columns: minimum and maxmum
    outDF['max_rh_95'] = outDF[['geolocation_rh_a1_95', 'geolocation_rh_a2_95', 'geolocation_rh_a3_95', 'geolocation_rh_a4_95', 'geolocation_rh_a5_95', 'geolocation_rh_a6_95']].max(axis=1)
    outDF['min_rh_95'] = outDF[['geolocation_rh_a1_95', 'geolocation_rh_a2_95', 'geolocation_rh_a3_95', 'geolocation_rh_a4_95', 'geolocation_rh_a5_95', 'geolocation_rh_a6_95']].min(axis=1)

    # outDF = outDF.where(outDF['quality_flag'].ne(0)) 
    # outDF = outDF.where(outDF['sensitivity'] > 0.95)
    outDF = outDF.where(outDF['min_rh_95'] > 0)
    outDF = outDF.dropna()

    select = ['Latitude', 'Longitude', 'geolocation_rh_a1_95', 'geolocation_rh_a2_95', 'geolocation_rh_a3_95', 'geolocation_rh_a4_95', 'geolocation_rh_a5_95', 'geolocation_rh_a6_95', 'min_rh_95', 'max_rh_95', 'BEAM', 'digital_elevation_model', 'elev_lowestmode', 'geolocation_quality_flag_a1', 'geolocation_quality_flag_a2', 'geolocation_quality_flag_a3', 'geolocation_quality_flag_a4', 'geolocation_quality_flag_a5', 'geolocation_quality_flag_a6','geolocation_sensitivity_a1', 'geolocation_sensitivity_a2', 'geolocation_sensitivity_a3', 'geolocation_sensitivity_a4', 'geolocation_sensitivity_a5', 'geolocation_sensitivity_a6', 'degrade_flag', 'solar_elevation']

    for i in range(0, 92, 5):
        select.extend(['geolocation_rh_a1_'+ str(i),'geolocation_rh_a2_'+ str(i),'geolocation_rh_a3_'+ str(i), 'geolocation_rh_a4_'+ str(i),'geolocation_rh_a5_'+ str(i),'geolocation_rh_a6_'+ str(i)])

    select.extend(['geolocation_rh_a1_100', 'geolocation_rh_a2_100', 'geolocation_rh_a3_100', 'geolocation_rh_a4_100', 'geolocation_rh_a5_100', 'geolocation_rh_a6_100'])
   
    lennn2 = lennn - len(outDF)
    print(f"Quality filtered: {lennn2} in {len(outDF)} footprints were filtered.")

    # outDF = outDF.drop(columns=['geometry', 'shot_number'])
    #del select[-2]

    outDF = outDF[select] 
    for i in outDF.columns:
        print(i)
   
    # Check if outDF is empty
    if len(outDF) == 0:
        print('No points are founded!')
        sys.exit(3)
        
    else:
# --------------------------------EXPORT AS TXT---------------------------------------------- #
        # Check for empty output dataframe
        try:    
            fmt = (len(outDF.columns)-27) * ['%d']
            fmt[0:0] = ['%.8g', '%.8g', '%d', '%d', '%d', '%d', '%d', '%d',    '%d', '%d',    '%d', '%.8g', '%.8g',   '%d','%d','%d','%d','%d','%d',    '%.3f','%.3f','%.3f','%.3f','%.3f','%.3f',    '%d', '%.1f' ]
           
            np.savetxt(f"{outDir}{g.replace('.h5', '_detailed.txt')}", outDF.values, fmt=fmt)
            print(f"{g.replace('.h5', '.txt')} saved at: {outDir}")
        except ValueError:
            print(f"{g} intersects the bounding box of the input ROI, but no shots intersect final clipped ROI.")