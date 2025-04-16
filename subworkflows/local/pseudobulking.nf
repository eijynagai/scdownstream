include { SCIMILARITY_PSEUDOBULK } from '../../modules/local/scimilarity/pseudobulk'

workflow PSEUDOBULKING {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()

    SCIMILARITY_PSEUDOBULK(ch_h5ad)
    ch_versions = ch_versions.mix(SCIMILARITY_PSEUDOBULK.out.versions)

    ch_h5ad_pseudobulk = SCIMILARITY_PSEUDOBULK.out.h5ad

    emit:
    h5ad_pseudobulk = ch_h5ad_pseudobulk
    versions        = ch_versions
}
