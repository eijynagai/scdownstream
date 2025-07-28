process SCANPY_PLOTQC {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ba/baee2c1ee0f6cd0b6a18a6c71bad03370139a77e53cad06464b065f795d52cd0/data'
        : 'community.wave.seqera.io/library/pyyaml_scanpy:a3a797e09552fddc'}"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.png"), emit: plots
    path ("*_mqc.json"), emit: multiqc_files
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    section_name = task.ext.section_name ?: "QC Plots"
    description = task.ext.description ?: "Quality control plots"
    template('plotqc.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    section_name = task.ext.section_name ?: "QC Plots"
    description = task.ext.description ?: "Quality control plots"
    """
    touch ${prefix}_total_counts_vs_n_genes_by_counts.png
    touch ${prefix}_mqc.json
    touch versions.yml
    """
}
