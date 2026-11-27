process GROMACS_MDRUN {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(tpr)

    output:
    tuple val(meta), path("${prefix}.gro"), emit: gro
    tuple val(meta), path("${prefix}.edr"), emit: edr
    tuple val(meta), path("${prefix}.log"), emit: log
    tuple val(meta), path("${prefix}.xtc"), emit: xtc, optional: true
    tuple val("${task.process}"), val('gromacs'), eval("${task.ext.gmx_cmd ?: 'gmx'} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"), emit: versions_gromacs, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gmx = task.ext.gmx_cmd ?: 'gmx'
    """
    $gmx mdrun \\
        -s $tpr \\
        -deffnm ${prefix} \\
        $args
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.gro
    touch ${prefix}.edr
    touch ${prefix}.log
    touch ${prefix}.xtc
    """
}
