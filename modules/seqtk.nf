process subsample_reads {
  input:
    tuple val(meta), path(reads)
    val(sample_size)

  output:
    tuple val(meta), path("*sub.fastq")

  script:
  """
  seqtk sample -s\${RANDOM} $reads ${sample_size} > ${meta.sample}_sub.fastq
  """
}