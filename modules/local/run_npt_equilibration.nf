#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    NPT EQUILIBRATION Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Perform NPT equilibration.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RUN_NPT_EQUILIBRATION {
    label 'process_medium'

    publishDir "${params.outdir}/${sample}/npt_equilibration", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(nvt_gro), path(topol), path(itps), path(npt_mdp), path(md_mdp)


    output:
    tuple val(sample),
        path("${npt_mdp.simpleName}.gro"),
        path("topol.top"),
        path(itps),
        path(md_mdp),
        emit: npt_equilibration_out
    path "${npt_mdp.simpleName}.tpr"
    path "${npt_mdp.simpleName}.edr"
    path "${npt_mdp.simpleName}.log"
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    echo "Performing NPT equilibration"
    ${params.gmx_cmd} grompp -f ${npt_mdp} -c ${nvt_gro} -r ${nvt_gro} -p topol.top -o ${npt_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${npt_mdp.simpleName}
    echo "NPT equilibration completed"

    """
}
