process GROMACS_GROMPP {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(mdp), path(gro), path(top), path(itp), path(restraint_gro, stageAs: 'restraint/*')

    output:
    tuple val(meta), path("${prefix}.tpr"), emit: tpr
    tuple val("${task.process}"), val('gromacs'), eval("${task.ext.gmx_cmd ?: 'gmx'} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"), emit: versions_gromacs, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gmx = task.ext.gmx_cmd ?: 'gmx'
    def restraint = restraint_gro ? "-r ${restraint_gro}" : ''
    """
    $gmx grompp \\
        -f $mdp \\
        -c $gro \\
        $restraint \\
        -p $top \\
        -o ${prefix}.tpr \\
        $args
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.tpr
    """
}
