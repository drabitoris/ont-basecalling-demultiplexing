#!/usr/bin/env nextflow
include { addDefaultParamValues; pathCheck } from './lib/groovy/utils.gvy'

// load default parameters from YAML
addDefaultParamValues(params, "${workflow.projectDir}/params.default.yml")


include { BasecallingAndDemux } from './subworkflows/basecalling_demux.nf'
include { QualityCheck }        from './subworkflows/quality_check.nf'


// check and prepare input channels
fast5_dir = pathCheck(params.fast5_dir, isDirectory: true)
multiqc_config = pathCheck("${workflow.projectDir}/conf/multiqc_config.yaml")
pathCheck(params.sample_data)
sample_names = channel
  .fromPath(params.sample_data)
  .splitCsv(header: true)
  .map { row -> [row.barcode, row.sample] }


workflow {
  BasecallingAndDemux(sample_names, fast5_dir)
  QualityCheck(
    BasecallingAndDemux.out.sequences,
    BasecallingAndDemux.out.sequencing_summary,
    BasecallingAndDemux.out.barcoding_summary
  )
}