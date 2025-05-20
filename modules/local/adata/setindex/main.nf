process ADATA_SETINDEX {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/anndata_pyyaml:5f82ece6392dc30c'
        : 'community.wave.seqera.io/library/anndata_pyyaml:b30e03a395613673'}"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    column = task.ext.column ?: null
    axis = task.ext.axis ?: "obs"
    if (column == null) {
        error("Column is required, use \"task.ext.column\" to set it!")
    }
    if (!(axis in ["obs", "var"])) {
        error("Axis must be either 'obs' or 'var', but got '${axis}'! Use \"task.ext.axis\" to set it!")
    }
    if ("${prefix}.h5ad" == "${h5ad}") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }
    template('setindex.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
