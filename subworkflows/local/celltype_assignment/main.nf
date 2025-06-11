include { CELLTYPES_CELLTYPIST } from '../../../modules/local/celltypes/celltypist'
include { CELLTYPES_SINGLER } from '../../../modules/local/celltypes/singler'
workflow CELLTYPE_ASSIGNMENT {
    take:
    ch_h5ad // channel: [ meta, h5ad ]
    celldex_ref_dirs
    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()

    // Process celldex references if specified
    if (params.celldex_reference ) { //a celldex reference was specified so we need to process it and possibly download it
        if (workflow.profile.contains('conda') || workflow.profile.contains('mamba')) {
            // Log warning and skip if conda/mamba is used
            log.warn "Skipping singleR module in conda/mamba profile."
            return
        }
        CELLTYPES_SINGLER(ch_h5ad, celldex_ref_dirs, params.celldex_reference_label)
        ch_obs = ch_obs.mix(CELLTYPES_SINGLER.out.obs)
        //ch_h5ad = CELLTYPES_SINGLER.out.h5ad
        ch_versions = ch_versions.mix(CELLTYPES_SINGLER.out.versions)
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
