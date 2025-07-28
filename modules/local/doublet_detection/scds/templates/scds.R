#!/usr/bin/env Rscript

library(scds)
library(SingleCellExperiment)
library(anndataR)

Sys.setenv(TMP = ".")

set.seed(0)

adata <- read_h5ad("${h5ad}")
sce <- adata\$as_SingleCellExperiment()

## Annotate doublet using binary classification based doublet scoring:
sce <- bcds(sce, retRes = TRUE, estNdbl=TRUE)

## Annotate doublet using co-expression based doublet scoring:
try({
    sce <- cxds(sce, retRes = TRUE, estNdbl=TRUE)
})

### If cxds worked, run hybrid, otherwise use bcds annotations
if ("cxds_score" %in% colnames(colData(sce))) {
    ## Combine both annotations into a hybrid annotation
    sce <- cxds_bcds_hybrid(sce, estNdbl=TRUE)

    predictions <- colData(sce)[, 'hybrid_call', drop=FALSE]
} else {
    predictions <- colData(sce)[, 'bcds_call', drop=FALSE]
}

adata_processed <- as_AnnData(sce)
write_h5ad(adata_processed, "${prefix}.h5ad")

colnames(predictions) <- "${prefix}"
write.csv(predictions, "${prefix}.csv")

################################################
################################################
## VERSIONS FILE                              ##
################################################
################################################

r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
scds.version <- as.character(packageVersion('scds'))

writeLines(
    c(
        '"${task.process}":',
        paste('    R:', r.version),
        paste('    scds:', scds.version)
    ),
'versions.yml')

################################################
################################################
################################################
################################################
