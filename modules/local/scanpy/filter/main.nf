process SCANPY_FILTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pyyaml_scanpy:158b12038812cf13':
        'community.wave.seqera.io/library/pyyaml_scanpy:61c9ab8e312bbe0a' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    min_genes           = task.ext.min_genes ?: 0
    min_cells           = task.ext.min_cells ?: 0
    min_counts_gene     = task.ext.min_counts_gene ?: 0
    min_counts_cell     = task.ext.min_counts_cell ?: 0
    max_mito_percentage = task.ext.max_mito_percentage ?: 100

    prefix = task.ext.prefix ?: "${meta.id}"

    if ("${prefix}.h5ad" == "${h5ad}") {
        error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    }
    template 'filter.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
