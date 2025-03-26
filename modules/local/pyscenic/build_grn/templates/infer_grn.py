#!/usr/bin/env python3

import os
import platform
import pickle
import scanpy as sc
import pandas as pd

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

from arboreto.utils import load_tf_names
from arboreto.algo import grnboost2
from pyscenic.utils import modules_from_adjacencies

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

def format_yaml_like(data: dict, indent: int = 0) -> str:
    """Formats a dictionary to a YAML-like string.

    Args:
        data (dict): The dictionary to format.
        indent (int): The current indentation level.

    Returns:
        str: A string formatted as YAML.
    """
    yaml_str = ""
    for key, value in data.items():
        spaces = "  " * indent
        if isinstance(value, dict):
            yaml_str += f"{spaces}{key}:\\n{format_yaml_like(value, indent + 1)}"
        else:
            yaml_str += f"{spaces}{key}: {value}\\n"
    return yaml_str


h5ad_input = "${h5ad}"
prefix = "${prefix}"
TF_FILE = "${tfs}"
MODULES_FNAME = "${prefix}_modules.pkl"

adata = sc.read_h5ad(h5ad_input)
ex_matrix = adata.to_df()

tf_names = load_tf_names(TF_FILE)

adjacencies = grnboost2(ex_matrix, tf_names=tf_names, verbose=True)

modules = list(modules_from_adjacencies(adjacencies, ex_matrix))

with open(MODULES_FNAME, "wb") as f:
    pickle.dump(modules, f)

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scanpy": sc.__version__,
        "pandas": pd.__version__,
    }
}
with open("versions.yml", "w") as vf:
    vf.write(format_yaml_like(versions))