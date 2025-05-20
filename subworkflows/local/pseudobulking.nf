include { SCIMILARITY_PSEUDOBULK as PSEUDOBULK } from '../../modules/local/scimilarity/pseudobulk'

workflow PSEUDOBULKING {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()

    PSEUDOBULK(ch_h5ad)
    ch_versions = ch_versions.mix(PSEUDOBULK.out.versions)

    ch_h5ad_pseudobulk = PSEUDOBULK.out.h5ad

    emit:
    h5ad_pseudobulk = ch_h5ad_pseudobulk
    versions        = ch_versions
}
