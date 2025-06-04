#!/usr/bin/env python3

import os
import platform
import yaml

os.environ["MPLCONFIGDIR"] = "./tmp/mpl"
os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"

import scanpy as sc
import pandas as pd
import scanpy.external as sce

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))

adata = sc.read_h5ad("${h5ad}")

adata_processing = adata.copy()

if "${counts_layer}" != "X":
    adata_processing.X = adata.layers["${counts_layer}"]

sc.pp.log1p(adata_processing)
sc.pp.pca(adata_processing)
sce.pp.harmony_integrate(adata_processing, "${batch_col}", adjusted_basis="X_emb")

# Round to avoid floating point precision issues
# This ensures hashes are consistent
emb = adata_processing.obsm["X_emb"].round(6)
adata.obsm["X_emb"] = emb

adata.write_h5ad("${prefix}.h5ad")

df = pd.DataFrame(emb, index=adata.obs_names)
df.to_pickle("X_${prefix}.pkl")

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
