#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc02_quantile.sh.%A_%a.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc02_quantile.sh.%A_%a.err
#SBATCH --job-name=sc02_quantile
#SBATCH --mem=10G
#SBATCH --array=20001-21579

###  --array=1-10000
###  --array=10001-20000
###  --array=20001-21579
##### sbatch /nfs/roberts/pi/pi_ga254/hydro/scripts/USGS/sc02_quantile.sh

INPUT_DIR=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q
OUTPUT_DIR=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile

export file=$(find "$INPUT_DIR" -name "*.rdb" | head -"$SLURM_ARRAY_TASK_ID" | tail -1)
export filename=$(basename "$file")

source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_usgs/bin/activate

python << 'EOF'
from __future__ import annotations

import os
from typing import List

import numpy as np
import pandas as pd

CFS_TO_CMS = 0.028316846592

# Passed from bash environment
INFILE = os.environ["file"]
FILENAME = os.environ["filename"]

OUTPUT_DIR = "/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/usgs/stations_q_quantile"

PCTS = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
QCOLS = ["QMIN"] + [f"Q{p}" for p in PCTS[1:-1]] + ["QMAX"]


def _looks_like_types_row(row: pd.Series) -> bool:
    vals = [str(v) for v in row.tolist()]
    if len(vals) < 3:
        return False
    return all(any(v.endswith(sfx) for sfx in ("s", "n", "d")) for v in vals if v != "nan")


def detect_discharge_col(columns: List[str]) -> str:
    # Preferred: TSID_00060_00003 (daily mean discharge)
    for c in columns:
        if c.endswith("_00060_00003"):
            return c
    # Fallback: any column containing 00060_00003
    for c in columns:
        if "00060_00003" in c:
            return c
    # Last resort: 4th column
    if len(columns) >= 4:
        return columns[3]
    raise ValueError(f"Cannot detect discharge column from columns={columns}")


def read_usgs_rdb(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, sep="\t", comment="#", dtype=str)

    if df.empty:
        return pd.DataFrame(columns=["StationID", "date", "q_cms"])

    # Drop the "types" row (e.g. 5s 15s 20d 14n 10s)
    if _looks_like_types_row(df.iloc[0]):
        df = df.iloc[1:].reset_index(drop=True)

    if "site_no" not in df.columns or "datetime" not in df.columns:
        raise ValueError(f"{path}: missing site_no/datetime. Columns={list(df.columns)}")

    discharge_col = detect_discharge_col(list(df.columns))

    out = df[["site_no", "datetime", discharge_col]].copy()
    out = out.rename(columns={"site_no": "StationID", "datetime": "date", discharge_col: "q_cfs"})

    out["date"] = pd.to_datetime(out["date"], errors="coerce")
    out["q_cfs"] = pd.to_numeric(out["q_cfs"], errors="coerce")
    out["q_cms"] = out["q_cfs"] * CFS_TO_CMS

    out = out.dropna(subset=["date", "q_cms"])
    return out[["StationID", "date", "q_cms"]]


def quantile_series(x: pd.Series) -> pd.Series:
    arr = x.to_numpy(dtype=float)
    qs = np.nanpercentile(arr, PCTS)
    return pd.Series(qs, index=QCOLS)


def main() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    daily = read_usgs_rdb(INFILE)

    # If file has no observations after cleaning, still write an empty .ql with header
    if daily.empty:
        qtbl = pd.DataFrame(columns=["StationID", "YYYY", "MM"] + QCOLS)
    else:
        daily["YYYY"] = daily["date"].dt.year.map(lambda y: f"{int(y):04d}")
        daily["MM"] = daily["date"].dt.month.map(lambda m: f"{int(m):02d}")

        qtbl = (
            daily.groupby(["StationID", "YYYY", "MM"])["q_cms"]
            .apply(quantile_series)
            .unstack()
            .reset_index()
        )

        qtbl = qtbl[["StationID", "YYYY", "MM"] + QCOLS]

    out_path = os.path.join(OUTPUT_DIR, f"{FILENAME}.ql")
    # space-separated as in your current script
    qtbl.to_csv(out_path, sep=" ", index=False, float_format="%.6f")

    print(f"INFILE: {INFILE}")
    print(f"OUTFILE: {out_path}")
    print(f"Daily rows read: {len(daily)}")
    print(f"Monthly quantile rows written: {len(qtbl)}")


if __name__ == "__main__":
    main()
EOF

exit
