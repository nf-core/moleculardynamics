process PDB_CHECKMISSING {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(pdb)

    output:
    tuple val(meta), path("${prefix}.pdb"), emit: pdb
    tuple val("${task.process}"), val('grep'), eval("{ grep --version 2>&1 || true; grep --help 2>&1 || true; } | sed -n -E 's/^.*(BusyBox v|GNU grep[^0-9]*)([0-9]+[.][0-9.]+).*/\\2/p' | head -n 1 || true"), emit: versions_grep, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    if grep -q $args 'MISSING' $pdb; then
        echo "ERROR: Missing atoms found in $pdb" >&2
        grep $args 'MISSING' $pdb >&2
        exit 1
    fi
    cp $pdb ${prefix}.pdb
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    touch ${prefix}.pdb
    """
}
