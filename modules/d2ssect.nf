process d2s_pair {
  publishDir "$params.outdir/d2ssect", mode: 'copy'

  input:
  tuple val(meta1), path(r1), path(jf1), val(meta2), path(r2), path(jf2)

  output:
  path("*.txt")

  script:
  """
  d2ssect -l $jf1 $jf2 -f $r1 $r2 > ${meta1.i}-${meta2.i}.txt
  """
}

process gather_d2s_matrix {
  publishDir "$params.outdir/d2ssect", mode: 'copy'

  input:
  path(pairs)

  output:
  path("matrix.tsv")

  """
#!/usr/bin/env python3  
from os import listdir
import sys

def read_pairfile(path):
  i,j = path[:-4].split("-")
  with open(path,'r') as fh:
    name1,name2,d2s = "","",0
    name1,zero,d2s = fh.readline().rstrip().split()
    name2,d2s,zero = fh.readline().rstrip().split()

  return int(i),int(j),name1,name2,float(d2s)

out = open("matrix.tsv","w")
pair_results=[]

n_sample=0
for entry in listdir():
  if entry.endswith(".txt"):
    pr=read_pairfile(entry)
    if max(pr[0],pr[1]) > n_sample:
      n_sample=max(pr[0],pr[1])
    pair_results.append(pr)

d2s_matrix = [([0]*n_sample) for i in range(n_sample)]

sample_names=["" for i in range(n_sample)]
for pr in pair_results:
  i,j,v = pr[0]-1,pr[1]-1,pr[4]
  sample_names[i]=pr[2]
  sample_names[j]=pr[3]
  d2s_matrix[i][j] = v
  d2s_matrix[j][i] = v

for r in range(n_sample):
  row = d2s_matrix[r]
  sample = sample_names[r]
  out.write(sample + '\t' + '\t'.join(f'{score:.{6}f}' for score in row) + "\\n")

  """
}
