process CELLTYPES_SINGLER {
    tag "$meta.id"
    label 'process_medium'

    container 'docker.io/saditya88/singler:0.0.1'


    input:
    tuple val(meta), path(h5ad)
    path(reference)
    val(label)

    output:
    //tuple val(meta), path("*.h5ad"), emit: h5ad
    path "*.pdf"                   , emit: pdf
    tuple val(meta), path("*.csv") , emit: obs
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'singleR.R'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    //touch ${prefix}.h5ad
    """
    touch ${prefix}.pdf
    touch ${prefix}.csv
    touch versions.yml
    """
}
