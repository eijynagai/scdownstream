process ADATA_UNIFY {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/anndata_pyyaml:5f82ece6392dc30c':
        'community.wave.seqera.io/library/anndata_pyyaml:b30e03a395613673' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    duplicate_var_resolution = task.ext.duplicate_var_resolution ?: "make_unique"
    batch_col = task.ext.batch_col ?: "batch"
    label_col = task.ext.label_col ?: ""
    unknown_label = task.ext.unknown_label ?: "unknown"
    symbol_col = task.ext.symbol_col ?: "index"
    counts_layer = task.ext.counts_layer ?: "X"
    template 'unify.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
