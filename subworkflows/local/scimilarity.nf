include { UNTAR                } from '../../modules/nf-core/untar'
include { SCIMILARITY_EMBED    } from '../../modules/local/scimilarity/embed'
include { SCIMILARITY_ANNOTATE } from '../../modules/local/scimilarity/annotate'

workflow SCIMILARITY {
    take:
    ch_h5ad
    scimilarity_model

    main:
    ch_versions = Channel.empty()
    ch_integrations = Channel.empty()
    ch_obsm = Channel.empty()
    ch_obs = Channel.empty()

    ch_scimilarity_model = Channel.value(
        [
            [id: 'scimilarity_model'],
            file(scimilarity_model, checkIfExists: true),
        ]
    )

    if (!scimilarity_model) {
        error("scimilarity_model is required for scimilarity integration")
    }

    if (scimilarity_model.endsWith('.tar.gz')) {
        UNTAR(ch_scimilarity_model)
        ch_versions = ch_versions.mix(UNTAR.out.versions)
        ch_scimilarity_model = UNTAR.out.untar
    }

    SCIMILARITY_EMBED(
        ch_h5ad,
        ch_scimilarity_model,
    )
    ch_versions = ch_versions.mix(SCIMILARITY_EMBED.out.versions)
    ch_integrations = ch_integrations.mix(SCIMILARITY_EMBED.out.h5ad)
    ch_obsm = ch_obsm.mix(SCIMILARITY_EMBED.out.obsm)

    SCIMILARITY_ANNOTATE(
        SCIMILARITY_EMBED.out.h5ad,
        ch_scimilarity_model,
    )
    ch_versions = ch_versions.mix(SCIMILARITY_ANNOTATE.out.versions)
    ch_obs = ch_obs.mix(SCIMILARITY_ANNOTATE.out.obs)

    emit:
    integrations = ch_integrations
    obs          = ch_obs
    obsm         = ch_obsm
    versions     = ch_versions
}
