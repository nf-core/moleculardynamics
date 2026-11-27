process GROMACS_TRJCONV {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(tpr), path(xtc)
    val center_group
    val output_group

    output:
    tuple val(meta), path("${prefix}.xtc"), emit: xtc
    tuple val("${task.process}"), val('gromacs'), eval("${task.ext.gmx_cmd ?: 'gmx'} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"), emit: versions_gromacs, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gmx = task.ext.gmx_cmd ?: 'gmx'
    """
    printf "${center_group}\\n${output_group}\\n" | $gmx trjconv \\
        -s $tpr \\
        -f $xtc \\
        -o ${prefix}.xtc \\
        $args
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.xtc
    """
}
