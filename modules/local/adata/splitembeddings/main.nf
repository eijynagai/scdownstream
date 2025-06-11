process ADATA_SPLITEMBEDDINGS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ba/baee2c1ee0f6cd0b6a18a6c71bad03370139a77e53cad06464b065f795d52cd0/data'
        : 'community.wave.seqera.io/library/pyyaml_scanpy:a3a797e09552fddc'}"

    input:
    tuple val(meta), path(h5ad)
    val embeddings

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    template('split_embeddings.py')
}
