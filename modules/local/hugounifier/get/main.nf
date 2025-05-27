process HUGOUNIFIER_GET {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pip_hugo-unifier:3e1901cbb7f39dfc':
        'community.wave.seqera.io/library/pip_hugo-unifier:6d176a11f2d9defb' }"

    input:
    tuple val(meta), val(names), path(h5ads, stageAs: 'input/file_?.h5ad')

    output:
    tuple val(meta), path("${meta.id}/*.csv"), emit: changes
    path("versions.yml")                     , emit: versions


    script:
    def namedFiles = [[names].flatten(), [h5ads].flatten()].transpose()
    def input = namedFiles.collect { name, h5ad -> "-i ${name}:${h5ad}" }.join(' ')
    """
    hugo-unifier get -o ${meta.id} ${input}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hugo-unifier: \$(hugo-unifier --version | grep -oP '(?<=version )[\\d.]+')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${meta.id}

    for name in ${names.join(' ')}; do
        touch ${meta.id}/\${name}.csv
    done

    touch versions.yml
    """
}
