process GROMACS_PDB2GMX {
    tag "$meta.id"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/gromacs:2022'
        : 'quay.io/biocontainers/gromacs:2022'}"

    input:
    tuple val(meta), path(pdb), val(force_field)
    val water_model

    output:
    tuple val(meta), path("${prefix}.gro"), emit: gro
    tuple val(meta), path("topol.top"), emit: top
    tuple val(meta), path("*.itp"), emit: itp
    tuple val("${task.process}"), val('gromacs'), eval("${task.ext.gmx_cmd ?: 'gmx'} --version 2>/dev/null | sed -n 's/^GROMACS version:[[:space:]]*//p' | head -n 1 || true"), emit: versions_gromacs, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def gmx = task.ext.gmx_cmd ?: 'gmx'
    """
    $gmx pdb2gmx \\
        -f $pdb \\
        -o ${prefix}.gro \\
        -ff $force_field \\
        -water $water_model \\
        $args
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.gro
    touch topol.top
    touch posre.itp
    """
}
