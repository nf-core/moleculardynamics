include { PDB_CLEAN        } from '../../../modules/local/pdb/clean/main'
include { PDB_CHECKMISSING } from '../../../modules/local/pdb/checkmissing/main'

workflow PRE_PROCESSING {
    take:
    ch_pdb // channel: [ val(meta), path(pdb) ]

    main:
    PDB_CLEAN(ch_pdb)
    PDB_CHECKMISSING(PDB_CLEAN.out.pdb)

    emit:
    pdb = PDB_CHECKMISSING.out.pdb // channel: [ val(meta), path(pdb) ]
}
