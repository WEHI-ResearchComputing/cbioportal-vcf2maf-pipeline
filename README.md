# cbioportal-vcf2maf-pipeline
A pipeline to convert VCF files with somatic mutations into a single MAF for import into cBioPortal.

The [Genome Nexus annotatino tools repo](https://github.com/genome-nexus/annotation-tools) has a pipeline script,
but doesn't seem to work that well with our data (the annotator fails annotating more mutations than it should).

The pipeline script follows the steps:

1. converts the vcfs to mafs with `annotation-tools/vcf2maf.py`
2. merges the mafs into a single one with `annotation-tools/merge_mafs.py`
3. reduces the merged maf to a minimal maf using `cut` (grabbing columns as per [instructions on cBioPortal documentation](https://docs.cbioportal.org/file-formats/#minimal-maf-file-format))
4. annotate the resultant minimal maf with the genome nexus annotation pipeline to obtain the final maf.

## Setup

Prerequisites: Python 3.6, Maven, Java

### Get the repo

```bash
git clone --recursive https://github.com/WEHI-ResearchComputing/cbioportal-vcf2maf-pipeline.git```
cd cbioportal-vcf2maf-pipeline
```

### Install Python prerequisites

```bash
pip install -r annotation-tools/requirements.txt
```

### Build pipeline jar

Copy and modify the example config files.

```bash
cd genome-nexus-annotation-pipeline
cp annotationPipeline/src/main/resources/application.properties.EXAMPLE annotationPipeline/src/main/resources/application.properties
cp annotationPipeline/src/main/resources/log4j.properties.EXAMPLE annotationPipeline/src/main/resources/log4j.properties
```

You will want to edit the `log4j.properties` file to control where logs are written (edit the `log4j.appender.a.File` field).

If you wish to use the Genome Nexus GRCh38 (apparently experimental) database, change the
`genomenexus.base` field from `https://www.genomenexus.org` to `https://grch38.genomenexus.org`.

Build the jar file

```bash
mvn clean install
```

This will create the jar file in `genome-nexus-annotation-pipeline/annotationPipeline`

## Usage

```output
./pipeline.sh -i=<dir> -o=<dir> -p=<dir> -j=<jar> -c=center [-t=<dir>] [-e=error.log]
        -i | --input-directory               input data directory for processing somatic mutation data files [REQUIRED]
        -o | --output-directory              output directory to write processed and annotated MAF to [REQUIRED]
        -p | --annotation-scripts-home       path to the annotation suite scripts directory [REQUIRED]
        -j | --annotation-pipeline-jar       path to the annotation pipeline jar [REQUIRED]
        -c | --center-name                   center name to be used in Center MAF field [REQUIRED]
        -c | --isoform-override              Isoform Overrides - mskcc or uniprot [REQUIRED]
        -t | --intermediate-files-directory  path to store intermediary files. Default is directory created with mktemp
        -e | --annotation-error-log          path to store annotation pipeline error log. Default is ./error.log
```