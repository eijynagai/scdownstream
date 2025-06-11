#!/usr/bin/env python3

import os
import platform

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

import scanpy as sc
import numpy as np
import pandas as pd
import yaml

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

adata = sc.read_h5ad("${h5ad}", backed='r')
prefix = "${prefix}"

sc.tl.umap(adata, random_state=0)

# Round to 10 decimal places
# This ensures hashes are stable
adata.obsm["X_umap"] = np.round(adata.obsm["X_umap"], 10)

adata.write_h5ad(f"{prefix}.h5ad")
df = pd.DataFrame(adata.obsm["X_umap"], index=adata.obs_names)
df.to_pickle(f"X_{prefix}.pkl")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scanpy": sc.__version__,
        "pandas": pd.__version__
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
