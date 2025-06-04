include { CELDA_DECONTX               } from '../../modules/local/celda/decontx'
include { CELLBENDER_REMOVEBACKGROUND } from '../../modules/nf-core/cellbender/removebackground'
include { CELLBENDER_MERGE            } from '../../modules/nf-core/cellbender/merge'
include { SOUPX                       } from '../../modules/local/soupx'
include { SCVITOOLS_SCAR              } from '../../modules/nf-core/scvitools/scar'

workflow AMBIENT_RNA_REMOVAL {
    take:
    ch_pairing // channel: [ meta, h5ad, h5ad ]
    method     // value: string

    main:
    ch_versions = Channel.empty()

    ch_multi = ch_pairing.multiMap { meta, filtered, unfiltered ->
        input: [meta, filtered, unfiltered]
        batch_col: meta.batch_col ?: "batch"
        input_layer: meta.counts_layer ?: "X"
    }

    if (method == 'none') {
        log.info("AMBIENT_RNA_REMOVAL: Not performed since 'none' selected.")
        ch_h5ad = ch_pairing.map { meta, filtered, _unfiltered -> [meta, filtered] }
    }
    else if (method == 'decontx') {
        CELDA_DECONTX(ch_multi.input, ch_multi.batch_col, ch_multi.input_layer)
        ch_h5ad = CELDA_DECONTX.out.h5ad
        ch_versions = ch_versions.mix(CELDA_DECONTX.out.versions)
    }
    else if (method == 'cellbender') {
        CELLBENDER_REMOVEBACKGROUND(ch_pairing.map { meta, _filtered, unfiltered -> [meta, unfiltered] })
        ch_versions = ch_versions.mix(CELLBENDER_REMOVEBACKGROUND.out.versions)

        CELLBENDER_MERGE(
            ch_pairing.map { meta, filtered, raw -> [meta.id, meta, filtered, raw] }.join(CELLBENDER_REMOVEBACKGROUND.out.h5.map { meta, h5 -> [meta.id, h5] }, by: 0, failOnMismatch: true).map { _id, meta, filtered, raw, h5 -> [meta, filtered, raw, h5] }
        )
        ch_h5ad = CELLBENDER_MERGE.out.h5ad
        ch_versions = ch_versions.mix(CELLBENDER_MERGE.out.versions)
    }
    else if (method == 'soupx') {
        SOUPX(ch_multi.input, ch_multi.input_layer)
        ch_h5ad = SOUPX.out.h5ad
        ch_versions = ch_versions.mix(SOUPX.out.versions)
    }
    else if (method == 'scar') {
        SCVITOOLS_SCAR(ch_pairing)
        ch_h5ad = SCVITOOLS_SCAR.out.h5ad
        ch_versions = SCVITOOLS_SCAR.out.versions
    }
    else {
        error("AMBIENT_RNA_REMOVAL: Unexpected method for ambient RNA removal: '${method}'.")
    }

    emit:
    h5ad     = ch_h5ad // channel: [ meta, h5ad ]
    versions = ch_versions // channel: [ versions.yml ]
}
