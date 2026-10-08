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
    label 'process_medium'

    publishDir "${params.outdir}/${sample}/topology", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(checked_pdb), val(forcefield), val(box_type), val(distance_to_box), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(sample),
        path("${sample}.gro"),
        path("topol.top"),
        path("*.itp"),
        path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
        val(forcefield), val(box_type), val(distance_to_box),
        emit: topology_out
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    echo "Loading data from ${checked_pdb} and generating GROMACS topology file (.gro)"
    ${params.gmx_cmd} pdb2gmx -f ${checked_pdb} -o ${sample}.gro -i posre.itp -ff ${forcefield} -water ${params.water_model} -ignh

    """
}
