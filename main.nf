#!/usr/bin/env nextflow
include { validateParameters; samplesheetToList } from 'plugin/nf-schema'
include { BasecallingAndDemux }                   from './subworkflows/basecalling_demux.nf'
include { QualityCheck }                          from './subworkflows/quality_check.nf'
include { GenerateReports }                       from './subworkflows/reports.nf'
include { CollectVersions }                       from './subworkflows/versions.nf'


// validate and prepare input channels
validateParameters()

// Create a Nextflow channel with filenames and files
data = Channel
    .fromPath("${params.data_dir}/*")
    .map { file -> 
        def filename = file.getName()
        def filenameWithoutExtension = filename.replaceAll(/\.[^\.]+$/, '')  // Remove file extension
        return [filenameWithoutExtension, file]
    }
data.subscribe { element ->
    println "DEBUG: Filename without extension: ${element[0]}, Full file path: ${element[1]}"
}
fol = Channel.of('default_string')
multiqc_config = file("${workflow.projectDir}/tool_conf/multiqc_config.yaml", checkIfExists: true)

if (params.sample_data) {
  samples = channel.fromList(samplesheetToList(params.sample_data, "assets/samples_data_schema.json"))
} else {
  samples = channel.empty()
}


workflow {
  QualityCheck(data)

  CollectVersions()

  GenerateReports(
    QualityCheck.out.software_reports,
    CollectVersions.out.software_versions,
    CollectVersions.out.model_versions,
    fol,
    samples.map { it[0] }.collect().ifEmpty { [] },
    data_dir,
    multiqc_config
  )
}
