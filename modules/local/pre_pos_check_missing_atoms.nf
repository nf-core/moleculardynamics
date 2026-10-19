#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    CHECK_MISSING_ATOMS Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Reads a PDB file from the given path.
//     - Checks for missing atoms in the PDB file.
//     - Rises an error if any missing atoms are found. Stop the workflow.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PRE_POS_CHECK_MISSING_ATOMS {

        input:
        tuple val(sample), path(cleaned_pdb), val(forcefield), val(box_type), val(distance_to_box), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

        output:
        tuple val(sample),
              path("${sample}_checked.pdb"),
              val(forcefield), val(box_type), val(distance_to_box),
              path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)
              emit: checked_pdb

        script:
        """
        if grep -q 'MISSING' "$cleaned_pdb"; then
            echo "ERROR: Missing atoms found in $pdb_file" >&2
            grep 'MISSING' "$cleaned_pdb" >&2
            exit 1
        else
            cp "$cleaned_pdb" "${sample}_checked.pdb"
            echo "No missing atoms found in $cleaned_pdb"
        fi
        """

}
