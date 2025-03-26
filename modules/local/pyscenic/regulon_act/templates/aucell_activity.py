#!/usr/bin/env python3

import os
import platform
import pickle
import scanpy as sc
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

from pyscenic.aucell import aucell
from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

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

h5ad_input = "${h5ad}"
regulons_file = "${regulons}"
prefix = "${prefix}"
auc_output = "${prefix}_auc.csv"

adata = sc.read_h5ad(h5ad_input)
print(f"AnnData shape: {adata.shape} (cells x genes)")

ex_matrix = adata.to_df()
print(f"Expression matrix shape: {ex_matrix.shape}")

with open(regulons_file, "rb") as f:
    regulons = pickle.load(f)
print(f"Loaded {len(regulons)} regulons from {regulons_file}")

auc_mtx = aucell(ex_matrix, regulons, num_workers=int("${task.cpus}"))
print(f"AUCell matrix shape: {auc_mtx.shape}")

auc_mtx.to_csv(auc_output)
print(f"AUC matrix saved to {auc_output}")

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scanpy": sc.__version__,
        "pandas": pd.__version__,
    }
}
with open("versions.yml", "w") as vf:
    vf.write(format_yaml_like(versions))