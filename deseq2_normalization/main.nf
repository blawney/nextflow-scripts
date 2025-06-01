params.normalized_counts_dirname = 'bulk_normalized_counts'

process deseq2_norm {

    cpus 1
    memory '6 GB'
    container "ghcr.io/xyonetx/nextflow-scripts/deseq2_norm:1.40.2"

    publishDir "${output_dir}/bulk_normalized_expression", mode:"copy", pattern: "normalized_counts.*"

    input:
        path raw_counts
        val output_dir

    output:
        path "${nc_filename}"

    script:
        nc_filename = "normalized_counts.tsv"
        """
        Rscript /usr/local/bin/deseq2_normalize.R \
            ${raw_counts} \
            ${nc_filename}
        """
}


process map_ensg_to_symbol {
    tag "Run ENSG to symbol gene mapping"
    publishDir "${output_dir}/bulk_normalized_expression", mode:"copy"
    container "ghcr.io/xyonetx/tcga-pipeline/pandas"
    cpus 2
    memory '4 GB'

    input:
        path infile
        val output_dir

    output:
        path("${outfile}")

    script:
        outfile = "${infile.baseName}.symbol_remapped.tsv"
        """
        /usr/bin/python3 /opt/software/scripts/map_ensg_to_symbol.py \
            -i ${infile} \
            -m /opt/software/resources/Human_Ensembl_Gene_ID_MSigDB.v2023.1.Hs.chip \
            -o ${outfile}
        """
}


// used when invoking as a sub-workflow
workflow deseq2_norm_wf {

    take:
        raw_counts
        output_dir
    main: 
        nc_ch = deseq2_norm(raw_counts, output_dir)
        map_ensg_to_symbol(nc_ch, output_dir)

    emit:
        nc_ch
}


// used when invoking as standalone
workflow {
    raw_counts_ch = Channel.fromPath(params.raw_counts)
    deseq2_norm_wf(raw_counts_ch, params.output_dir)
}