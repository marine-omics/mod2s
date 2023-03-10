nextflow.enable.dsl=2

include { bwa_index as index_target; bwa_index as index_background } from './modules/bwa.nf'
include { get_mapped_reads; concat_reads; get_mapped_reads_notbg } from './modules/samtools.nf'
include { d2s_pair; gather_d2s_matrix } from './modules/d2ssect.nf'
include { jellyfish_count } from './modules/jellyfish.nf'
include { count_reads } from './modules/shell.nf'
include { subsample_reads } from './modules/seqtk.nf'

params.target_ref=null
params.background_ref=null
params.outdir=null

// After discarding samples with <n_reads, a random subsample of n_reads will be used
// If n_reads is not set the worflow will stop after calculating read depths 
// to allow the user to choose a threshold 
//
params.n_reads=null 

if(!params.outdir){
  log.error "No outdir provided. Provide one with --outdir myoutdir"
  exit 1
}

workflow d2s {
  take:
    reads

  main:
    ch_jf = reads | jellyfish_count

    ch_d2s_inputs = reads.join(ch_jf)

    ch_pairs = ch_d2s_inputs.combine(ch_d2s_inputs).map {
      m1,fq1,jf1,m2,fq2,jf2 -> {
        v=null
        if (m1.i<m2.i){
          v=[m1,fq1,jf1,m2,fq2,jf2]
        } 
        v
      }
    }

    pairs = d2s_pair(ch_pairs) | collect 
    gather_d2s_matrix(pairs) 
}

workflow {
  ch_input_sample = extract_csv(file(params.samples, checkIfExists: true))

  if (params.target_ref){
    target_ref_fasta = Channel.fromPath(file(params.target_ref, checkIfExists:true)) | collect
    target_ref_index = index_target(target_ref_fasta) | collect
  }

  if (params.background_ref){
    background_ref_fasta = Channel.fromPath(file(params.background_ref, checkIfExists:true)) | collect
    background_ref_index = index_background(background_ref_fasta)| collect
  }

// There are three possible ref configs
// 1. No ref 
// 2. target_ref only
// 3. Both target_ref and background_ref
  if (!params.target_ref && !params.background_ref){

    ch_reads = ch_input_sample | concat_reads

  } else if (params.target_ref && !params.background_ref){

    ch_reads = get_mapped_reads(ch_input_sample,target_ref_fasta,target_ref_index)

  } else if (params.target_ref && params.background_ref){

    ch_reads = get_mapped_reads_notbg(ch_input_sample,target_ref_fasta,target_ref_index,background_ref_fasta,background_ref_index)    

  } else {
    log.error "background_ref provided but not target_ref. When providing a single reference it must be labelled refa"
  }

  if (!params.n_reads){
    log.error "n_reads not provided. \n When this run is complete use read counts in <outdir>/sample_counts.txt to choose an appropriate value and then rerun with --n_reads X -resume where X is your chosen read threshold"    

    ch_counts = ch_reads.map {
         count = file(it[1]).countFastq()
         "${it[0].sample},${count}"
     }
     ch_counts.view()

    ch_counts.collectFile(name:'sample_counts.txt', newLine: true, storeDir: params.outdir)
    .subscribe {
        println "Entries are saved to file: $it"
    }

  } else {

    ch_counted_reads = ch_reads.map {
      count = file(it[1]).countFastq()
      it[0]['count'] = count
      it
    }

    i=1
    ch_filtered_samples = ch_counted_reads.filter {
      it[0].count >= params.n_reads
    }.map {
      it[0].i = i
      i=i+1
      it
    }

    ch_filtered_samples.view()

    ch_sampled_reads = subsample_reads(ch_filtered_samples,params.n_reads)

    d2s(ch_sampled_reads)    
  }


}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def resolve_path(pathstring){
  if(pathstring =~ /^\//){
    pathstring
  } else {
    "${params.base_path}/${pathstring}"
  }
}

def extract_csv(csv_file) {
    i=1
    Channel.from(csv_file).splitCsv(header: true)
    .map{ row -> 
      def meta = [:]
      meta.sample = row.sample

      def fastq_1     = file(resolve_path(row.fastq_1), checkIfExists: true)
      def fastq_2     = row.fastq_2 ? file(resolve_path(row.fastq_2), checkIfExists: true) : null
      meta.single_end = row.fastq_2 ? false : true
      meta.i = i
      i=i+1
      if (!meta.single_end){
        reads = [fastq_1,fastq_2]
      } else {
        reads = [fastq_1]
      }

      reads.removeAll([null])

      [meta,reads]
    }
}
