//
// Define the simulation box, add the solvent and replace solvent molecules with ions
//
include { GROMACS_EDITCONF                      } from '../../../modules/local/gromacs/editconf/main'
include { GROMACS_SOLVATE                       } from '../../../modules/local/gromacs/solvate/main'
include { GROMACS_GROMPP as GROMACS_GROMPP_IONS } from '../../../modules/local/gromacs/grompp/main'
include { GROMACS_GENION                        } from '../../../modules/local/gromacs/genion/main'

workflow GROMACS_SOLVATION {
    take:
    ch_gro            // channel: [ val(meta), path(gro) ]
    ch_top            // channel: [ val(meta), path(top) ]
    ch_itp            // channel: [ val(meta), path(itp) ]
    ch_mdp            // channel: [ val(meta), path(mdp) ], parameters used to prepare the ion placement
    val_solvent_group // string:  group whose molecules are replaced by ions

    main:
    GROMACS_EDITCONF(ch_gro)

    GROMACS_SOLVATE(GROMACS_EDITCONF.out.gro.join(ch_top, failOnMismatch: true, failOnDuplicate: true))

    // No position restraints are needed here, hence the empty list
    ch_grompp = ch_mdp
        .join(GROMACS_SOLVATE.out.gro, failOnMismatch: true, failOnDuplicate: true)
        .join(GROMACS_SOLVATE.out.top, failOnMismatch: true, failOnDuplicate: true)
        .join(ch_itp, failOnMismatch: true, failOnDuplicate: true)
        .map { meta, mdp, gro, top, itp -> [meta, mdp, gro, top, itp, []] }
    GROMACS_GROMPP_IONS(ch_grompp)

    GROMACS_GENION(
        GROMACS_GROMPP_IONS.out.tpr.join(GROMACS_SOLVATE.out.top, failOnMismatch: true, failOnDuplicate: true),
        val_solvent_group,
    )

    emit:
    gro = GROMACS_GENION.out.gro // channel: [ val(meta), path(gro) ]
    top = GROMACS_GENION.out.top // channel: [ val(meta), path(top) ]
}
