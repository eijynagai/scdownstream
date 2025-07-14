include { samplesheetToList    } from 'plugin/nf-schema'
include { SINGLER              } from '../singler'
include { CELLTYPES_CELLTYPIST } from '../../../modules/local/celltypes/celltypist'

workflow CELLTYPE_ASSIGNMENT {
    take:
    ch_h5ad // channel: [ meta, h5ad ]

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()

    if (params.celldex_reference ) {
        SINGLER(
            ch_h5ad,
            Channel.fromList(samplesheetToList(params.celldex_reference, "${projectDir}/assets/schema_singler.json"))
        )
        ch_obs = ch_obs.mix(SINGLER.out.obs)
        ch_versions = ch_versions.mix(SINGLER.out.versions)
    }

    if (params.celltypist_model) {
        celltypist_models = Channel.value(params.celltypist_model.split(',').collect{ it -> it.trim() })

        CELLTYPES_CELLTYPIST(ch_h5ad, celltypist_models)
        ch_obs = ch_obs.mix(CELLTYPES_CELLTYPIST.out.obs)
        ch_h5ad = CELLTYPES_CELLTYPIST.out.h5ad
        ch_versions = ch_versions.mix(CELLTYPES_CELLTYPIST.out.versions)
    }

    emit:
    obs      = ch_obs      // channel: [ meta, pkl ]
    h5ad     = ch_h5ad     // channel: [ meta, h5ad ]
    versions = ch_versions // channel: [ versions.yml ]
}
