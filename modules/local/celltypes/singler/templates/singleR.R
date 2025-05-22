#!/usr/bin/env Rscript

library(SingleR)
library(celldex)
library(yaml)
library(Seurat)
library(ggplot2)
library(anndataR)
library(HDF5Array)

# Function to convert a list to a YAML-like structure, as before
format_yaml_like <- function(data, indent = 0) {
  yaml_str <- ""
  for (key in names(data)) {
    spaces <- strrep("  ", indent)
    value <- data[[key]]
    if (is.list(value)) {
      yaml_str <- paste0(yaml_str, spaces, key, ":\n",
                         format_yaml_like(value, indent + 1))
    } else {
      yaml_str <- paste0(yaml_str, spaces, key, ": ", value, "\n")
    }
  }
  return(yaml_str)
}
# Read .h5ad file using zellkonverter
h5ad_file <- "${h5ad}" # Get the filename from environment variable
sce <- read_h5ad(h5ad_file, as = "SingleCellExperiment") # Converts .h5ad to a SingleCellExperiment object

# Split the references by comma and loop over each
references <- strsplit("${reference}", ",")[[1]]
prefix <- "${prefix}"
Sys.setenv(XDG_CACHE_HOME = file.path(getwd(), ".cache"))
for (ref in references) {
  ref <- trimws(ref)
  ref_name <- strsplit(ref, "__")[[1]][1]
  ref_ver <- strsplit(ref, "__")[[1]][2]
  # Read the SummarizedExperiment object from the provided path
  print("${reference}")
  print(list.files("${reference}"))
  reference <- loadHDF5SummarizedExperiment(dir = "${reference}")
  predictions <- SingleR(test = assay(sce, 'counts'), ref = reference, labels = colData(reference)[['label.main']]) #TODO make the label column name a parameter that defaults to label.main

  # Save predictions as CSV file
  write.csv(predictions, file = paste0(prefix, "_", ref, "_predictions.csv"), row.names = TRUE)

  # Unique column names for each reference
  pred_col <- paste0("SingleR_", ref_name, "_", ref_ver)
  score_col <- paste0("SingleR_score_", ref_name, "_", ref_ver)

  # Add predictions and scores to the SingleCellExperiment object
  colData(sce)[[pred_col]] <- predictions\$labels
  scores <- predictions\$scores
  single_scores <- vapply(
    seq_len(nrow(scores)),
    FUN = function(i) scores[i, predictions\$labels[i]],
    FUN.VALUE = numeric(1)
  )
  colData(sce)[[score_col]] <- single_scores

  # Plot and save heatmap
  p <- plotScoreHeatmap(predictions,
                        main = paste0("SingleR Predictions: ", basename(h5ad_file), " [", ref, "]"),
                        show_rownames = TRUE,
                        show_colnames = FALSE)
  ggsave(filename = paste0(prefix, "_", ref, "_heatmap.pdf"), plot = p, width = 10, height = 8)

  # Plot and save distribution
  p2 <- plotDeltaDistribution(predictions, ncol = 3)
  p2 <- p2 + ggtitle(paste0("SingleR Predictions: ", basename(h5ad_file), " [", ref, "]"))
  ggsave(filename = paste0(prefix, "_", ref, "_distribution.pdf"), plot = p2, width = 14, height = 12)
}

# Capturing version information, as before
versions <- list(
  "${task.process}" = list(
    R = R.version.string,
    SingleR = as.character(packageVersion("SingleR")),
    celldex = as.character(packageVersion("celldex")),
    anndataR = as.character(packageVersion("anndataR")),
    yaml = as.character(packageVersion("yaml")),
    Seurat = as.character(packageVersion("Seurat")),
    ggplot2 = as.character(packageVersion("ggplot2"))
  )
)

# Delete the Rplots.pdf file if it exists
if (file.exists("Rplots.pdf")) {
  file.remove("Rplots.pdf")
}
write_h5ad(sce, path = paste0(prefix, ".h5ad"), mode = "w") # Save the SingleCellExperiment object as h5ad
# Write versions info into a YAML file, as before
write(format_yaml_like(versions), file = "versions.yml")
