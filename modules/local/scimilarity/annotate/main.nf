process SCIMILARITY_ANNOTATE {
    tag "$meta.id"
    label 'process_medium'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/gcc_gxx_zarr_pip_scimilarity:ff19dd7542203afd':
        'community.wave.seqera.io/library/gcc_gxx_zarr_pip_scimilarity:0d43350a5e8f0759' }"

    input:
    tuple val(meta), path(h5ad)
    tuple val(meta2), path(model)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path("${prefix}.pkl")                  , emit: obs
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    if ("${prefix}.h5ad" == "${h5ad}")
        error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"

    template 'annotate.py'
}
