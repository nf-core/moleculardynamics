# nf-core/moleculardynamics: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

Results are grouped per sample: each row of the samplesheet gets its own `<sample>/` directory containing one subdirectory per step. Only `pipeline_info/` is shared by all samples:

```
<outdir>/
├── <sample>/
│   ├── preprocessing/
│   ├── topology/
│   ├── solvation/
│   ├── energy_minimization/
│   ├── nvt_equilibration/
│   ├── npt_equilibration/
│   ├── production/
│   ├── post_processing/
│   └── analysis/
└── pipeline_info/
```

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and runs a standard [GROMACS](https://www.gromacs.org/) molecular dynamics workflow using the following steps:

- [Pre-processing](#pre-processing) - Remove heteroatoms from the input structure and check for missing atoms
- [Topology](#topology) - Generate the GROMACS topology
- [Solvation](#solvation) - Define the simulation box, solvate the system and add ions
- [Energy minimisation](#energy-minimisation) - Relax the solvated system
- [NVT equilibration](#nvt-equilibration) - Equilibrate temperature at constant volume
- [NPT equilibration](#npt-equilibration) - Equilibrate pressure and density
- [Production](#production) - Run the production MD simulation
- [Post-processing](#post-processing) - Centre the protein and remove periodic boundary effects from the trajectory
- [Analysis](#analysis) - Compute the RMSD of the protein along the trajectory
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### File naming

- `<sample>` in directory and file names is the value of the `sample` column of the samplesheet.
- Files produced by `gmx grompp` and `gmx mdrun` (`.tpr`, `.gro`, `.edr`, `.log`, `.xtc`) are named after the MDP file used for that step. For example, if the samplesheet column `em_mdp` points to `em.mdp`, the energy minimisation outputs are `em.tpr`, `em.gro`, `em.edr` and `em.log`. In the sections below, `<em>`, `<nvt>`, `<npt>` and `<md>` stand for the base names of the `em_mdp`, `nvt_mdp`, `npt_mdp` and `md_mdp` files.

### Pre-processing

<details markdown="1">
<summary>Output files</summary>

- `<sample>/preprocessing/`
  - `<sample>_cleaned.pdb`: input structure with all `HETATM` (ligands, ions, crystallographic waters, cofactors) and `CONECT` records removed.
  - `<sample>_checked.pdb`: the cleaned structure after checking for missing atoms. It is only written if no missing atoms are found; otherwise the pipeline stops with an error.

</details>

The input PDB is reduced to the protein, then checked for missing atoms, which would make topology generation fail.

### Topology

<details markdown="1">
<summary>Output files</summary>

- `<sample>/topology/`
  - `<sample>.gro`: processed protein coordinates in GROMACS format.
  - `topol.top`: system topology for the chosen force field (`forcefield` column) and water model (`--water_model`).
  - `posre*.itp`: position restraint file(s) for heavy atoms, used during equilibration (`define = -DPOSRES`). Proteins with several chains get one `.itp` file per chain.

</details>

[`gmx pdb2gmx`](https://manual.gromacs.org/current/onlinehelp/gmx-pdb2gmx.html) builds the topology and adds hydrogens. Hydrogens present in the input structure are ignored (`-ignh`) and rebuilt according to the force field.

### Solvation

<details markdown="1">
<summary>Output files</summary>

- `<sample>/solvation/`
  - `<sample>_box.gro`: protein centred in the simulation box.
  - `<sample>_box_solv.gro`: box filled with water molecules.
  - `<sample>_box_solv_ions.gro`: solvated system after adding ions. This is the starting structure for energy minimisation.
  - `ions.tpr`: run input file used by `gmx genion` to place the ions.
  - `topol.top`: topology updated with the number of water molecules and ions.
  - `posre*.itp`: position restraint file(s).

</details>

- [`gmx editconf`](https://manual.gromacs.org/current/onlinehelp/gmx-editconf.html) defines the box, using the samplesheet's `box_type` and `distance_to_box` columns.
- [`gmx solvate`](https://manual.gromacs.org/current/onlinehelp/gmx-solvate.html) fills the box with water, using the solvent box given by `--water_coordinates`.
- [`gmx genion`](https://manual.gromacs.org/current/onlinehelp/gmx-genion.html) replaces water molecules with Na⁺ and Cl⁻ ions. This neutralises the system and brings the salt concentration to `--ion_concentration` (default 0.15 M).

### Energy minimisation

<details markdown="1">
<summary>Output files</summary>

- `<sample>/energy_minimization/`
  - `<em>.gro`: minimised structure.
  - `<em>.tpr`: run input file.
  - `<em>.edr`: energy file, e.g. for plotting the potential energy with `gmx energy`.
  - `<em>.log`: GROMACS log with the final potential energy and maximum force.
  - `topol.top`, `posre*.itp`: topology files used by this step.

</details>

Energy minimisation removes steric clashes before dynamics starts. To check whether it converged, look for `converged to Fmax < ...` near the end of `<em>.log`.

### NVT equilibration

<details markdown="1">
<summary>Output files</summary>

- `<sample>/nvt_equilibration/`
  - `<nvt>.gro`: structure at the end of NVT equilibration.
  - `<nvt>.tpr`: run input file.
  - `<nvt>.edr`: energy file, e.g. for checking that the temperature converged with `gmx energy`.
  - `<nvt>.log`: GROMACS log.
  - `topol.top`, `posre*.itp`: topology files used by this step.

</details>

The system is heated to the target temperature at constant volume, with the protein heavy atoms position-restrained.

### NPT equilibration

<details markdown="1">
<summary>Output files</summary>

- `<sample>/npt_equilibration/`
  - `<npt>.gro`: structure at the end of NPT equilibration.
  - `<npt>.tpr`: run input file.
  - `<npt>.edr`: energy file, e.g. for checking pressure and density with `gmx energy`.
  - `<npt>.log`: GROMACS log.
  - `topol.top`, `posre*.itp`: topology files used by this step.

</details>

Pressure and density are equilibrated, again with the protein heavy atoms position-restrained.

### Production

<details markdown="1">
<summary>Output files</summary>

- `<sample>/production/`
  - `<md>.xtc`: compressed trajectory of the production run, as periodic images (see [Post-processing](#post-processing)).
  - `<md>.gro`: final structure of the production run.
  - `<md>.tpr`: run input file. It contains the full system and the starting coordinates, and is the reference for analysis tools.
  - `<md>.edr`: energy file.
  - `<md>.log`: GROMACS log, including performance (ns/day).
  - `MD_REPORT.out`: methods summary written by [`gmx report-methods`](https://manual.gromacs.org/current/onlinehelp/gmx-report-methods.html) (system size, integrator, time step, thermostat and barostat settings), which can be used as a starting point for the methods section of a publication.

</details>

The production run is unrestrained MD, run with the settings in the `md_mdp` file.

### Post-processing

<details markdown="1">
<summary>Output files</summary>

- `<sample>/post_processing/`
  - `md_noPBC.xtc`: production trajectory with the protein centred in the box and molecules made whole across periodic boundaries.

</details>

[`gmx trjconv`](https://manual.gromacs.org/current/onlinehelp/gmx-trjconv.html) is run with `-pbc mol -center`, centring on the protein and writing the whole system. Use this trajectory, not the raw `<sample>/production/<md>.xtc`, for visualisation and analysis. For example, in VMD: `vmd <sample>/production/<md>.gro <sample>/post_processing/md_noPBC.xtc`.

### Analysis

<details markdown="1">
<summary>Output files</summary>

- `<sample>/analysis/`
  - `rmsd.xvg`: C-alpha RMSD (nm) against time (ns). Plot it with e.g. [Grace](https://plasma-gate.weizmann.ac.il/Grace/) (`xmgrace rmsd.xvg`) or Python; lines starting with `#` or `@` are headers.

</details>

[`gmx rms`](https://manual.gromacs.org/current/onlinehelp/gmx-rms.html) computes the root-mean-square deviation of the C-alpha atoms, after a least-squares fit on the C-alpha atoms. The reference is the starting structure of the production run (`<sample>/production/<md>.tpr`), so the RMSD is 0 at t = 0. A plateau in the RMSD suggests that the protein structure has stabilised during the simulation.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report_<timestamp>.html`, `execution_timeline_<timestamp>.html`, `execution_trace_<timestamp>.txt` and `pipeline_dag_<timestamp>.html`.
  - Parameters used by the pipeline run: `params_<timestamp>.json`.
  - Software versions used for each process: `nf_core_moleculardynamics_software_versions.yml`.
  - Reports generated by the pipeline: `pipeline_report.html` and `pipeline_report.txt`. These files are only present if the `--email` / `--email_on_fail` parameters are used when running the pipeline.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
