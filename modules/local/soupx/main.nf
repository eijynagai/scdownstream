process SOUPX {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/nicotru/soupx:f6297681695fbfcf"

    input:
    tuple val(meta), path(h5ad), path(raw)
    val(input_layer)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    cluster_resolution = task.ext.cluster_resolution ?: 0.8
    output_layer = task.ext.output_layer ?: "ambient_corrected"
    template 'soupx.R'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
