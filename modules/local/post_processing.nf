#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    POST-PROCESSING Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - This process handles the post-processing of molecular dynamics simulation results.
//     - It removes possible periodicity artifacts along the trajectory.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process POST_PROCESSING {

    publishDir "${outdir}", mode: 'copy'

    input:
        path md_xtc
        path md_tpr
        val outdir

    output:
        path "md_noPBC.xtc"       , emit: post_xtc

    script:
    """
    echo "Starting post-processing to remove periodicity artifacts"
    echo "We center the protein and output the system"
    printf "1\n0\n" | ${params.gmx_cmd} trjconv -s ${md_tpr} -f ${md_xtc} -o md_noPBC.xtc -pbc mol -center
    echo "Post-processing completed! Processed trajectory saved as md_noPBC.xtc in ${outdir}"
    """
}
