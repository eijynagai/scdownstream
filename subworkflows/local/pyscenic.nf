include { PYSCENIC_GRN } from '../../modules/local/pyscenic/build_grn'
include { PYSCENIC_REG_PRED } from '../../modules/local/pyscenic/regulon_pred'
include { PYSCENIC_REG_ACT } from '../../modules/local/pyscenic/regulon_act'


workflow PYSCENIC {
    take:
        ch_h5ad
        refgenome
        motifsource

    main:
        //Step1: build GRN using GRNBoost2
        ch_tfs = Channel.value(file(
                "${workflow.projectDir}/assets/scenic_tfs.csv",
                checkIfExists: true))
            .splitCsv()
            .filter{ it[0] == refgenome }
            .map{ file(it[1], checkIfExists: true) }
        
        PYSCENIC_GRN(ch_h5ad, ch_tfs.collect())

        //Step2: Regulon prediction and motif enrichment
        ch_rfr_db = Channel.value(file(
                "${workflow.projectDir}/assets/scenic_rfr_db.csv",
                checkIfExists: true))
            .splitCsv()
            .filter{ it[0] == refgenome}
            .map{ file(it[5], checkIfExists: true) }
        
        ch_motif_annot = Channel.value(file(
                "${workflow.projectDir}/assets/scenic_motif_tf.csv",
                checkIfExists: true))
            .splitCsv()
            .filter{ it[1] == refgenome && it[3] == motifsource}
            .map{ file(it[4], checkIfExists: true) }

        PYSCENIC_REG_PRED(PYSCENIC_GRN.out.modules, ch_rfr_db.collect(), ch_motif_annot.collect())

        //Step3: Regulon activity scoring (AUCell)
        PYSCENIC_REG_ACT(ch_h5ad, PYSCENIC_REG_PRED.out.regulons)
}
