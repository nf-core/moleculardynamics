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
    outdir

    main:
    // Print out parameters for logging
    paramsSummaryMap(params, methodsDescriptionText(params)).view { "📝 Pipeline parameters:\n$it" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 0. Unpack samplesheet into a well-defined tuple channel
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

    ch_inputs = ch_samplesheet.map { row ->
        def sample        = row.sample
        def structure     = file(row.structure)
        def em_mdp        = file(row.em_mdp)
        def nvt_mdp       = file(row.nvt_mdp)
        def npt_mdp       = file(row.npt_mdp)
        def md_mdp        = file(row.md_mdp)
        def forcefield    = row.forcefield
        def box_type      = row.box_type ?: "cubic"
        def distance_to_box = (row.distance_to_box ?: "1") as Double

        tuple(sample, structure, em_mdp, nvt_mdp, npt_mdp, md_mdp, forcefield, box_type, distance_to_box)
    }
    ch_inputs.view { "📦 Parsed sample inputs: $it" }


    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 1. Pre-processing: Clean PDB file
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ch_preprocessing = PRE_PROCESSING(ch_inputs, params.outdir)
    PRE_PROCESSING.out.cleaned_pdb.view { "✅ Cleaned PDB ready: $it" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 2-7. Run MD simulation: Energy minimization, equilibration, production run, post-processing
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ch_trajectory = RUN_MD_SIMULATION(ch_preprocessing, params.outdir)
    RUN_MD_SIMULATION.out.md_report.view { "✅ Production run completed! You can see the report here: $it" }
    ch_md_tpr = ch_trajectory.md_tpr
    ch_md_gro = ch_trajectory.md_gro
    ch_md_xtc = ch_trajectory.md_xtc

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 8. Post-processing: Remove periodicity, fit to reference, etc.
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ch_postprocessed_data = POST_PROCESSING(ch_md_tpr, ch_md_gro, ch_md_xtc, params.outdir)
    POST_PROCESSING.out.postprocessed_report.view { "✅ Post-processing completed! You can see the report here: $it" }
    ch_postprocessed_xtc = ch_postprocessed_data.post_xtc

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 9. Analysis: RMSD calculation
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ANALYSIS_RMSD(ch_postprocessed_xtc, ch_postprocessed_gro, ch_postprocessed_tpr, params.outdir)
    ANALYSIS_RMSD.out.rmsd_xvg.view { "✅ RMSD analysis completed: $it" }

    def ch_versions = channel.empty()

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'moleculardynamics_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    collated_info           = ch_collated_versions        // channel: [ path(collated_versions.yml) ]
    cleaned_pdb             = ch_cleaned_pdb              // channel: [ tuple(sample_id, path(cleaned_pdb)) ]
    ch_postprocessed_xtc    = ch_postprocessed_xtc        // channel: [ tuple(sample_id, path(postprocessed_xtc)) ]
    versions                = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
