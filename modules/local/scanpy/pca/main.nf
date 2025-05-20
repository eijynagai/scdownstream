process SCANPY_PCA {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/scanpy-cli:0.1.6--6ce8e193a0ecbf8a':
        'community.wave.seqera.io/library/scanpy-cli:0.1.6--f0a9e6aaa5c7abbd' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    args = task.ext.args ?: ""

    if ("${prefix}.h5ad" == "${h5ad}")
        error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    export MPLCONFIGDIR=./tmp/mpl
    export NUMBA_CACHE_DIR=./tmp
    scanpy-cli pp pca -i ${h5ad} -o ${prefix}.h5ad ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scanpy-cli: \$(scanpy-cli --version | grep -oP '(?<=version )[\d.]+')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
