process jellyfish_count {
  input:
  tuple val(meta), path(reads)

  output:
  tuple val(meta), path("*.jf")

  script:
  """
  jellyfish count -t ${task.cpus} -m 21 -s 10000000 $reads -o ${meta.sample}.jf
  """
}

