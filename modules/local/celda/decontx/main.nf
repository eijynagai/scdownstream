process CELDA_DECONTX {
    tag "$meta.id"
    label 'process_medium'

    container "wave.seqera.io/wt/a7c563682913/wave/build:c805fdf0a2290cf2"

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
