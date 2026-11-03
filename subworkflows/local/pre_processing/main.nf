#!/usr/bin/env nextflow

include { PRE_POS_CLEAN_PDB }         from '../../../modules/local/pre_pos_clean_pdb.nf'
include { PRE_POS_CHECK_MISSING_ATOMS } from '../../../modules/local/pre_pos_check_missing_atoms.nf'

workflow PRE_PROCESSING {
    take:
    ch_inputs

    main:
    PRE_POS_CLEAN_PDB(ch_inputs)
    PRE_POS_CHECK_MISSING_ATOMS(PRE_POS_CLEAN_PDB.out.cleaned)

    emit:
    cleaned_pdb = PRE_POS_CHECK_MISSING_ATOMS.out.checked_pdb
}
