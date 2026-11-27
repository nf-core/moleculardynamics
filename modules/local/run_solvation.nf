#!/usr/bin/env nextflow

/*
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     nf-core/moleculardynamics
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Github : https://github.com/nf-core/moleculardynamics
// ----------------------------------------------------------------------------------------
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//    SOLVATION Process
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     Description:
//     - Define the box where the system will be solvated (options: triclinic, cubic, dodecahedron and octahedron)
//       by using the `gmx editconf` command.
//     - Solvate the system with water molecules using the `gmx solvate` command.
//     - Add ions to neutralize the system using the `gmx genion` command.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


process RUN_SOLVATION {
    tag "$meta.id"
    label 'process_medium'

    publishDir path: { "${params.outdir}/${meta.id}/solvation" }, mode: 'copy', saveAs: { filename -> filename.endsWith('.mdp') ? null : filename }

    input:
    tuple val(meta), path(gro), path(topol), path(itps), path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp)

    output:
    tuple val(meta),
        path("${meta.id}_box_solv_ions.gro"),
        path("topol.top"),
        path(itps),
        path(em_mdp), path(nvt_mdp), path(npt_mdp), path(md_mdp),
        emit: solvation_out
    path "${meta.id}_box.gro"
    path "${meta.id}_box_solv.gro"
    path "ions.tpr"
    tuple val("${task.process}"),
        val('gromacs'),
        eval("${params.gmx_cmd} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"),
        emit: versions_gromacs,
        topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    echo "Defining the box for ${gro} and solvating the system"
    ${params.gmx_cmd} editconf -f ${gro} -o ${meta.id}_box.gro ${args}
    ${params.gmx_cmd} solvate -cp ${meta.id}_box.gro -cs ${params.water_coordinates} -o ${meta.id}_box_solv.gro -p topol.top
    echo "Adding ions to neutralize the system"
    touch ions.mdp
    ${params.gmx_cmd} grompp -f ions.mdp -c ${meta.id}_box_solv.gro -p topol.top -o ions.tpr
    printf "SOL\n" | ${params.gmx_cmd} genion -s ions.tpr -o ${meta.id}_box_solv_ions.gro -p topol.top -neutral -conc ${params.ion_concentration} -pname NA -nname CL

    """
}
