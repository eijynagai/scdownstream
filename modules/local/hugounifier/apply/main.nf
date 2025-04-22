process HUGOUNIFIER_APPLY {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pip_hugo-unifier:98cad6c07a357a66':
        'wave.seqera.io/wt/7231f9ebfc62/wave/build:pip_hugo-unifier-0.2.4--323130be100e102e' }"

    input:
    tuple val(meta), path(h5ad, arity: 1), path(changes, arity: 1)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path("versions.yml")                   , emit: versions


    script:
    prefix = task.ext.prefix ?: meta.id
    """
    hugo-unifier apply -i ${h5ad} -c ${changes} -o ${prefix}.h5ad

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hugo-unifier: \$(hugo-unifier --version | grep -oP '(?<=version )[\\d.]+')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
