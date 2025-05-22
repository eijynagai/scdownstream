include { CELLTYPES_CELLTYPIST } from '../../modules/local/celltypes/celltypist'
include { CELLTYPES_SINGLER } from '../../modules/local/celltypes/singler'
include { CELLTYPES_CELLDEXDOWNLOAD } from '../../modules/local/celltypes/celldexdownload'

workflow CELLDEX_REFERENCE_PROCESSING {
    take:
    reference_string

    main:
    refdir = Channel.empty()
    referencedir = reference_string ==~ /celldex_.*_h5_se/ ? file(reference_string) : file("celldex_${reference_string}_h5_se")

    if(!referencedir.exists()){
        log.info("Downloading Celldex reference ${reference_string} into folder ${referencedir}")
        CELLTYPES_CELLDEXDOWNLOAD(reference_string)
        refdir = CELLTYPES_CELLDEXDOWNLOAD.out.refdir
    }else{
        if( referencedir.exists() && referencedir.isDirectory() ){
            def assaysFile = file(reference_string + "/assays.h5")
            def seFile     = file(reference_string + "/se.rds")
            if(seFile.exists() && assaysFile.exists()){
                log.info("SummarizedExperiment serialized to HSDF5 was found at ${referencedir}")
                refdir = Channel.fromPath(referencedir)
            }else{
                error "Directory ${referencedir} exists but doesn't contain the expected 'assays.h5' and 'se.rds' files"
            }
        }
    }
    emit:
    refdir
}

workflow CELLTYPE_ASSIGNMENT {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()

    if (params.celldex_reference) { //a celldex reference was specified so we need to process it and possibly download it
        CELLDEX_REFERENCE_PROCESSING(params.celldex_reference)
        CELLTYPES_SINGLER(ch_h5ad, CELLDEX_REFERENCE_PROCESSING.out.refdir)
        ch_obs = ch_obs.mix(CELLTYPES_SINGLER.out.obs)
        ch_h5ad = CELLTYPES_SINGLER.out.h5ad
        ch_versions = ch_versions.mix(CELLTYPES_SINGLER.out.versions)
    }

    if (params.celltypist_model) {
        celltypist_models = Channel.value(params.celltypist_model.split(',').collect{it.trim()})

        CELLTYPES_CELLTYPIST(ch_h5ad, celltypist_models)
        ch_obs = ch_obs.mix(CELLTYPES_CELLTYPIST.out.obs)
        ch_h5ad = CELLTYPES_CELLTYPIST.out.h5ad
        ch_versions = ch_versions.mix(CELLTYPES_CELLTYPIST.out.versions)
    }

    emit:
    obs = ch_obs
    h5ad = ch_h5ad

    versions = ch_versions
}
