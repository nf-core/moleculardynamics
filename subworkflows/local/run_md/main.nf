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
    outdir

    main:
    // STEP 1. Generate topology
    topology_out        = RUN_TOPOLOGY(ch_preprocessing, force_field, outdir)

    // STEP 2. Solvating the system + adding ions
    solvation_out          = RUN_SOLVATION(topology_out, outdir)

    // STEP 3. Energy minimization
    // ch_em_mdp           = Channel.fromPath("${inputdir}/input/em*.mdp")
    energy_min_out      = RUN_ENERGY_MINIMISATION(solvation_out, outdir)

    // STEP 4. NVT equilibration
    nvt_equilibration_out  = RUN_NVT_EQUILIBRATION(energy_min_out, outdir)

    // STEP 5. NPT equilibration
    npt_equilibration_out = RUN_NPT_EQUILIBRATION(nvt_equilibration_out, outdir)

    // STEP 6. Production run
    production_run_out  = RUN_PRODUCTION(npt_equilibration_out, outdir)

    emit:
    md_result = production_run_out
}
