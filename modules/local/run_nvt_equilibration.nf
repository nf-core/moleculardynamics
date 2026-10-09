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
    label 'process_medium'

    publishDir "${params.outdir}/${sample}/nvt_equilibration", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(em_gro), path(topol), path(itps), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(sample),
        path("${nvt_mdp.simpleName}.gro"),
        path("topol.top"),
        path(itps),
        path(npt_mdp), path(md_mdp),
        emit: nvt_equilibration_out
    path "${nvt_mdp.simpleName}.tpr"
    path "${nvt_mdp.simpleName}.edr"
    path "${nvt_mdp.simpleName}.log"
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    echo "Performing NVT equilibration"
    ${params.gmx_cmd} grompp -f ${nvt_mdp} -c ${em_gro} -r ${em_gro} -p topol.top -o ${nvt_mdp.simpleName}.tpr
    ${params.gmx_cmd} mdrun -v -deffnm ${nvt_mdp.simpleName}
    echo "NVT equilibration completed"

    """
}
