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
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ANALYSIS_RMSD {

    publishDir "${outdir}/analysis", mode: 'copy'

    input:
        path md_noPBC_xtc
        path md_gro
        path md_topol
        val outdir

    output:
        path "rmsd.xvg"       , emit: rmsd_xvg

    script:
    """
    echo "Calculating RMSD for the protein along the trajectory"
    # Select group 3 (usually C-alpha atoms) for RMSD calculation over the protein (group 1)
    printf "3\n1\n" | ${params.gmx_cmd} rms -s ${md_gro} -f ${md_noPBC_xtc} -o rmsd.xvg -tu ns
    echo "RMSD analysis completed! Results saved in ${outdir}/analysis"
    """
}
