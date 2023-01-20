process count_reads {

  input:
    tuple val(meta), path(reads)

  output:
    tuple val(meta), stdout

  script:
  """
  lns=\$(cat ${reads} | wc -l)
  echo \$((\$lns/4))
  """
}
