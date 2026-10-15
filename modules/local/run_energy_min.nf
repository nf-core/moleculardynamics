#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    ENERGY MINIMISATION Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Perform energy minimization of the system.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RUN_ENERGY_MINIMISATION {

    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(sample), path(gro_box_solvated_ions), path(topol), path(itps), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp), val(outdir)

    output:
    tuple val(sample),
        path("${em_mdp.simpleName}.tpr"),
        path("${em_mdp.simpleName}.edr"),
        path("${em_mdp.simpleName}.log"),
        path("${em_mdp.simpleName}.gro"),
        path("topol.top"),
        path(itps),
        path(nvt_mdp), path(npt_mdp), path(md_mdp)
        emit:  energy_min_out


    script:
    """
    echo "Performing energy minimization"
    ${params.gmx_cmd} grompp -f ${em_mdp} -c ${gro_box_solvated_ions} -p topol.top -o ${em_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${em_mdp.simpleName}
    echo "Energy minimization completed"
    """
}
