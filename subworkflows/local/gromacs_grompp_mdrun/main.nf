//
// Build a run input file and run it: used for energy minimisation, NVT, NPT and production
//
include { GROMACS_GROMPP } from '../../../modules/local/gromacs/grompp/main'
include { GROMACS_MDRUN  } from '../../../modules/local/gromacs/mdrun/main'

workflow GROMACS_GROMPP_MDRUN {
    take:
    ch_mdp         // channel: [ val(meta), path(mdp) ]
    ch_gro         // channel: [ val(meta), path(gro) ]
    ch_top         // channel: [ val(meta), path(top) ]
    ch_itp         // channel: [ val(meta), path(itp) ]
    val_restraints // boolean: use the input structure as reference for position restraints

    main:
    ch_grompp = ch_mdp
        .join(ch_gro, failOnMismatch: true, failOnDuplicate: true)
        .join(ch_top, failOnMismatch: true, failOnDuplicate: true)
        .join(ch_itp, failOnMismatch: true, failOnDuplicate: true)
        .map { meta, mdp, gro, top, itp -> [meta, mdp, gro, top, itp, val_restraints ? gro : []] }
    GROMACS_GROMPP(ch_grompp)

    GROMACS_MDRUN(GROMACS_GROMPP.out.tpr)

    emit:
    tpr     = GROMACS_GROMPP.out.tpr // channel: [ val(meta), path(tpr) ]
    gro     = GROMACS_MDRUN.out.gro  // channel: [ val(meta), path(gro) ]
    edr     = GROMACS_MDRUN.out.edr  // channel: [ val(meta), path(edr) ]
    run_log = GROMACS_MDRUN.out.log // channel: [ val(meta), path(log) ]
    xtc     = GROMACS_MDRUN.out.xtc  // channel: [ val(meta), path(xtc) ], optional
}
