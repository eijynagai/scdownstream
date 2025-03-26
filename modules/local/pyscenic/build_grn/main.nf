process PYSCENIC_GRN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pyscenic_multicore-tsne_python_scanpy_seaborn:dd8689fb27b6135b':
        'community.wave.seqera.io/library/pyscenic_multicore-tsne_python_scanpy_seaborn:196ca9be7b659658'}"

    input:
    tuple val(meta), path(h5ad)
    path(tfs)

    output:
    path "*_modules.pkl"                   , emit: modules
    path "versions.yml"                    , emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template 'infer_grn.py'
}
