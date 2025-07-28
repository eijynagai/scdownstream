#!/usr/bin/env python3

import platform
import anndata as ad
import yaml

adata = ad.read_h5ad("$h5ad")

axis = "$axis"
column = "$column"

df = adata.obs if axis == "obs" else adata.var

assert column in df.columns, f"Column '{column}' not found in {axis}"
df.index = df[column]

if axis == "obs":
    adata.obs = df
else:
    adata.var = df

adata.write_h5ad("${prefix}.h5ad")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "anndata": ad.__version__,
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
