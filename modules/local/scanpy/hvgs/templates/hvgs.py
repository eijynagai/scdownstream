#!/usr/bin/env python3

import os
import platform
from threadpoolctl import threadpool_limits

os.environ["MPLCONFIGDIR"] = "./tmp/mpl"
os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"

import scanpy as sc
import yaml

threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

adata = sc.read_h5ad("${h5ad}")
prefix = "${prefix}"
n_hvgs = int("${n_hvgs}")
use_gpu = "${task.ext.use_gpu}" == "true"
batch_key = "${batch_key}"

if adata.n_vars > n_hvgs and n_hvgs >= 0:
    kwargs = {}

    if batch_key:
        kwargs["batch_key"] = batch_key

    # If an actual limit is provided, use it
    # Otherwise, scanpy will automatically determine the number of highly variable genes
    if n_hvgs > 0:
        kwargs["n_top_genes"] = n_hvgs

    raw_counts = adata.X.copy()

    if use_gpu:
        os.environ["CUPY_CACHE_DIR"] = "./tmp/cupy"

        import rapids_singlecell as rsc
        import rmm
        from rmm.allocators.cupy import rmm_cupy_allocator
        import cupy as cp
        rmm.reinitialize(
            managed_memory=True,
            pool_allocator=False,
        )
        cp.cuda.set_allocator(rmm_cupy_allocator)

        rsc.get.anndata_to_GPU(adata)

        rsc.pp.log1p(adata)
        rsc.pp.highly_variable_genes(adata, **kwargs)

        rsc.get.anndata_to_CPU(adata)
    else:
        sc.pp.log1p(adata)
        sc.pp.highly_variable_genes(adata, **kwargs)

    adata.X = raw_counts
    adata = adata[:, adata.var["highly_variable"]]

adata.write_h5ad(f"{prefix}.h5ad")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scanpy": sc.__version__
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
