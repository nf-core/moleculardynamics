#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    PDB_CHECKMISSING Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Reads a PDB file from the given path.
//     - Checks for missing atoms in the PDB file.
//     - Rises an error if any missing atoms are found. Stop the workflow.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PDB_CHECKMISSING {
    tag "$meta.id"
    label 'process_single'

    publishDir path: { "${params.outdir}/${meta.id}/preprocessing" }, mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }


        input:
        tuple val(meta), path(cleaned_pdb), val(force_field), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

        output:
        tuple val(meta),
              path("${meta.id}_checked.pdb"),
              val(force_field),
              path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
              emit: checked_pdb
          tuple val("${task.process}"),
              val('gromacs'),
              eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
              emit: versions_gromacs,
              topic: versions

        script:
        """
        if grep -q 'MISSING' "$cleaned_pdb"; then
            echo "ERROR: Missing atoms found in $cleaned_pdb" >&2
            grep 'MISSING' "$cleaned_pdb" >&2
            exit 1
        else
            cp "$cleaned_pdb" "${meta.id}_checked.pdb"
            echo "No missing atoms found in $cleaned_pdb"
        fi

        """

}
