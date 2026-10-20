# nf-core/moleculardynamics: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev - [unreleased<!-- TODO nf-core: replace with date on release -->]

Initial release of nf-core/moleculardynamics, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- `test` (2 ps production, ~1.5 min on 4 CPUs) and `test_full` (50 ps) profiles using the lysozyme (PDB 1AKI) dataset from nf-core/test-datasets#1949.
- `gmx_cmd`, `water_model`, `water_coordinates`, `ion_concentration`, `gromacs_container` and `gromacs_conda` documented and validated in `nextflow_schema.json`.
- Output documentation (`docs/output.md`), updated usage documentation (`docs/usage.md`) and GROMACS citation in `README.md` and `CITATIONS.md`.

### `Changed`

- Template update to nf-core/tools 4.1.0: the pipeline now works with the latest Nextflow (26.x). Software versions are collated from the `versions` topic by the template's own code, so the local patch to `utils_nfcore_pipeline` is no longer needed and has been removed. `nextflow.preview.topic` and the help/summary banners in `nextflow.config` are gone.
- Results are now published per sample (`<outdir>/<sample>/<step>/`), so samples no longer overwrite each other's outputs.
- Input MDP files are no longer copied into every output folder.

### `Fixed`

- RMSD is now computed against the starting structure (production `.tpr`, frame 0) instead of the last frame, using C-alpha atoms for both fit and RMSD.
- `publishDir` paths are closures, as required by Nextflow >= 25.10 (a plain string failed with `No such variable: sample`).
- Samplesheet `forcefield` values are restricted to force fields included with GROMACS 2022 (`charmm36`, `amber14sb` and `amber` were accepted but failed at `pdb2gmx`).
- `manifest.defaultBranch` set to `main`.
- nf-test: corrected test-data base path and software versions file name.
- Lint: regenerated logos and LICENSE still referring to the old `mdsimulations` name, and removed an empty local subworkflow that crashed lint.

### `Dependencies`

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| Nextflow   | >=24.10.5   | >=25.10.4   |
| nf-schema  | 2.4.2       | 2.5.1       |

### `Deprecated`
