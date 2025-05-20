#!/usr/bin/env python3

import platform
import anndata as ad
import pandas as pd
import yaml

adata = ad.read_h5ad("${h5ad}", backed='r')

with open("${prefix}.txt", "w") as f:
    f.write(f"{adata.n_obs}")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "anndata": ad.__version__,
        "pandas": pd.__version__
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
