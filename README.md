<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-moleculardynamics_logo_dark.png">
    <img alt="nf-core/moleculardynamics" src="docs/images/nf-core-moleculardynamics_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/moleculardynamics/actions/workflows/nf-test.yml/badge.svg)](https://github.com/nf-core/moleculardynamics/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/moleculardynamics/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/moleculardynamics/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/moleculardynamics/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A524.10.5-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.3.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.3.2)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/moleculardynamics)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23moleculardynamics-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/moleculardynamics)[![Follow on Bluesky](https://img.shields.io/badge/bluesky-%40nf__core-1185fe?labelColor=000000&logo=bluesky)](https://bsky.app/profile/nf-co.re)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

# Introduction

**nf-core/moleculardynamics** is a bioinformatics pipeline for running molecular dynamic simulations (MD) using [GROMACS](https://www.gromacs.org/). This workflow enables researchers to perform standard protein simulations in a fully automated manner, with minimal configuration, on both local and high-performance computing (HPC) environments.

It takes a protein structure (PDB) and GROMACS parameter files (MDP) for each sample, prepares the system (topology, solvation, ions), runs energy minimisation, NVT/NPT equilibration and a production simulation, and returns the trajectory together with a first structural analysis (RMSD).

We are currently working on the following tasks:

1.  🚀📆 Official release of the `nf-core/moleculardynamics` pipeline.
2.  🛠👩‍💻 Expanding the pipeline’s capabilities to include more analysis modules (e.g., RMSF, distances), and integrating specialized tools for membrane proteins and protein-ligand complexes.

# Pipeline

<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/pipeline_v1.png">
    <img alt="nf-core/moleculardynamics" src="docs/images/pipeline_v1.png">
  </picture>
</h1>

The `nf-core/moleculardynamics` pipeline automates a standard GROMACS MD simulation workflow. The major steps are:

- **Input pre-processing:** Remove heteroatoms (ligands, ions, waters) from the PDB structure and check that no atoms are missing.
- **MD simulation:** Main subworkflow of the pipeline.
  - **Generation of molecular topology**,
  - **System solvation**, and ion addition to neutralize the system.
  - **Energy Minimization:** Removal of steric clashes and relaxation of the initial structure.
  - **Equilibration:** NVT (constant Number, Volume, Temperature) and NPT (constant Number, Pressure, Temperature) equilibration to bring the system to the desired temperature and density.
  - **Production MD:** Execution of the main molecular dynamics simulation.
- **Post-processing:** Centre the protein and remove periodic boundary condition (PBC) artifacts from the trajectory.
- **Analysis:** Calculation of the Root-Mean-Square Deviation (RMSD) relative to the starting structure.

# Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,structure,em_mdp,nvt_mdp,npt_mdp,md_mdp,forcefield,box_type,distance_to_box
LYSOZYME,/data/1AKI.pdb,/data/em.mdp,/data/nvt.mdp,/data/npt.mdp,/data/md.mdp,charmm27,cubic,1.0
```

Each row represents one protein system to simulate, with its structure, the MDP files for each simulation step, and the force field and box settings.

Now, you can run the pipeline using:

```bash
nextflow run nf-core/moleculardynamics \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/moleculardynamics/usage) and the [parameter documentation](https://nf-co.re/moleculardynamics/parameters).

# Pipeline output

Results are organised per sample (`<outdir>/<sample>/<step>/`) and include the prepared system, the equilibration and production trajectories, a PBC-corrected trajectory and the RMSD analysis.

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/moleculardynamics/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/moleculardynamics/output).

# Credits

nf-core/moleculardynamics has been developed by Sara Tolosa Alarcón ([@sarata00](https://github.com/sarata00)) from the [Computational Biology Group](https://www.bsc.es/discover-bsc/organisation/scientific-structure/computational-biology) at the [Barcelona Supercomputing Center](https://www.bsc.es/) under the [deCYPher project](https://www.decypher.bio/) and supervision of Miguel Romero-Durana ([@migromero](https://github.com/migromero)).

# Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#moleculardynamics` channel](https://nfcore.slack.com/channels/moleculardynamics) (you can join with [this invite](https://nf-co.re/join/slack)).

# Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/moleculardynamics for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

All simulation and analysis steps of this pipeline are run with [GROMACS](https://www.gromacs.org/). If you use nf-core/moleculardynamics, please also cite GROMACS:

> **GROMACS: High performance molecular simulations through multi-level parallelism from laptops to supercomputers.**
>
> Mark James Abraham, Teemu Murtola, Roland Schulz, Szilárd Páll, Jeremy C. Smith, Berk Hess & Erik Lindahl.
>
> _SoftwareX._ 2015;1-2:19-25. doi: [10.1016/j.softx.2015.06.001](https://doi.org/10.1016/j.softx.2015.06.001).

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
