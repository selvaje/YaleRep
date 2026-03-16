#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc01_download_quantile.sh.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc01_download_quantile.sh.%J.err
#SBATCH --job-name=
#SBATCH --array=500
#SBATCH --mem=500G

##### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/USGS/sc01_download_quantile.sh 

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q
cd $EXTRACT

source  /nfs/roberts/project/pi_ga254/ga254/py_env/venv_usgs/bin/activate

python3 <<'EOF'

import requests
import pandas as pd
import numpy as np
import io
import os
import time
import pickle
from concurrent.futures import ProcessPoolExecutor

# ---------------------------------------------------
# USER SETTINGS
# ---------------------------------------------------
START_DATE = "1990-01-01"
END_DATE   = "2020-12-31"
CHUNK_SIZE = 40
MAX_WORKERS = 6
CFS_TO_CMS = 0.0283168466
QUANTILES  = np.arange(0, 1.01, 0.1)
CHECKPOINT_FILE = "progress_checkpoint.pkl"
DONE_FILE = "processed_stations.txt"
# ---------------------------------------------------


# ---------------------------------------------------
# 1️⃣ GET ALL STATIONS
# ---------------------------------------------------
def get_all_stream_stations():

    url = "https://waterservices.usgs.gov/nwis/site/"
    params = {
        "format": "rdb",
        "siteType": "ST",
        "parameterCd": "00060",
        "siteStatus": "all",
        "siteOutput": "expanded"   # 🔥 THIS FIXES IT
    }

    r = requests.get(url, params=params)
    df = pd.read_csv(io.StringIO(r.text), sep="\t", comment="#", dtype=str)

    # Check available columns safely
    print("Columns returned:", df.columns.tolist())

    df = df.rename(columns={
        "site_no": "StationID",
        "dec_lat_va": "lat",
        "dec_long_va": "long",
        "drain_area_va": "drain_area"
    })

    # Only convert if exists
    if "drain_area" in df.columns:
        df["drain_area"] = pd.to_numeric(df["drain_area"], errors="coerce")
    else:
        df["drain_area"] = np.nan

    df = df.dropna(subset=["lat", "long"])

    return df[["StationID", "lat", "long", "drain_area"]]


# ---------------------------------------------------
# 2️⃣ BULK DOWNLOAD
# ---------------------------------------------------
def download_bulk_daily(station_ids):

    url = "https://waterservices.usgs.gov/nwis/dv/"
    params = {
        "format": "rdb",
        "sites": ",".join(station_ids),
        "startDT": START_DATE,
        "endDT": END_DATE,
        "parameterCd": "00060",
        "statCd": "00003"
    }

    r = requests.get(url, params=params)
    if r.status_code != 200:
        return None, None

    text = r.text.splitlines()

    # Detect unit from header comments
    unit = None
    for line in text:
        if line.startswith("#") and "ft3/s-mi2" in line:
            unit = "CFSM"
        elif line.startswith("#") and "ft3/s" in line:
            unit = "CFS"

    df = pd.read_csv(io.StringIO(r.text), sep="\t", comment="#", dtype=str)

    return df, unit


# ---------------------------------------------------
# 3️⃣ PER-STATION PROCESSING (PARALLEL SAFE)
# ---------------------------------------------------
def process_station(args):

    station_id, group, meta, unit = args

    try:
        lat = meta.loc[station_id, "lat"]
        lon = meta.loc[station_id, "long"]
        drain_area = meta.loc[station_id, "drain_area"]

        discharge_col = [c for c in group.columns if "00060_00003" in c]
        if not discharge_col:
            return None

        discharge_col = discharge_col[0]

        group["value"] = pd.to_numeric(group[discharge_col], errors="coerce")
        group["date"] = pd.to_datetime(group["datetime"])
        group = group.dropna(subset=["value"])

        # Unit conversion
        if unit == "CFS":
            group["cms"] = group["value"] * CFS_TO_CMS
        elif unit == "CFSM" and not pd.isna(drain_area):
            group["cms"] = group["value"] * drain_area * CFS_TO_CMS
        else:
            return None

        group["year"] = group["date"].dt.year
        group["month"] = group["date"].dt.month

        records = []

        for (y, m), sub in group.groupby(["year", "month"]):

            if len(sub) < 10:
                continue

            q_values = np.quantile(sub["cms"], QUANTILES)

            row = {
                "StationID": station_id,
                "lat": lat,
                "long": lon,
                "year": y,
                "month": m,
            }

            for i, q in enumerate(QUANTILES):
                if q == 0:
                    label = "QMIN"
                elif q == 1:
                    label = "QMAX"
                else:
                    label = f"Q{int(q*100)}"
                row[label] = q_values[i]

            records.append(row)

        return pd.DataFrame(records)

    except:
        return None


# ---------------------------------------------------
# 4️⃣ MAIN WITH CHECKPOINTING + PARALLEL
# ---------------------------------------------------
def main():

    stations = get_all_stream_stations()
    station_ids = stations["StationID"].tolist()
    meta = stations.set_index("StationID")

    # Load checkpoint
    if os.path.exists(CHECKPOINT_FILE):
        with open(CHECKPOINT_FILE, "rb") as f:
            all_results = pickle.load(f)
    else:
        all_results = []

    if os.path.exists(DONE_FILE):
        with open(DONE_FILE, "r") as f:
            processed = set(f.read().splitlines())
    else:
        processed = set()

    station_ids = [s for s in station_ids if s not in processed]

    print(f"Remaining stations: {len(station_ids)}")

    for i in range(0, len(station_ids), CHUNK_SIZE):

        chunk = station_ids[i:i+CHUNK_SIZE]

        df, unit = download_bulk_daily(chunk)
        if df is None or df.empty:
            continue

        grouped = df.groupby("site_no")

        tasks = [
            (sid, grouped.get_group(sid), meta, unit)
            for sid in grouped.groups
        ]

        with ProcessPoolExecutor(max_workers=MAX_WORKERS) as executor:
            results = list(executor.map(process_station, tasks))

        for res in results:
            if res is not None and not res.empty:
                all_results.append(res)

        # Update processed list
        with open(DONE_FILE, "a") as f:
            for sid in chunk:
                f.write(sid + "\n")

        # Save checkpoint
        with open(CHECKPOINT_FILE, "wb") as f:
            pickle.dump(all_results, f)

        print(f"Processed {i + len(chunk)} / total")
        time.sleep(1)

    final_df = pd.concat(all_results, ignore_index=True)
    final_df.to_csv("USGS_monthly_quantiles_CMS.csv", index=False)

    print("✅ Finished.")


if __name__ == "__main__":
    main()

print('End of the script!!!!!!!!!!!!')
EOF

