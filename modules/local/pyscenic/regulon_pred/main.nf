process PYSCENIC_REG_PRED {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pyscenic_multicore-tsne_python_scanpy_seaborn:dd8689fb27b6135b':
        'community.wave.seqera.io/library/pyscenic_multicore-tsne_python_scanpy_seaborn:196ca9be7b659658'}"

    input:
    tuple val(meta), path (modules)
    path(rfr_db)
    path(motif_annot)

    output:
    path "*_motifs.csv"                    , emit: motifs
    path "*_regulons.pkl"                  , emit: regulons 
    path "versions.yml"                    , emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'reg_pred.py'
}
