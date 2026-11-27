#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    TOPOLOGY Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Reads a cleaned PDB file from the output of PRE_PROCESSING subworkflow.
//     - Generates a GROMACS topology file (.gro) and position restraint file (.itp).
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


process RUN_TOPOLOGY {
    tag "$meta.id"
    label 'process_medium'

    publishDir path: { "${params.outdir}/${meta.id}/topology" }, mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(meta), path(checked_pdb), val(force_field), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(meta),
        path("${meta.id}.gro"),
        path("topol.top"),
        path("*.itp"),
        path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
        emit: topology_out
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    echo "Loading data from ${checked_pdb} and generating GROMACS topology file (.gro)"
    ${params.gmx_cmd} pdb2gmx -f ${checked_pdb} -o ${meta.id}.gro -i posre.itp -ff ${force_field} -water ${params.water_model} -ignh

    """
}
