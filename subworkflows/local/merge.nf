include { UNIFY_GENES } from './unify_genes'

workflow MERGE {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    if (params.unify_gene_symbols) {
        UNIFY_GENES(ch_h5ad)
        ch_h5ad = UNIFY_GENES.out.h5ad
        ch_versions = ch_versions.mix(UNIFY_GENES.out.versions)
    }

    emit:
    h5ad          = ch_h5ad
    multiqc_files = ch_multiqc_files
    versions      = ch_versions
}