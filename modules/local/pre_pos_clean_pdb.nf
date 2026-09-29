#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    CLEAN_PDB Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Reads a PDB file from the given path.
//     - Removes HETATM and CONECT entries.
//     - Outputs a cleaned PDB file.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PRE_POS_CLEAN_PDB {
    label 'process_single'

    publishDir "${params.outdir}/${sample}/preprocessing", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(pdb), val(forcefield), val(box_type), val(distance_to_box), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(sample), path("${sample}_cleaned.pdb"), val(forcefield), val(box_type), val(distance_to_box),
        path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
        emit: cleaned
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    grep -v HETATM "$pdb" > "${sample}_temp.pdb"
    grep -v CONECT "${sample}_temp.pdb" > "${sample}_cleaned.pdb"

    """
    
}