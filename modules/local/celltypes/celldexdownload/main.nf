process CELLTYPES_CELLDEXDOWNLOAD {
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/bioconductor-celldex_bioconductor-hdf5array_bioconductor-singlecellexperiment_r-yaml:c4e76f99d7b45118':
        'community.wave.seqera.io/library/bioconductor-celldex_bioconductor-hdf5array_bioconductor-singlecellexperiment_r-yaml:13bf33457e3e7490' }"

    input:
    val(ref)

    output:
    path("celldex_${ref}_h5_se/assays.h5"), emit: h5
    path("celldex_${ref}_h5_se/se.rds"),    emit: rds
    path("celldex_${ref}_h5_se"),           emit: refdir
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template("celldexDownload.R")

    stub:
    def args = task.ext.args ?: ''

    """
    mkdir -p celldex_${ref}_h5_se
    touch "celldex_${ref}_h5_se/assays.h5"
    touch "celldex_${ref}_h5_se/se.rds"
    """
}
