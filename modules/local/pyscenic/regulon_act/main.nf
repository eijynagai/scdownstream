process PYSCENIC_REG_ACT {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/scanpy:1.10.4--c2d474f46255931c':
        'community.wave.seqera.io/library/scanpy:1.10.4--f905699eb17b6536' }"

    input:
    tuple val(meta), path(h5ad)
    path (regulons)

    output:
    path "*_auc.csv"                   , emit: regulons_act
    path "versions.yml"                , emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'aucell_activity.py'
}
