process PYSCENIC_GRN {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? 
'oras://community.wave.seqera.io/library/pyscenic_python_scanpy_seaborn:b21cfb7c2f6485bb': 
'community.wave.seqera.io/library/pyscenic_python_scanpy_seaborn:6d42591d8f323124'}"

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
