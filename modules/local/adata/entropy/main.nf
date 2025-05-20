process ADATA_ENTROPY {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pyyaml_scanpy:158b12038812cf13':
        'community.wave.seqera.io/library/pyyaml_scanpy:61c9ab8e312bbe0a' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "*.pkl"                   , emit: obs
    path "*.png"                   , emit: plots, optional: true
    path "*_mqc.json"              , emit: multiqc_files, optional: true
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    group_col = task.ext.group_col ?: "leiden"
    entropy_col = task.ext.entropy_col ?: "batch"
    template 'entropy.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch ${prefix}.pkl
    touch ${prefix}.png
    touch ${prefix}_mqc.json
    touch versions.yml
    """
}
