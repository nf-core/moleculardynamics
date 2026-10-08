#!/usr/bin/env nextflow


include { RUN_TOPOLOGY } from '../../../modules/local/run_topology.nf'
include { RUN_SOLVATION } from '../../../modules/local/run_solvation.nf'
include { RUN_ENERGY_MINIMISATION } from '../../../modules/local/run_energy_min.nf'
include { RUN_NVT_EQUILIBRATION } from '../../../modules/local/run_nvt_equilibration.nf'
include { RUN_NPT_EQUILIBRATION } from '../../../modules/local/run_npt_equilibration.nf'
include { RUN_PRODUCTION } from '../../../modules/local/run_production.nf'

workflow RUN_MD_SIMULATION {

    take:
    ch_preprocessing

    main:
    // STEP 1. Generate topology
    RUN_TOPOLOGY(ch_preprocessing)

    // STEP 2. Solvating the system + adding ions
    RUN_SOLVATION(RUN_TOPOLOGY.out.topology_out)

    // STEP 3. Energy minimization
    RUN_ENERGY_MINIMISATION(RUN_SOLVATION.out.solvation_out)

    // STEP 4. NVT equilibration
    RUN_NVT_EQUILIBRATION(RUN_ENERGY_MINIMISATION.out.energy_min_out)

    // STEP 5. NPT equilibration
    RUN_NPT_EQUILIBRATION(RUN_NVT_EQUILIBRATION.out.nvt_equilibration_out)

    // STEP 6. Production run
    RUN_PRODUCTION(RUN_NPT_EQUILIBRATION.out.npt_equilibration_out)

    emit:
    // production_out is tuple(sample, tpr, gro, xtc)
    md_tpr    = RUN_PRODUCTION.out.production_out.map { tuple(it[0], it[1]) }
    md_gro    = RUN_PRODUCTION.out.production_out.map { tuple(it[0], it[2]) }
    md_xtc    = RUN_PRODUCTION.out.production_out.map { tuple(it[0], it[3]) }
    md_report = RUN_PRODUCTION.out.md_report
}
