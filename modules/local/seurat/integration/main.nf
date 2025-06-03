process SEURAT_INTEGRATION {
    tag "${meta.id}"
    label 'process_medium'

    container "wave.seqera.io/wt/393c85f00b50/wave/build:7ae5cb50170b43af"

    input:
    tuple val(meta), path(h5ad)
    val(batch_col)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml", emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template('integration.R')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.h5ad"
    touch "versions.yml"
    """
}
