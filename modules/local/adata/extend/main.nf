process ADATA_EXTEND {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/anndata_pyyaml:5f82ece6392dc30c'
        : 'community.wave.seqera.io/library/anndata_pyyaml:b30e03a395613673'}"

    input:
    tuple val(meta), path(base), path(obs), path(var), path(obsm), path(obsp), path(uns), path(layers)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    tuple val(meta), path("*.csv"), emit: metadata
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template('extend.py')
}
