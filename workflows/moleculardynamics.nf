/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_moleculardynamics_pipeline'

include { PRE_PROCESSING         } from '../subworkflows/local/pre_processing/main'
include { RUN_MD_SIMULATION      } from '../subworkflows/local/run_md/main'
include { GROMACS_TRJCONV        } from '../modules/local/gromacs/trjconv/main'
include { GROMACS_RMS            } from '../modules/local/gromacs/rms/main'


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
    log.info "📝 Pipeline parameters:\n${paramsSummaryMap(workflow)}"

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 0. Split the samplesheet into one channel per input, all keyed by meta
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // meta = [id, box_type, distance_to_box], as declared in assets/schema_input.json
    // Parameters file for the ion placement, shipped with the pipeline
    def ions_mdp = file("${projectDir}/assets/mdp/ions.mdp", checkIfExists: true)

    ch_samplesheet
        .multiMap { meta, structure, em_mdp, nvt_mdp, npt_mdp, md_mdp, force_field ->
            structure: [meta, structure]
            force_field: [meta, force_field]
            ions_mdp: [meta, ions_mdp]
            em_mdp: [meta, em_mdp]
            nvt_mdp: [meta, nvt_mdp]
            npt_mdp: [meta, npt_mdp]
            md_mdp: [meta, md_mdp]
        }
        .set { ch_inputs }
    ch_inputs.structure.view { sample -> "📦 Parsed sample inputs: ${sample}" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 1. Pre-processing: clean and check the PDB file
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    PRE_PROCESSING(ch_inputs.structure)
    PRE_PROCESSING.out.pdb.view { sample -> "✅ Cleaned PDB ready: ${sample}" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 2. Run MD simulation: topology, solvation, energy minimisation, equilibration and production
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    RUN_MD_SIMULATION(
        PRE_PROCESSING.out.pdb,
        ch_inputs.force_field,
        ch_inputs.ions_mdp,
        ch_inputs.em_mdp,
        ch_inputs.nvt_mdp,
        ch_inputs.npt_mdp,
        ch_inputs.md_mdp,
        params.water_model,
        'SOL',
    )
    RUN_MD_SIMULATION.out.report.view { "✅ Production run completed!" }

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 3. Post-processing: remove periodicity artefacts, centring the protein (group 1) and writing the system (group 0)
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    ch_trjconv = RUN_MD_SIMULATION.out.tpr.join(RUN_MD_SIMULATION.out.xtc, failOnMismatch: true, failOnDuplicate: true)
    GROMACS_TRJCONV(ch_trjconv, '1', '0')

    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // STEP 4. Analysis: RMSD, with the least squares fit and the RMSD both computed on C-alpha (group 3)
    // ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    // Reference is the production .tpr (starting structure), not the final .gro
    ch_rms = RUN_MD_SIMULATION.out.tpr.join(GROMACS_TRJCONV.out.xtc, failOnMismatch: true, failOnDuplicate: true)
    GROMACS_RMS(ch_rms, '3', '3')
    GROMACS_RMS.out.xvg.view { sample -> "✅ RMSD analysis completed: ${sample}" }

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
    versions           = ch_collated_versions        // channel: [ path(versions.yml) ]
    postprocessed_xtc  = GROMACS_TRJCONV.out.xtc     // channel: [ tuple(meta, path(postprocessed_xtc)) ]
    rmsd               = GROMACS_RMS.out.xvg         // channel: [ tuple(meta, path(rmsd.xvg)) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
