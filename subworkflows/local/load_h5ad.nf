include { SCANPY_READH5 } from '../../modules/local/scanpy/readh5'
include { ADATA_READRDS } from '../../modules/local/adata/readrds'
include { ADATA_READCSV } from '../../modules/local/adata/readcsv'

workflow LOAD_H5AD {
    take:
    ch_samples

    main:
    ch_versions = Channel.empty()
    ch_files = Channel.empty()
    ch_h5ad = Channel.empty()

    ch_files = ch_files.mix(ch_samples
        .map { meta, filtered, _unfiltered -> [meta + [type: 'filtered'], filtered] }
        .filter { _meta, filtered -> filtered }
    )
    ch_files = ch_files.mix(ch_samples
        .map { meta, _filtered, unfiltered -> [meta + [type: 'unfiltered'], unfiltered] }
        .filter { _meta, unfiltered -> unfiltered }
    )

    ch_files = ch_files.map { meta, file -> [meta, file, file.extension.toLowerCase()] }
        .branch { meta, file, ext ->
            unified: ext == "h5ad" && meta.unified == true
                return [meta, file]
            h5ad: ext == "h5ad"
                return [meta, file]
            h5: ext == "h5"
                return [meta, file]
            rds: ext == "rds"
                return [meta, file]
            csv: ext == "csv"
                return [meta, file]
        }

    ch_h5ad = ch_h5ad.mix(ch_files.h5ad)

    SCANPY_READH5(ch_files.h5)
    ch_h5ad = ch_h5ad.mix(SCANPY_READH5.out.h5ad)
    ch_versions = ch_versions.mix(SCANPY_READH5.out.versions)

    ADATA_READRDS(ch_files.rds)
    ch_h5ad = ch_h5ad.mix(ADATA_READRDS.out.h5ad)
    ch_versions = ch_versions.mix(ADATA_READRDS.out.versions)

    ADATA_READCSV(ch_files.csv)
    ch_h5ad = ch_h5ad.mix(ADATA_READCSV.out.h5ad)
    ch_versions = ch_versions.mix(ADATA_READCSV.out.versions)

    emit:
    h5ad = ch_h5ad
    unified = ch_files.unified
    versions = ch_versions
}
