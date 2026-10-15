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

    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(sample), path(npt_gro), path(topol), path(itps), path(md_mdp), val(outdir)


    output:
    tuple val(sample),
    path("${md_mdp.simpleName}.tpr"),
    path("${md_mdp.simpleName}.edr"),
    path("${md_mdp.simpleName}.gro"),
    path("${md_mdp.simpleName}.log"),
    path("topol.top"), path(itps), path("MD_REPORT"),
    val(outdir)
    emit: production_out


    script:
    """
    echo "Running the molecular dynamics simulation"
    ${params.gmx_cmd} grompp -f ${md_mdp} -c ${npt_gro} -p topol.top -o ${md_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${md_mdp.simpleName}
    ${params.gmx_cmd} report-methods -s ${md_mdp.simpleName}.tpr -o MD_REPORT

    echo "Simulation completed! Results saved in ${outdir}"
    """
}
