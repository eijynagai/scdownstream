include { ADATA_SPLITCOL as SPLITCOL    } from '../../modules/local/adata/splitcol'
include { SCANPY_NEIGHBORS as NEIGHBORS } from '../../modules/local/scanpy/neighbors'
include { SCANPY_LEIDEN as LEIDEN       } from '../../modules/local/scanpy/leiden'
include { SCANPY_UMAP as UMAP           } from '../../modules/local/scanpy/umap'
include { ADATA_ENTROPY as ENTROPY      } from '../../modules/local/adata/entropy'
workflow CLUSTER {
    take:
    ch_input

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()
    ch_obsm = Channel.empty()
    ch_obsp = Channel.empty()
    ch_uns = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_h5ad = Channel.empty()

    if (params.cluster_global) {
        ch_h5ad = ch_h5ad.mix(ch_input.map { meta, h5ad -> [meta + [subset: "global"], h5ad] })
    }

    if (params.cluster_per_label) {
        SPLITCOL(ch_input, params.input ? "label" : params.base_label_col)
        ch_versions = ch_versions.mix(SPLITCOL.out.versions)

        ch_h5ad = ch_h5ad.mix(
            SPLITCOL.out.h5ad.transpose().map { meta, h5ad -> [meta + [subset: h5ad.simpleName], h5ad] }
        )
    }

    ch_h5ad = ch_h5ad.map { meta, h5ad -> [meta + [id: meta.integration + "-" + meta.subset], h5ad] }

    ch_h5ad
        .branch { meta, _h5ad ->
            has_neighbors: meta.integration == "bbknn"
            needs_neighbors: true
        }
        .set { ch_h5ad }

    NEIGHBORS(ch_h5ad.needs_neighbors)
    ch_versions = ch_versions.mix(NEIGHBORS.out.versions)
    ch_h5ad = NEIGHBORS.out.h5ad.mix(ch_h5ad.has_neighbors)

    UMAP(ch_h5ad)
    ch_versions = ch_versions.mix(UMAP.out.versions)
    ch_obsm = ch_obsm.mix(UMAP.out.obsm)
    ch_multiqc_files = ch_multiqc_files.mix(UMAP.out.multiqc_files)

    ch_resolutions = Channel.from(params.clustering_resolutions.split(","))

    ch_h5ad = UMAP.out.h5ad
        .combine(ch_resolutions)
        .map { meta, h5ad, resolution ->
            [
                meta + [
                    resolution: resolution,
                    id: meta.integration + "-" + meta.subset + "-" + resolution,
                ],
                h5ad,
            ]
        }

    LEIDEN(ch_h5ad)
    ch_versions = ch_versions.mix(LEIDEN.out.versions)
    ch_obs = ch_obs.mix(LEIDEN.out.obs)
    ch_multiqc_files = ch_multiqc_files.mix(LEIDEN.out.multiqc_files)

    ENTROPY(LEIDEN.out.h5ad)
    ch_obs = ch_obs.mix(ENTROPY.out.obs)
    ch_versions = ch_versions.mix(ENTROPY.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(ENTROPY.out.multiqc_files)

    emit:
    obs             = ch_obs
    obsm            = ch_obsm
    obsp            = ch_obsp
    uns             = ch_uns
    h5ad_clustering = LEIDEN.out.h5ad
    h5ad_neighbors  = NEIGHBORS.out.h5ad
    multiqc_files   = ch_multiqc_files
    versions        = ch_versions
}
