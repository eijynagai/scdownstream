include { CELLTYPES_CELLTYPIST } from '../../modules/local/celltypes/celltypist'
include { CELLTYPES_SINGLER } from '../../modules/local/celltypes/singler'
include { CELLTYPES_CELLDEXDOWNLOAD } from '../../modules/local/celltypes/celldexdownload'

workflow CELLDEX_REFERENCE_PROCESSING {
    take:
    reference_string

    main:
    def refdirs = Channel.empty()
    def ref_list = reference_string.split(',').collect{it.trim()}
    log.info(" ${ref_list}")
    for (r in ref_list) {
        log.info("${r}")
        referencedir = r ==~ /celldex_.*_h5_se/ ? 
            file(r) : 
            file("celldex_${r}_h5_se")

        if(!referencedir.exists()){
            log.info("Downloading Celldex reference ${r} into folder ${referencedir}")
            CELLTYPES_CELLDEXDOWNLOAD(r)
            refdirs = refdirs.mix(CELLTYPES_CELLDEXDOWNLOAD.out.refdir)
        }else{
            if( referencedir.exists() && referencedir.isDirectory() ){
                log.info(file("${r}/assays.h5").view())
                assaysFile = file("${r}/assays.h5")
                seFile     = file("${r}/se.rds")
                if(seFile.exists() && assaysFile.exists()){
                    log.info("SummarizedExperiment serialized to HSDF5 was found at ${referencedir}")
                    refdirs = refdirs.mix(Channel.fromPath(referencedir))
                }else{
                    error "Directory ${referencedir} exists but doesn't contain the expected 'assays.h5' and 'se.rds' files"
                }
            }
        }   
    }
    emit: referenceDirs = refdirs.collect() 
}

workflow CELLTYPE_ASSIGNMENT {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()

    if (params.celldex_reference) { //a celldex reference was specified so we need to process it and possibly download it
        CELLDEX_REFERENCE_PROCESSING(params.celldex_reference)
        CELLTYPES_SINGLER(ch_h5ad, CELLDEX_REFERENCE_PROCESSING.out.referenceDirs)
        ch_obs = ch_obs.mix(CELLTYPES_SINGLER.out.obs)
        //ch_h5ad = CELLTYPES_SINGLER.out.h5ad
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
