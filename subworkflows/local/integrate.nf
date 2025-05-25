include { SCANPY_HVGS        } from '../../modules/local/scanpy/hvgs'
include { ADATA_TORDS        } from '../../modules/local/adata/tords'
include { SCVITOOLS_SCVI     } from '../../modules/local/scvitools/scvi'
include { SCVITOOLS_SCANVI   } from '../../modules/local/scvitools/scanvi'
include { SCANPY_HARMONY     } from '../../modules/local/scanpy/harmony'
include { INTEGRATION_BBKNN  } from '../../modules/local/integration/bbknn'
include { SCANPY_COMBAT      } from '../../modules/local/scanpy/combat'
include { SEURAT_INTEGRATION } from '../../modules/local/seurat/integration'
include { ADATA_READRDS      } from '../../modules/local/adata/readrds'
include { SCIMILARITY        } from './scimilarity'

workflow INTEGRATE {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()
    ch_obsm = Channel.empty()
    ch_layers = Channel.empty()
    ch_integrations = Channel.empty()

    // If a reference model is provided, only the genes in the reference model are used
    // Otherwise, we would intersect the HVGs, which is not what we want
    if (!params.base_adata && params.integration_hvgs >= 0) {
        SCANPY_HVGS(ch_h5ad, params.integration_hvgs)
        ch_versions = ch_versions.mix(SCANPY_HVGS.out.versions)
        ch_h5ad_hvg = SCANPY_HVGS.out.h5ad
    } else {
        ch_h5ad_hvg = ch_h5ad
    }

    methods = params.integration_methods.split(',').collect { it.trim().toLowerCase() }

    // Special treatment for R-based methods
    if (methods.intersect(['seurat']).size() > 0) {
        ADATA_TORDS(ch_h5ad_hvg)
        ch_versions = ch_versions.mix(ADATA_TORDS.out.versions)
        ch_rds = ADATA_TORDS.out.rds

        ch_rds_integrations = Channel.empty()

        if (methods.contains('seurat')) {
            SEURAT_INTEGRATION(ch_rds.map { _meta, rds -> [[id: 'seurat'], rds] })
            ch_versions = ch_versions.mix(SEURAT_INTEGRATION.out.versions)
            ch_rds_integrations = ch_rds_integrations.mix(SEURAT_INTEGRATION.out.rds)
        }

        ADATA_READRDS(ch_rds_integrations)
        ch_versions = ch_versions.mix(ADATA_READRDS.out.versions)

        ch_integrations = ch_integrations.mix(ADATA_READRDS.out.h5ad)
        ch_obsm = ch_obsm.mix(ADATA_READRDS.out.obsm)
    }

    if (methods.contains('scvi')) {
        SCVITOOLS_SCVI(
            (params.scvi_model ? ch_h5ad : ch_h5ad_hvg).map { _meta, h5ad -> [[id: 'scvi'], h5ad] },
            params.scvi_model
                ? Channel.value([[id: 'scvi_model'], params.scvi_model])
                : [[], []],
            params.scvi_categorical_covariates,
            params.scvi_continuous_covariates,
        )
        ch_versions = ch_versions.mix(SCVITOOLS_SCVI.out.versions)
        ch_integrations = ch_integrations.mix(SCVITOOLS_SCVI.out.h5ad)
        ch_obsm = ch_obsm.mix(SCVITOOLS_SCVI.out.obsm)
    }

    if (methods.contains('scanvi')) {
        SCVITOOLS_SCANVI(
            (params.scvi_model ? ch_h5ad : ch_h5ad_hvg).map { _meta, h5ad -> [[id: 'scanvi'], h5ad] },
            params.scanvi_model
                ? Channel.value([[id: 'scanvi_model'], params.scanvi_model])
                : methods.contains('scvi')
                    ? SCVITOOLS_SCVI.out.model
                    : [[], []],
            "label",
            params.scvi_categorical_covariates,
            params.scvi_continuous_covariates,
        )
        ch_versions = ch_versions.mix(SCVITOOLS_SCANVI.out.versions)
        ch_integrations = ch_integrations.mix(SCVITOOLS_SCANVI.out.h5ad)
        ch_obs = ch_obs.mix(SCVITOOLS_SCANVI.out.obs)
        ch_obsm = ch_obsm.mix(SCVITOOLS_SCANVI.out.obsm)
    }

    if (methods.contains('harmony')) {
        SCANPY_HARMONY(ch_h5ad_hvg.map { _meta, h5ad -> [[id: 'harmony'], h5ad] })
        ch_versions = ch_versions.mix(SCANPY_HARMONY.out.versions)
        ch_integrations = ch_integrations.mix(SCANPY_HARMONY.out.h5ad)
        ch_obsm = ch_obsm.mix(SCANPY_HARMONY.out.obsm)
    }

    if (methods.contains('bbknn')) {
        INTEGRATION_BBKNN(ch_h5ad_hvg.map { _meta, h5ad -> [[id: 'bbknn'], h5ad] })
        ch_versions = ch_versions.mix(INTEGRATION_BBKNN.out.versions)
        ch_integrations = ch_integrations.mix(INTEGRATION_BBKNN.out.h5ad)
    }

    if (methods.contains('combat')) {
        SCANPY_COMBAT(ch_h5ad_hvg.map { _meta, h5ad -> [[id: 'combat'], h5ad] })
        ch_versions = ch_versions.mix(SCANPY_COMBAT.out.versions)
        ch_integrations = ch_integrations.mix(SCANPY_COMBAT.out.h5ad)
        ch_obsm = ch_obsm.mix(SCANPY_COMBAT.out.obsm)
    }

    if (methods.contains('scimilarity')) {
        SCIMILARITY(
            ch_h5ad.map { _meta, h5ad -> [[id: 'scimilarity'], h5ad] },
            params.scimilarity_model,
        )
        ch_versions = ch_versions.mix(SCIMILARITY.out.versions)
        ch_integrations = ch_integrations.mix(SCIMILARITY.out.integrations)
        ch_obs = ch_obs.mix(SCIMILARITY.out.obs)
        ch_obsm = ch_obsm.mix(SCIMILARITY.out.obsm)
    }

    emit:
    integrations = ch_integrations
    obs          = ch_obs
    obsm         = ch_obsm
    layers       = ch_layers
    versions     = ch_versions
}
