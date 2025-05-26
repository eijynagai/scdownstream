#!/usr/bin/env Rscript
# -*- coding: utf-8 -*-
library(celldex)
library(SingleCellExperiment)
library(yaml)
library(HDF5Array)
r="${ref}"
print(paste("Attempting to fetch reference:", r))
# Split the reference into refName and refVersion based on __
refName <- strsplit(r, "__")[[1]][1]
refVersion <- strsplit(r, "__")[[1]][2]
reference <- fetchReference(refName, refVersion, cache = "./")
# Save SummarizedExperiment to HDF5 files
saveHDF5SummarizedExperiment(reference, dir=paste0("celldex_", r, "_h5_se"), replace = TRUE)


# Capturing version information, as before
versions <- list(
    "${task.process}" = list(
        R = R.version.string,
        celldex = as.character(packageVersion("celldex")),
        yaml = as.character(packageVersion("yaml")),
        HDF5Array = as.character(packageVersion("HDF5Array"))
    )
)
# Write versions info into a YAML file, as before
write_yaml(x = versions, file = "versions.yml")