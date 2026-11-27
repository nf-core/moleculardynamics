//
// Standard MD protocol: topology, solvation, energy minimisation, NVT, NPT and production
//
include { GROMACS_PDB2GMX                                 } from '../../../modules/local/gromacs/pdb2gmx/main'
include { GROMACS_REPORTMETHODS                           } from '../../../modules/local/gromacs/reportmethods/main'
include { GROMACS_SOLVATION                               } from '../gromacs_solvation/main'
include { GROMACS_GROMPP_MDRUN as GROMPP_MDRUN_EM         } from '../gromacs_grompp_mdrun/main'
include { GROMACS_GROMPP_MDRUN as GROMPP_MDRUN_NVT        } from '../gromacs_grompp_mdrun/main'
include { GROMACS_GROMPP_MDRUN as GROMPP_MDRUN_NPT        } from '../gromacs_grompp_mdrun/main'
include { GROMACS_GROMPP_MDRUN as GROMPP_MDRUN_PRODUCTION } from '../gromacs_grompp_mdrun/main'

workflow RUN_MD_SIMULATION {
    take:
    ch_pdb            // channel: [ val(meta), path(pdb) ]
    ch_force_field    // channel: [ val(meta), val(force_field) ]
    ch_ions_mdp       // channel: [ val(meta), path(mdp) ]
    ch_em_mdp         // channel: [ val(meta), path(mdp) ]
    ch_nvt_mdp        // channel: [ val(meta), path(mdp) ]
    ch_npt_mdp        // channel: [ val(meta), path(mdp) ]
    ch_md_mdp         // channel: [ val(meta), path(mdp) ]
    val_water_model   // string:  water model used to build the topology
    val_solvent_group // string:  group whose molecules are replaced by ions

    main:
    // STEP 1. Generate topology
    GROMACS_PDB2GMX(
        ch_pdb.join(ch_force_field, failOnMismatch: true, failOnDuplicate: true),
        val_water_model,
    )

    // STEP 2. Solvate the system and add ions
    GROMACS_SOLVATION(
        GROMACS_PDB2GMX.out.gro,
        GROMACS_PDB2GMX.out.top,
        GROMACS_PDB2GMX.out.itp,
        ch_ions_mdp,
        val_solvent_group,
    )

    // STEP 3. Energy minimisation
    GROMPP_MDRUN_EM(ch_em_mdp, GROMACS_SOLVATION.out.gro, GROMACS_SOLVATION.out.top, GROMACS_PDB2GMX.out.itp, false)

    // STEP 4. NVT equilibration
    GROMPP_MDRUN_NVT(ch_nvt_mdp, GROMPP_MDRUN_EM.out.gro, GROMACS_SOLVATION.out.top, GROMACS_PDB2GMX.out.itp, true)

    // STEP 5. NPT equilibration
    GROMPP_MDRUN_NPT(ch_npt_mdp, GROMPP_MDRUN_NVT.out.gro, GROMACS_SOLVATION.out.top, GROMACS_PDB2GMX.out.itp, true)

    // STEP 6. Production run
    GROMPP_MDRUN_PRODUCTION(ch_md_mdp, GROMPP_MDRUN_NPT.out.gro, GROMACS_SOLVATION.out.top, GROMACS_PDB2GMX.out.itp, false)
    GROMACS_REPORTMETHODS(GROMPP_MDRUN_PRODUCTION.out.tpr)

    emit:
    tpr    = GROMPP_MDRUN_PRODUCTION.out.tpr // channel: [ val(meta), path(tpr) ]
    gro    = GROMPP_MDRUN_PRODUCTION.out.gro // channel: [ val(meta), path(gro) ]
    xtc    = GROMPP_MDRUN_PRODUCTION.out.xtc // channel: [ val(meta), path(xtc) ]
    report = GROMACS_REPORTMETHODS.out.out   // channel: [ val(meta), path(out) ]
}
