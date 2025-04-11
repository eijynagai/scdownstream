include { HUGOUNIFIER_GET } from '../../modules/local/hugounifier/get'


workflow UNIFY_GENES {
    take:
    ch_h5ad

    main:

    HUGOUNIFIER_GET(
        ch_h5ad
            .map { _meta, h5ad -> [[id: 'hugo-unifier'], h5ad] }
            .groupTuple())

}
