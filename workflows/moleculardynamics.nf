/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_moleculardynamics_pipeline'

include { PRE_PROCESSING        } from '../subworkflows/local/pre_processing/main.nf'
include { RUN_MD_SIMULATION     } from '../subworkflows/local/run_md/main.nf'
include { POST_PROCESSING       } from '../modules/local/post_processing.nf'
include { ANALYSIS_RMSD         } from '../modules/local/analysis_rmsd.nf'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MOLECULARDYNAMICS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:
    // Print out parameters for logging
    log.info "📝 Pipeline parameters:\n${paramsSummaryMap(workflow)}"

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 0. Unpack samplesheet into a well-defined tuple channel
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

    ch_inputs = ch_samplesheet.map { meta, structure, em_mdp, nvt_mdp, npt_mdp, md_mdp, forcefield, box_type, distance_to_box ->
        def sample = meta.id
        // Reorder to match PRE_POS_CLEAN_PDB input declaration
        tuple(sample, structure, forcefield, box_type, distance_to_box, em_mdp, nvt_mdp, npt_mdp, md_mdp)
    }
    ch_inputs.view { "📦 Parsed sample inputs: $it" }


    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 1. Pre-processing: Clean PDB file
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    PRE_PROCESSING(ch_inputs)
    PRE_PROCESSING.out.cleaned_pdb.view { "✅ Cleaned PDB ready: $it" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 2-7. Run MD simulation: Energy minimization, equilibration, production run, post-processing
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    RUN_MD_SIMULATION(PRE_PROCESSING.out.cleaned_pdb)
    RUN_MD_SIMULATION.out.md_report.view { "✅ Production run completed!" }
    ch_md_tpr = RUN_MD_SIMULATION.out.md_tpr    // tuple(sample, tpr)
    ch_md_gro = RUN_MD_SIMULATION.out.md_gro    // tuple(sample, gro)
    ch_md_xtc = RUN_MD_SIMULATION.out.md_xtc    // tuple(sample, xtc)

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 8. Post-processing: Remove periodicity, fit to reference, etc.
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ch_post_input = ch_md_tpr.join(ch_md_xtc)   // tuple(sample, tpr, xtc)
    POST_PROCESSING(ch_post_input)
    ch_postprocessed_xtc = POST_PROCESSING.out.post_xtc   // tuple(sample, noPBC.xtc)

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 9. Analysis: RMSD calculation
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // Reference is the production .tpr (starting structure), not the final .gro
    ch_rmsd_input = ch_md_tpr.join(ch_postprocessed_xtc)   // tuple(sample, tpr, noPBC.xtc)
    ANALYSIS_RMSD(ch_rmsd_input)
    ANALYSIS_RMSD.out.rmsd_xvg.view { "✅ RMSD analysis completed: $it" }

    ch_versions = channel.topic('versions')

    // Collate and save software versions
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'moleculardynamics_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions           = ch_collated_versions        // channel: [ path(versions.yml) ]
    postprocessed_xtc  = ch_postprocessed_xtc        // channel: [ tuple(sample_id, path(postprocessed_xtc)) ]
    rmsd               = ANALYSIS_RMSD.out.rmsd_xvg  // channel: [ tuple(sample_id, path(rmsd.xvg)) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
