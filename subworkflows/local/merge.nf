include { ADATA_MYGENE as MYGENE              } from '../../modules/local/adata/mygene'
include { ADATA_UPSETGENES as UPSET_GENES_RAW } from '../../modules/local/adata/upsetgenes'
include { UNIFY_GENES                         } from './unify_genes'
include { ADATA_UPSETGENES as UPSET_GENES     } from '../../modules/local/adata/upsetgenes'
include { ADATA_UNIFY                         } from '../../modules/local/adata/unify'
include { ADATA_MERGE                         } from '../../modules/local/adata/merge'

workflow MERGE {
    take:
    ch_h5ad
    ch_base

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_var = Channel.empty()

    ch_h5ad = ch_h5ad.branch { meta, _h5ad ->
        has_symbol_col: meta.symbol_col != "none"
        needs_symbol_conversion: true
    }

    MYGENE(ch_h5ad.needs_symbol_conversion)
    ch_versions = ch_versions.mix(MYGENE.out.versions)
    ch_h5ad = ch_h5ad.has_symbol_col.mix(
        MYGENE.out.h5ad.map{meta, h5ad -> [meta + [symbol_col: 'symbols'], h5ad]}
    )

    if (params.unify_gene_symbols) {
        UPSET_GENES_RAW(ch_h5ad.map { meta, h5ad -> [[id: 'upset_raw'], meta.id, h5ad] }.groupTuple())
        ch_versions = ch_versions.mix(UPSET_GENES_RAW.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(UPSET_GENES_RAW.out.multiqc_files)

        UNIFY_GENES(ch_h5ad)
        ch_h5ad = UNIFY_GENES.out.h5ad
        ch_versions = ch_versions.mix(UNIFY_GENES.out.versions)
    }

    UPSET_GENES(ch_h5ad.map { meta, h5ad -> [[id: 'upset'], meta.id, h5ad] }.groupTuple())
    ch_versions = ch_versions.mix(UPSET_GENES.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(UPSET_GENES.out.multiqc_files)

    ADATA_UNIFY(ch_h5ad)
    ch_h5ad = ADATA_UNIFY.out.h5ad
    ch_versions = ch_versions.mix(ADATA_UNIFY.out.versions)

    ADATA_MERGE(
        ch_h5ad.map { _meta, h5ad -> [[id: "merged"], h5ad] }.groupTuple(),
        ch_base,
    )
    ch_var = ch_var.mix(ADATA_MERGE.out.intersect_genes)
    ch_outer = ADATA_MERGE.out.outer
    ch_versions = ch_versions.mix(ADATA_MERGE.out.versions)

    emit:
    h5ad          = ch_h5ad
    multiqc_files = ch_multiqc_files
    versions      = ch_versions
}
