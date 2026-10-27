#!/usr/bin/env nextflow

include { PRE_POS_CLEAN_PDB }         from '../../../modules/local/pre_pos_clean_pdb.nf'
include { PRE_POS_CHECK_MISSING_ATOMS } from '../../../modules/local/pre_pos_check_missing_atoms.nf'

workflow PRE_PROCESSING {
    take:
    ch_inputs
    outdir

    main:
    ch_clean = PRE_POS_CLEAN_PDB(ch_inputs, outdir)
    ch_check = PRE_POS_CHECK_MISSING_ATOMS(ch_clean.cleaned)

    emit:
    cleaned_pdb = ch_check.checked_pdb
}
