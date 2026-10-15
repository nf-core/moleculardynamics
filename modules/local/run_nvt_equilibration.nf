#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    NVT EQUILIBRATION Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Perform NVT equilibration.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RUN_NVT_EQUILIBRATION {

    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(sample), path(em_gro), path(topol), path(itps), path(nvt_mdp), path(npt_mdp), path(md_mdp), val(outdir)

    output:
    tuple val(sample),
        path("${nvt_mdp.simpleName}.tpr"),
        path("${nvt_mdp.simpleName}.edr"),
        path("${nvt_mdp.simpleName}.gro"),
        path("${nvt_mdp.simpleName}.log"),
        path("topol.top"),
        path(itps),
        path(npt_mdp), path(md_mdp)
        emit: nvt_equilibration_out

    script:
    """
    echo "Performing NVT equilibration"
    ${params.gmx_cmd} grompp -f ${nvt_mdp} -c ${em_gro} -r ${em_gro} -p topol.top -o ${nvt_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${nvt_mdp.simpleName}
    echo "NVT equilibration completed"
    """
}
