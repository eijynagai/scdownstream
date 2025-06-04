process CELDA_DECONTX {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/nicotru/celda:1d48a68e9d534b2b"

    input:
    tuple val(meta), path(h5ad), path(raw)
    val(batch_col)
    val(input_layer)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    output_layer = task.ext.output_layer ?: "decontXcounts"
    template 'decontx.R'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
