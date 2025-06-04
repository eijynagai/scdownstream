#!/usr/bin/env Rscript

library(anndataR)
library(celda)

# Read the AnnData object
adata <- read_h5ad("${h5ad}")

# Convert to SingleCellExperiment
sce <- adata\$as_SingleCellExperiment()

# Prepare parameters for decontX
params <- list()
params\$assayName <- "${input_layer == 'X' ? 'counts' : input_layer}"

# Handle batch information if available
batch_col <- "${batch_col}"
if (batch_col != "" && length(unique(adata\$obs[[batch_col]])) > 1) {
    params\$batch <- adata\$obs[[batch_col]]
}

# Handle background data if available
raw_path <- "${raw}"
if (file.exists(raw_path)) {
    raw <- read_h5ad(raw_path)
    params\$background <- raw\$as_SingleCellExperiment()
}

# Run decontX with parameters
corrected <- do.call(decontX, c(list(sce), params))

adata_corrected <- as_AnnData(corrected)

# Convert back to AnnData and update layers
adata\$layers["${output_layer}"] <- adata_corrected\$layers["decontXcounts"]

# Save the output
write_h5ad(adata, "${prefix}.h5ad")

# Write version information
writeLines(
    c(
        '"${task.process}":',
        paste('    r:', paste(version\$major, version\$minor, sep = ".")),
        paste('    anndataR:', as.character(packageVersion('anndataR'))),
        paste('    celda:', as.character(packageVersion('celda')))
    ),
'versions.yml')
