#!/usr/bin/env python3

import os
import json
import platform
import base64
import pickle

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

import scanpy as sc
import pandas as pd
import matplotlib.pyplot as plt
import yaml

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

adata = sc.read_h5ad("${h5ad}")
prefix = "${prefix}"

kwargs = {
    "groupby": "${obs_key}",
    "pts": True
}

if adata.obs["${obs_key}"].value_counts().size > 1:
    sc.pp.log1p(adata)
    sc.tl.rank_genes_groups(adata, **kwargs)

    rgg_dict = adata.uns["rank_genes_groups"]

    pickle.dump(rgg_dict, open(f"{prefix}.pkl", "wb"))
    adata.write_h5ad(f"{prefix}.h5ad")

    # Plot
    sc.pl.rank_genes_groups(adata, show=False)
    path = f"{prefix}.png"
    plt.savefig(path)

    # MultiQC
    with open(path, "rb") as f_plot, open("${prefix}_mqc.json", "w") as f_json:
        image_string = base64.b64encode(f_plot.read()).decode("utf-8")
        image_html = f'<div class="mqc-custom-content-image"><img src="data:image/png;base64,{image_string}" /></div>'

        custom_json = {
            "id": "${prefix}",
            "parent_id": "${meta.integration}",
            "parent_name": "${meta.integration}",
            "parent_description": "Results of the ${meta.integration} integration.",

            "section_name": "${meta.id} characteristic genes",
            "plot_type": "image",
            "data": image_html,
        }

        json.dump(custom_json, f_json)
else:
    print("Skipping rank_genes_groups computation as the group has less than 2 unique values.")

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
