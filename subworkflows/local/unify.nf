include { ADATA_MYGENE as MYGENE              } from '../../modules/local/adata/mygene'
include { ADATA_SETINDEX as SET_INDEX         } from '../../modules/local/adata/setindex'
include { ADATA_UPSETGENES as UPSET_GENES_RAW } from '../../modules/local/adata/upsetgenes'
include { UNIFY_GENES                         } from './unify_genes'
include { ADATA_UPSETGENES as UPSET_GENES     } from '../../modules/local/adata/upsetgenes'
include { ADATA_UNIFY                         } from '../../modules/local/adata/unify'

workflow UNIFY {
    take:
    ch_h5ad // channel: [ meta, h5ad ]

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_h5ad = ch_h5ad.branch { meta, _h5ad ->
        has_symbol_col: meta.symbol_col != "none"
        needs_symbol_conversion: true
    }

    MYGENE(ch_h5ad.needs_symbol_conversion)
    ch_versions = ch_versions.mix(MYGENE.out.versions)
    ch_h5ad = ch_h5ad.has_symbol_col.mix(
        MYGENE.out.h5ad.map { meta, h5ad -> [meta + [symbol_col: 'symbols'], h5ad] }
    )

    if (params.unify_gene_symbols) {
        ch_h5ad = ch_h5ad.branch { meta, _h5ad ->
            has_symbols_as_index: meta.symbol_col == "index"
            needs_index_updating: true
        }

        SET_INDEX(ch_h5ad.needs_index_updating)
        ch_versions = ch_versions.mix(SET_INDEX.out.versions)
        ch_h5ad = ch_h5ad.has_symbols_as_index.mix(
            SET_INDEX.out.h5ad.map { meta, h5ad -> [meta + [symbol_col: 'index'], h5ad] }
        )

        UPSET_GENES_RAW(ch_h5ad.map { meta, h5ad -> [[id: 'upset_raw'], meta.id, h5ad] }.groupTuple())
        ch_versions = ch_versions.mix(UPSET_GENES_RAW.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(UPSET_GENES_RAW.out.multiqc_files)

        UNIFY_GENES(ch_h5ad)
        ch_h5ad = UNIFY_GENES.out.h5ad
        ch_versions = ch_versions.mix(UNIFY_GENES.out.versions)
    }

    ADATA_UNIFY(ch_h5ad)
    ch_h5ad = ADATA_UNIFY.out.h5ad
    ch_versions = ch_versions.mix(ADATA_UNIFY.out.versions)

    UPSET_GENES(ch_h5ad.map { meta, h5ad -> [[id: 'upset'], meta.id, h5ad] }.groupTuple())
    ch_versions = ch_versions.mix(UPSET_GENES.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(UPSET_GENES.out.multiqc_files)

    emit:
    h5ad          = ch_h5ad          // channel: [ meta, h5ad ]
    multiqc_files = ch_multiqc_files // channel: [ json ]
    versions      = ch_versions      // channel: [ versions.yml ]
}
