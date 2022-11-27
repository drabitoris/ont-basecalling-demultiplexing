workflow BasecallingAndDemux {
  take:
    sample_names  // channel [barcode, sample]
    fast5_dir     // directory containing FAST5 files

  main:
    basecalling(fast5_dir)

    basecalling.out.fastq_pass
      | mix(basecalling.out.fastq_fail)
      | map { [it.simpleName, it] }
      | set { sequences_to_merge }

    if (params.skip_demultiplexing) {
      mergeSequences(sequences_to_merge)
    } else {
      demultiplexing(basecalling.out.fastq_pass)

      demultiplexing.out.classified
        | flatMap { it.collect { x -> [x.simpleName, x] } }
        | join(sample_names)
        | map { [it[2], it[1]] }
        | mix(demultiplexing.out.unclassified.map { ['unclassified', it] })
        | mix(sequences_to_merge)
        | mergeSequences
    }

  emit:
    sequences = mergeSequences.out
    sequencing_summary = basecalling.out.sequencing_summary
    barcoding_summary = params.skip_demultiplexing ? null : demultiplexing.out.barcoding_summary
}


process basecalling {
  label 'guppy'
  publishDir "${params.output_dir}/guppy_info/", \
    pattern: 'basecalled/sequencing_summary.txt', \
    saveAs: { 'sequencing_summary.txt' }, \
    mode: 'copy'
  clusterOptions = "--gres=gpu:${params.guppy_basecalling_gpus}"
  cpus params.guppy_basecalling_cpus
  
  input:
  path(fast5_dir)

  output:
  path('basecalled/pass'), emit: fastq_pass
  path('basecalled/fail'), emit: fastq_fail
  path('basecalled/sequencing_summary.txt'), emit: sequencing_summary

  script:
  """
  guppy_basecaller \
    --input_path ${fast5_dir} \
    --save_path basecalled \
    --config ${params.guppy_basecalling_config} \
    --recursive \
    --device 'cuda:all' \
    --num_callers ${task.cpus} \
    ${params.guppy_basecalling_extra_config}
  """
}


process demultiplexing {
  label 'guppy'
  publishDir "${params.output_dir}/guppy_info/", \
    pattern: 'demultiplexed/barcoding_summary.txt', \
    saveAs: { 'barcoding_summary.txt' }, \
    mode: 'copy'
  cpus params.guppy_barcoding_cpus

  input:
  path(fastq_dir)

  output:
  path('demultiplexed/barcode*'), emit: classified
  path('demultiplexed/unclassified'), emit: unclassified
  path('demultiplexed/barcoding_summary.txt'), emit: barcoding_summary

  script:
  both_ends = params.guppy_barcoding_both_ends ? '--require_barcodes_both_ends' : ''
  """
  guppy_barcoder \
    --input_path ${fastq_dir} \
    --save_path demultiplexed/ \
    --recursive \
    --barcode_kits "${params.guppy_barcoding_kits}" \
    ${both_ends} \
    --detect_adapter \
    --detect_barcodes \
    --worker_threads ${task.cpus} \
    ${params.guppy_barcoding_extra_config}
  """
}


process mergeSequences {
  label 'linux'
  tag "${name}"
  publishDir "${params.output_dir}/fastq/", \
    pattern: '^(pass|fail|unclassified)', \
    mode: 'copy'

  input:
  tuple val(name), path(fastq_dir)

  output:
  tuple val(name), path("${name}.fastq")

  script:
  """
  cat ${fastq_dir}/*.fastq > ${name}.fastq
  """
}