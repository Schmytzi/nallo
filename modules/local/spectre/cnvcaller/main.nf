

process SPECTRE_CNVCALLER {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "docker.io/schmytzi/spectre-cnv:0.2.1"

    input:
    tuple val(meta) , path(bed, stageAs: "in/*"), path(csi, stageAs: "in/*")
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)
    tuple val(meta4), path(metadata)  // reference metadata, optional
    tuple val(meta5), path(blacklist) // optional


    output:
    tuple val(meta), path("out/*.bed.gz")               , emit: bed
    tuple val(meat), path("out/*.bed.gz.tbi")           , emit: bed_tbi
    tuple val(meta), path("out/*.vcf.gz")               , emit: vcf
    tuple val(meta), path("out/*.vcf.gz.tbi")           , emit: vcf_tbi
    tuple val(meta), path("out/*.spc.gz")               , emit: spc
    tuple val(meta), path("out/img/*.png")              , emit: png
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def meta_arg = args.contains("--metadata") || !metadata ? "" : "--metadata $metadata"
    def blacklist_arg = args.contains("--blacklist") || !blacklist ? "" : "--blacklist $blacklist"
    """
    spectre \\
        CNVCaller \\
        $args \\
        $meta_arg \\
        $blacklist_arg \\
        --threads $task.cpus \\
        --sample-id ${meta.id} \\
        --coverage in \\
        --reference $fasta \\
        --output-dir out \\


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spectre: \$(spectre version |& sed '2!d ; s/.* Spectre version: //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir out
    cd out
    mkdir img
    touch ${meta.id}_cnv.bed.gz.tbi ${meta.id}.vcf.gz.tbi img/${meta.id}_plot_cnv_chr1.png
    echo "" | gzip > ${meta.id}_cnv.bed.gz
    echo "" | gzip > ${meta.id}.vcf.gz
    echo "" | gzip > ${meta.id}.spc.gz
    cd ..

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ont-spectre: \$(spectre version |& sed '1!d ; s/spectre::INFO> Spectre version: //')
    END_VERSIONS
    """
}
