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

    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(sample), path(checked_pdb), val(forcefield), val(box_type), val(distance_to_box), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp) into checked_pdb

    output:
    tuple val(sample),
        path("${sample}.gro"),    // gro file
        path("topol.top"),                        // topology
        path("*.itp"),                             // itp files
        path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
        val(forcefield), val(box_type), val(distance_to_box)
        emit: topology_out

    script:
    """
    echo "Loading data from ${checked_pdb} and generating GROMACS topology file (.gro)"
    ${params.gmx_cmd} pdb2gmx -f ${checked_pdb} -o ${sample}.gro -i posre.itp -ff ${forcefield} -water spce -ignh
    """
}
