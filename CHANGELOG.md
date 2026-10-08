# nf-core/moleculardynamics: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0dev

Initial release of nf-core/moleculardynamics, created with the [nf-core](https://nf-co.re/) template.

**Fixed**
- Fix RMSD calculation bug: it  is now computed against the starting structure (production `.tpr`, frame 0) instead of the last frame, using C-alpha atoms for both fit and RMSD.
- Results are published per sample (`<outdir>/<sample>/<step>/`).
- Input MDP files are no longer copied into every output folder.
- Samplesheet `forcefield` values restricted to force fields included with GROMACS 2022.
- `manifest.defaultBranch` set to `main`.
- nf-test: corrected test-data base path and software versions file name.
- Lint: regenerated logos and LICENSE still referring to the old `mdsimulations` name, synced RO-Crate, recorded the local change to `utils_nfcore_pipeline` (topic-channel versions) as a patch, removed an empty local subworkflow that crashed lint.

**Added**
- `test` (2 ps production, ~1.5 min on 4 CPUs) and `test_full` (50 ps) profiles using the lysozyme (PDB 1AKI) dataset from nf-core/test-datasets#1949.
- `gmx_cmd`, `water_model`, `water_coordinates`, `ion_concentration`, `gromacs_container` and `gromacs_conda` documented and validated in `nextflow_schema.json`.
- `docs/output.md`, updated `docs/usage.md`, update citations in `README.md` and `CITATIONS.md`.
