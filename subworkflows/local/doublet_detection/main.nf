include { SCVITOOLS_SOLO   } from '../../../modules/nf-core/scvitools/solo'
include { SCANPY_SCRUBLET  } from '../../../modules/local/scanpy/scrublet'
include { DOUBLETDETECTION } from '../../../modules/nf-core/doubletdetection'
include { SCDS             } from '../../../modules/local/doublet_detection/scds'
include { DOUBLET_REMOVAL  } from '../../../modules/local/doublet_detection/doublet_removal'

workflow DOUBLET_DETECTION {
    take:
    ch_h5ad // channel: [ meta, h5ad ]
    methods // value: list of strings
    threshold // value: integer

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_predictions = Channel.empty()

    if (methods.size() == 0) {
        log.info("DOUBLET_DETECTION: Not performed since no methods selected.")
    } else {
        if (methods.contains('scds')) {
            SCDS(ch_h5ad)
            ch_predictions = ch_predictions.mix(SCDS.out.predictions)
            ch_versions = SCDS.out.versions
        }

        if (methods.contains('solo')) {
            SCVITOOLS_SOLO(ch_h5ad)
            ch_predictions = ch_predictions.mix(SCVITOOLS_SOLO.out.predictions)
            ch_versions = SCVITOOLS_SOLO.out.versions
        }

        if (methods.contains('scrublet')) {
            ch_scrublet = ch_h5ad.multiMap { meta, h5ad ->
                input: [meta, h5ad]
                batch_col: meta.batch_col
            }
            SCANPY_SCRUBLET(ch_scrublet.input, ch_scrublet.batch_col)
            ch_predictions = ch_predictions.mix(SCANPY_SCRUBLET.out.predictions)
            ch_versions = SCANPY_SCRUBLET.out.versions
        }

        if (methods.contains('doubletdetection')) {
            DOUBLETDETECTION(ch_h5ad)
            ch_predictions = ch_predictions.mix(DOUBLETDETECTION.out.predictions)
            ch_versions = DOUBLETDETECTION.out.versions
        }

        DOUBLET_REMOVAL(
            ch_h5ad.join(ch_predictions.groupTuple()),
            threshold,
        )

        ch_h5ad = DOUBLET_REMOVAL.out.h5ad
        ch_multiqc_files = ch_multiqc_files.mix(DOUBLET_REMOVAL.out.multiqc_files)
        ch_versions = ch_versions.mix(DOUBLET_REMOVAL.out.versions)
    }

    emit:
    h5ad          = ch_h5ad // channel: [ meta, h5ad ]
    multiqc_files = ch_multiqc_files // channel: [ json ]
    versions      = ch_versions // channel: [ versions.yml ]
}
