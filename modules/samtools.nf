process concat_reads {

    input:
    tuple val(meta), path(readsin)

    output:
    tuple val(meta), path ("*.fastq"), emit: reads

    script:    
    """
    zcat $readsin > ${meta.sample}.fastq
    """
}

process get_mapped_reads {

    input:
    tuple val(meta), path(readsin)
    path(target)
    path(target_index)

    output:
    tuple val(meta), path ("*.fastq"), emit: reads

    script:
    """
    bwa mem -M -t $task.cpus -p $target $readsin | \
    samtools view -F 4 -b |\
    samtools fastq > ${meta.sample}.fastq
    """
}

process get_mapped_reads_notbg {

    input:
    tuple val(meta), path(readsin)
    path(target)
    path(target_index)
    path(background)
    path(background_index)

    output:
    tuple val(meta), path ("*.fastq"), emit: reads

    script:
    """
    bwa mem -M -t $task.cpus -p $target $readsin | \
    samtools fastq -F 4 | \
    bwa mem -M -t $task.cpus -p $background - | \
    samtools fastq -f 4 > ${meta.sample}.fastq
    """

}

