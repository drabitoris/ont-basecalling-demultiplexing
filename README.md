# ONT Basecalling / Demux Pipeline

Small pipeline to perform basecalling and demultiplexing (optional) of ONT data, collect QC metrics and generate a MultiQC report.
It uses Guppy for basecalling and demultiplexing.

## Requirements
- [Nextflow](https://www.nextflow.io/) (>= 22.04)
- [Apptainer](https://apptainer.org/) / Singularity
- Guppy GPU (>= 6.4.6). Not distributed with the pipeline, hast to be downloaded from [ONT community](https://community.nanoporetech.com/)

## Usage
- Clone this repository
- If you want to demultiplex: create a `samples.csv` file with at least the `barcode` and `sample` columns. The `barcode` column should contain the barcode used for demultiplexing (with the leading zero, e.g. `barcode01`), and the `sample` column should contain the sample name (this name with be used on the report and as name for FASTQ file).
- Make a copy of `params.default.yml` and modify it according to your needs. Remember to point `sample_data` parameter to the file created at the previous step.
- Run the pipeline passing your params file to `-params-file` option:
```
nextflow run ont-basecalling-demultiplexing/ -params-file my_params.yml
```

## Considerations
- The pipeline is designed to run on a SLURM cluster, but should run on local machines as well.
- Basecalling and demultiplexing are performed on separated steps to allow for a better control of the resources used by each process, and to prevent a whole basecalling redo in case of a failure during demultiplexing, wrong kit specified, etc.
- The basecalling process uses GPU, so make sure to have one available. The SLURM job will be submitted with `--gres=gpu:X` option (with `X` as 1 by default).
- Demultiplexing doesn't use GPU.