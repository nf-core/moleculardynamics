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
    label 'process_medium'

    publishDir "${params.outdir}/${sample}/energy_minimization", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(gro_box_solvated_ions), path(topol), path(itps), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(sample),
        path("${em_mdp.simpleName}.gro"),
        path("topol.top"),
        path(itps),
        path(nvt_mdp), path(npt_mdp), path(md_mdp),
        emit: energy_min_out
    path "${em_mdp.simpleName}.tpr"
    path "${em_mdp.simpleName}.edr"
    path "${em_mdp.simpleName}.log"
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions


    script:
    """
    echo "Performing energy minimization"
    ${params.gmx_cmd} grompp -f ${em_mdp} -c ${gro_box_solvated_ions} -p topol.top -o ${em_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${em_mdp.simpleName}
    echo "Energy minimization completed"

    """
}
