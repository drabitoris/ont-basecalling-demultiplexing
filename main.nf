#!/usr/bin/env nextflow
include { addDefaultParamValues } from './lib/groovy/utils.gvy'

// load default parameters from YAML
addDefaultParamValues(params, "${workflow.projectDir}/params.default.yml")


include { BasecallingAndDemux } from './subworkflows/basecalling_demux.nf'
include { QualityCheck }        from './subworkflows/quality_check.nf'


// prepare input channels
fast5_dir = channel.value(file(params.fast5_dir))
sample_names = channel
  .fromPath(params.sample_data)
  .splitCsv(header: true)
  .map { row -> [row.barcode, row.sample] }


workflow {
  BasecallingAndDemux(sample_names, fast5_dir)
    | QualityCheck
}