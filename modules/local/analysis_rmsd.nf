#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    RMSD ANALYSIS Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - This process calculates the Root Mean Square Deviation (RMSD) of a molecular dynamics trajectory.
//     - It uses GROMACS tools to perform the analysis and outputs the RMSD data and plot.
//     - The reference is the production run .tpr, i.e. the starting structure (first frame) of the trajectory.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ANALYSIS_RMSD {
    label 'process_low'

    publishDir "${params.outdir}/${sample}/analysis", mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(sample), path(md_tpr), path(md_noPBC_xtc)

    output:
    tuple val(sample), path("rmsd.xvg"), emit: rmsd_xvg
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    """
    echo "Calculating RMSD for the protein along the trajectory"
    # Reference: starting structure stored in the production .tpr (first frame of the trajectory)
    # Least-squares fit and RMSD both computed over group 3 (C-alpha)
    printf "3\n3\n" | ${params.gmx_cmd} rms -s ${md_tpr} -f ${md_noPBC_xtc} -o rmsd.xvg -tu ns

    echo "RMSD analysis completed!"
    """
}
