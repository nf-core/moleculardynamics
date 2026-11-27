#!/usr/bin/env nextflow

include { PDB_CLEAN }        from '../../../modules/local/pdb/clean/main'
include { PDB_CHECKMISSING } from '../../../modules/local/pdb/checkmissing/main'

workflow PRE_PROCESSING {
    take:
    ch_inputs

    main:
    PDB_CLEAN(ch_inputs)
    PDB_CHECKMISSING(PDB_CLEAN.out.cleaned)

    emit:
    cleaned_pdb = PDB_CHECKMISSING.out.checked_pdb
}
