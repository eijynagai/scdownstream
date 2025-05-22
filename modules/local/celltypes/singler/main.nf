process CELLTYPES_SINGLER {
    tag "$meta.id"
    label 'process_medium'

    //conda "${moduleDir}/environment.yml"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //   'docker://saditya88/singler:0.0.1':
    //    'saditya88/singler:0.0.1' }"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://paulpyl/scqc/singler:latest':
        'paulpyl/scqc/singler:latest' }"


    input:
    tuple val(meta), path(h5ad)
    path(reference)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "*.pdf"                   , emit: pdf
    path "*.csv"                   , emit: obs
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'singleR.R'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch ${prefix}.pdf
    touch ${prefix}.csv
    touch versions.yml
    """
}
