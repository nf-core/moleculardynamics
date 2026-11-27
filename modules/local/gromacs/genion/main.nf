process GROMACS_GENION {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(tpr), path(top)
    val solvent_group

    output:
    tuple val(meta), path("${prefix}.gro"), emit: gro
    tuple val(meta), path("topol.top"), emit: top
    tuple val("${task.process}"), val('gromacs'), eval("${task.ext.gmx_cmd ?: 'gmx'} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"), emit: versions_gromacs, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gmx = task.ext.gmx_cmd ?: 'gmx'
    """
    printf "${solvent_group}\\n" | $gmx genion \\
        -s $tpr \\
        -o ${prefix}.gro \\
        -p $top \\
        $args
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.gro
    touch topol.top
    """
}
