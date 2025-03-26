#!/usr/bin/env python3

import os
import platform
import glob
import pickle
import pandas as pd

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

from ctxcore.rnkdb import FeatherRankingDatabase as RankingDatabase
from pyscenic.prune import prune2df, df2regulons
from pyscenic.utils import load_motifs

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))

def format_yaml_like(data: dict, indent: int = 0) -> str:
    """Formats a dictionary to a YAML-like string."""
    yaml_str = ""
    for key, value in data.items():
        spaces = "  " * indent
        if isinstance(value, dict):
            yaml_str += f"{spaces}{key}:\n{format_yaml_like(value, indent + 1)}"
        else:
            yaml_str += f"{spaces}{key}: {value}\n"
    return yaml_str


prefix = "${prefix}"
NUM_WORKERS = "${task.cpus}"
DATABASES_GLOB = "${rfr_db}".split(" ")
MODULES_FNAME = "${modules}"
MOTIF_ANNOTATIONS_FNAME = "${motif_annot}"


# Output files: motifs & regulons
MOTIFS_FNAME = f"{prefix}_motifs.csv"
REGULONS_FNAME = f"{prefix}_regulons.pkl"

with open(MODULES_FNAME, "rb") as f:
    modules = pickle.load(f)
print(f"Loaded {len(modules)} modules from {MODULES_FNAME}")

def name(fname):
    return os.path.splitext(os.path.basename(fname))[0]

db_fnames = DATABASES_GLOB
dbs = [RankingDatabase(fname=f, name=name(f)) for f in db_fnames]
print(f"Found {len(dbs)} ranking databases under {DATABASES_GLOB}")

df = prune2df(
    rnkdbs=dbs,
    modules=modules,
    motif_annotations_fname=MOTIF_ANNOTATIONS_FNAME,
    filter_for_annotation=True,
    num_workers=NUM_WORKERS
)
print(f"prune2df complete. Motif enrichment DataFrame: {df.shape}")

regulons = df2regulons(df)
print(f"Total regulons: {len(regulons)}")

df.to_csv(MOTIFS_FNAME, index=False)
print(f"Saved motif table to {MOTIFS_FNAME}")

with open(REGULONS_FNAME, "wb") as f:
    pickle.dump(regulons, f)
print(f"Saved regulons to {REGULONS_FNAME}")

df_check = load_motifs(MOTIFS_FNAME)
print(f"Reloaded motifs shape: {df_check.shape}")

with open(REGULONS_FNAME, "rb") as f:
    regs_check = pickle.load(f)
print(f"Reloaded regulons count: {len(regs_check)}")

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "pandas": pd.__version__
    }
}
with open("versions.yml", "w") as vf:
    vf.write(format_yaml_like(versions))