process CELLDEX_FETCHREFERENCE {
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'oras://community.wave.seqera.io/library/bioconductor-celldex_bioconductor-hdf5array_bioconductor-singlecellexperiment_r-yaml:c4e76f99d7b45118'
        : 'community.wave.seqera.io/library/bioconductor-celldex_bioconductor-hdf5array_bioconductor-singlecellexperiment_r-yaml:13bf33457e3e7490'}"

    input:
    tuple val(meta), val(ref)

    output:
    tuple val(meta), path("celldex_${ref}_h5_se.tar.gz"), emit: tar
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template("celldexDownload.R")

    stub:
    """
    touch "celldex_${ref}_h5_se.tar.gz"
    """
}
