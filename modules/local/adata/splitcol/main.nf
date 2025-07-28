process ADATA_SPLITCOL {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/anndata_pyyaml:5f82ece6392dc30c'
        : 'community.wave.seqera.io/library/anndata_pyyaml:b30e03a395613673'}"

    input:
    tuple val(meta), path(h5ad)
    val column

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template('split_column.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch A.h5ad
    touch B.h5ad
    touch versions.yml
    """
}
