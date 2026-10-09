#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    PRODUCTION RUN Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - This is a placeholder for the production run process.
//     - It also generates a report of the simulation, including the settings used to run it.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RUN_PRODUCTION {
    label 'process_high'
    label 'process_long'

    publishDir "${params.outdir}/${sample}/production", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(npt_gro), path(topol), path(itps), path(md_mdp)


    output:
    tuple val(sample),
        path("${md_mdp.simpleName}.tpr"),
        path("${md_mdp.simpleName}.gro"),
        path("${md_mdp.simpleName}.xtc"),
        emit: production_out
    path "${md_mdp.simpleName}.edr"
    path "${md_mdp.simpleName}.log"
    path "MD_REPORT.out", emit: md_report
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions


    script:
    """
    echo "Running the molecular dynamics simulation"
    ${params.gmx_cmd} grompp -f ${md_mdp} -c ${npt_gro} -p topol.top -o ${md_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${md_mdp.simpleName}
    ${params.gmx_cmd} report-methods -s ${md_mdp.simpleName}.tpr -o MD_REPORT.out

    echo "Simulation completed!"
    """
}
