process SCIMILARITY_PSEUDOBULK {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/gcc_gxx_pyyaml_zarr_pruned:049c63c0e0a999fa'
        : 'community.wave.seqera.io/library/gcc_gxx_pyyaml_zarr_pruned:8912afd95c57731a'}"

    input:
    tuple val(meta), path(h5ad)
    val(counts_layer)
    val(groupby_labels)
    val(min_num_cells)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"

    if ("${prefix}.h5ad" == "${h5ad}") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }

    template('pseudobulk.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
