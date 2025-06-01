# nextflow-scripts

This repository contains various nextflow workflows which can be used as standalone processes (e.g. the `deseq2` folder can run differential expression with DESeq2) or by invoking several in a "superworkflow" (e.g. `rnaseq_dge_workflow`).

## Orientation

Each subdirectory contains nextflow scripts, parameter templates, and other files for running the nextflow process. Generally, you edit the `params.json.tmpl` and `nextflow.config.tmpl` to fill-in parameters for your job, then run the process by executing:

```shell
nextflow run <script.nf> -params-file <JSON param file> -c nextflow.config
```

See comments in the workflow-specific directories which describe the parameters contained in the template parameter JSON file.

Note that some workflows are capable of running on a local machine while others, such as alignment with STAR, require greater machine resources and are expected to be run on a cloud provider like AWS. While nothing about the scripts is specific to hardware or specific cloud providers, we have only used this on AWS via AWS Batch and S3 for storage.

**docker/: (top level)**

This directory contains general `Dockerfile`s required to execute the workflows. They will generally be named like `Dockerfile.<foo>` where `<foo>` is some descriptor. Note that the names maybe referenced in the Github Actions build scripts, so be careful if you rename.

Also note that any `Dockerfile` manifests in this folder should be relatively general in nature and not include custom process-specific scripts, files, etc. If you require this (such as a script to post-process an output file produced by DESeq2), you can add process-specific `Dockerfile`s in the appropriate subdirectory for your workflow/process. Since most tools have some portion requiring custom processing, you will find most workflows have a workflow-specific `docker/` folder.

**star_create_index/:**

This directory contains nextflow scripts and files for creating the STAR index.

**star_align/:**

This directory contains nextflow scripts and files for alignment using the STAR aligner.

**deseq2/:**

This directory contains nextflow scripts and files for running count-based differential expression using DESeq2.

**deseq2_normalization/:**

This directory contains nextflow scripts and files for creating a normalized count matrix using DESeq2's "median-based" method.

**gsea/:**

This directory contains nextflow scripts and files for running Gene Set Enrichment Analysis (GSEA).

**rnaseq_dge_workflow/:**

This directory contains nextflow scripts and files which orchestrate a typical pipeline for differential expression analysis including alignment, differential expression, and pathway enrichment with GSEA.