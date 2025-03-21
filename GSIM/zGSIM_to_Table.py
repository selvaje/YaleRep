# This script is to convert GSIM data into a dataframe format

# modified from the code of Jens Kiesel, 27.07.2018

import os, sys
import pandas as pd
from math import log

def calc_entropy(prob_arr):
    my_sum = 0
    for p in prob_arr:
        if p > 0:
            my_sum += p * log(p,2)
        elif p == 0 :
            my_sum += 0 
    return - my_sum

def check_string(string, nodata_val):
    #checks if a string contains information
    #returns nodata_val if no information
    if len(string) < 1:
        string = nodata_val
    return string

def mon_diff(d1,d2) :
    date_str = (d1, d2)
    [d1, d2] = pd.to_datetime(date_str)
    return d2.month - d1.month + 12*(d2.year - d1.year) + 1

def is_nextmonth(d1,d2) :
    date_str = (d1, d2)
    [d1, d2] = pd.to_datetime(date_str)
    if d1.year == d2.year and d1.month == d2.month - 1 :
        return True
    elif d1.year == d2.year - 1 and d1.month == 12 and d2.month == 1 :
        return True
    else :
        return False

#############################################
#  longest consecutive time interval : LCTI #
#############################################
def find_LCTI(df_ts) : 
    ts_A = ts_E = df_ts.index[0] 
    trace = 0
    i = 1
    count = 1 # number of time segments 
    for d_curr in df_ts.index[1:] :
        if trace == 0 and is_nextmonth(ts_E, d_curr) :
            ts_E = d_curr
        elif trace == 0 and not is_nextmonth(ts_E, d_curr) :
            count += 1 
            trace = 1 
            span0 = mon_diff(ts_A, ts_E)
            ts_I = ts_F = d_curr
        elif trace == 1 and  is_nextmonth(ts_F, d_curr) :
            ts_F = d_curr
        elif trace == 1 and  not is_nextmonth(ts_F, d_curr) :
            count += 1
            span1 = mon_diff(ts_I, ts_F)
            if span1 > span0 :
                ts_A = ts_I
                ts_E = ts_F
                ts_I = ts_F = d_curr
            else :
                ts_I = ts_F = d_curr
        elif trace == 1 and  i == len(df_ts.index) :
            span1 = mon_diff(ts_I, ts_F)
            if span1 > span0 :
                ts_A = ts_I
                ts_E = ts_F
        i += 1
    return ([ts_A, ts_E, count])            
    
def file_proc(fIn,d_start,d_end,fOut) :
        #----------------
        # Get header info
        #----------------
        #d_start, d_end : begin and end dates of the full time period of interest 
        nodata_val = 'NAN'
        gsimno_str, river_str, station_str, country_str, area_str, elevation_str, latitude_str, longitude_str = nodata_val,nodata_val,nodata_val,nodata_val,nodata_val,nodata_val,nodata_val,nodata_val            
        fp = open(fIn, 'r')
        for i, aline_str in enumerate(fp):
            if i < 20 : # meta data ends
                if aline_str.startswith("# gsim.no"):
                    gsimno_str = aline_str.split(':')[1].replace(' ', '').replace(',','')
                    gsimno_str = check_string(gsimno_str, nodata_val)
                elif aline_str.startswith("# river"):
                    river_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    river_str = check_string(river_str, nodata_val)
                elif aline_str.startswith("# station"):
                    station_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    station_str = check_string(station_str, nodata_val)
                elif aline_str.startswith("# country"):
                    country_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    country_str = check_string(country_str, nodata_val)
                elif aline_str.startswith("# latitude"):
                    latitude_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    latitude_str = check_string(latitude_str, nodata_val)
                elif aline_str.startswith("# longitude"):
                    longitude_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    longitude_str = check_string(longitude_str, nodata_val)
                elif aline_str.startswith("# area"):
                    area_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    area_str = check_string(area_str, nodata_val)
                elif aline_str.startswith("# elevation"):
                    elevation_str = aline_str.split(':')[1].replace(' ','').replace(',','')
                    elevation_str = check_string(elevation_str, nodata_val)
        #--------------------
        #get time series info
        #--------------------
            else :
                df = pd.read_csv(fp, sep=',\t', engine='python',header=0,index_col=0)
        fp.close()
        df.columns = df.columns.str.replace('"', '')
        df.index.name = 'date'
        mask = df['n.available'].values > 0
        df_sub = df[mask].loc[d_start:d_end, :]
        if df_sub.shape[0] >= 1 :
            pcetFP = df_sub.shape[0]/mon_diff(d_start, d_end) # percentage of data w.r.t full period of interest 
            TS_span = mon_diff(df_sub.index[0], df_sub.index[-1])       
            pcetTS = df_sub.shape[0]/TS_span # percentage of data w.r.t time series
            [LCTI_b,LCTI_e,nSeg] = find_LCTI(df_sub)
            LCTI_span = mon_diff(LCTI_b,LCTI_e)
            pcetLCTI = LCTI_span/df_sub.shape[0] # percentage of LCTI w.r.t available data 
            prob = nSeg/TS_span 
            Hb = calc_entropy([prob, 1-prob])
            df_sub.insert(0,'LAT',latitude_str)
            df_sub.insert(1,'LONG',longitude_str)
            df_sub['PCET_FP'] = format(pcetFP, '.3f')
            df_sub['TS_span'] = TS_span
            df_sub['PCET_TS'] = format(pcetTS, '.3f')
            df_sub['TS_b'] = df_sub.index[0]
            df_sub['TS_e'] = df_sub.index[-1]
            df_sub['TS_nSeg'] = nSeg
            df_sub['Hb'] = format(Hb, '.3f')
            df_sub['LCTI_span'] = LCTI_span
            df_sub['PCET_LCTI'] = format(pcetLCTI, '.3f')
            df_sub['LCTI_b'] = LCTI_b
            df_sub['LCTI_e'] = LCTI_e
            df_sub['ID'] = gsimno_str
            df_sub['CTRY'] = country_str
            df_sub['river'] = river_str
            df_sub['STN'] = station_str
            df_sub['ELEV'] = elevation_str
            df_sub['area'] = area_str
            df_sub.to_csv(fOut,na_rep="NAN")
        else :
            fp = open(fOut, 'w')
            fp.write('date,LAT,LONG,MEAN,SD,CV,IQR,MIN,MAX,MIN7,MAX7,n.missing,n.available,PCET_FP,TS_span' + \
                     'PCET_TS,LCTI_b,LCTI_e,LCTI,ID,CTRY,river,STN,ELEV,area\n')
            fp.write('NAN,%s,%s,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,NAN,%s,%s,%s,%s,%s,%s\n'\
                     %(latitude_str,longitude_str,gsimno_str,country_str,river_str,station_str,elevation_str,area_str))
            fp.close()
# TERRA : 1958-2018
# GSIM : 1806-2016
filter_from_date_str = '1958-01-31'
filter_to_date_str = '2016-12-31'

fPath, fName = os.path.split(sys.argv[1])
fPfx, fSfx = os.path.splitext(fName)
dirOut = sys.argv[2]
fOut = dirOut + "/" + fPfx + ".csv"

file_proc(sys.argv[1],filter_from_date_str,filter_to_date_str,fOut)

