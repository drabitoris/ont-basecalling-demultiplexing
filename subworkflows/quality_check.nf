workflow QualityCheck {
  take:
    fastq_files         // channel [name, fastq]
    sequencing_summary  // sequencing summary file
    barcoding_summary   // barcoding summary file

  main:
    pycoQC(sequencing_summary, barcoding_summary)

    fastq_files
      | (fastQC & nanoPlot)
      | mix
      | map { it[1] }
      | collect
      | multiQC
}


process fastQC {
  label 'fastqc'
  tag "${name}"
  publishDir "${params.output_dir}/qc/fastqc", mode: 'copy'
  cpus { 8 * task.attempt }
  memory { 16.GB * task.attempt }
  time '30m'
  errorStrategy 'retry'
  maxRetries 3

  input:
  tuple val(name), path(fastq)

  output:
  tuple val(name), path("fastqc_${name}")

  script:
  """
  mkdir fastqc_${name}
  fastqc ${fastq} -o fastqc_${name} -t ${task.cpus}
  """
}


process nanoPlot {
  label 'nanoplot'
  tag "${name}"
  publishDir "${params.output_dir}/qc/nanoplot", mode: 'copy'
  cpus 4

  input:
  tuple val(name), path(fastq)

  output:
  tuple val(name), path("nanoplot_${name}")

  script:
  """
  NanoPlot \
    --fastq ${fastq} \
    --outdir nanoplot_${name} \
    --prefix ${name}_ \
    --threads ${task.cpus}
  """
}


process pycoQC {
  label 'pycoqc'
  publishDir "${params.output_dir}/qc/pycoqc", mode: 'copy'

  input:
  path(sequencing_summary)
  path(barcoding_summary)
  
  output:
  path("pycoQC_report.html")
  
  script:
  barcoding_opt = barcoding_summary.name != 'NO_FILE'
    ? "-b ${barcoding_summary}"
    : ''
  """
  pycoQC \
    -f ${sequencing_summary} \
    ${barcoding_opt} \
    -o pycoQC_report.html
  """
}


process multiQC {
  label 'multiqc'
  publishDir "${params.output_dir}/qc/multiqc", mode: 'copy'
  
  input:
  path(fastqc_reports)

  output:
  tuple path('multiqc_data'), path('multiqc_report.html')

  script:
  """
  cp ${workflow.projectDir}/conf/multiqc_config.yaml .
  multiqc .
  """
}