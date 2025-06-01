params.dge_results_dirname = 'differential_expression'
params.normalized_counts_dirname = 'normalized_counts'


process deseq2_dge {

    cpus 4
    memory '12 GB'
    container "ghcr.io/xyonetx/nextflow-scripts/deseq2:1.40.2"

    publishDir "${output_dir}/${params.dge_results_dirname}/${contrast}", mode:"copy", pattern: "deseq2_results.*"
    publishDir "${output_dir}/${params.normalized_counts_dirname}/${contrast}", mode:"copy", pattern: "normalized_counts.*"

    input:
        path ann
        path raw_counts
        tuple val(base_condition), val(experimental_condition)
        val output_dir

    output:
        path "${output_dge_filename}"
        path "${nc_filename}"
        val "${contrast}"

    script:
        def output_dge_filename_template = "deseq2_results.%s.tsv"
        def nc_filename_template = "normalized_counts.%s.tsv"
        def contrast_template = "%s_versus_%s"
        contrast = String.format(contrast_template, experimental_condition, base_condition)
        output_dge_filename = String.format(output_dge_filename_template, contrast)
        nc_filename = String.format(nc_filename_template, contrast)
        """
        /opt/software/deseq2_env/bin/Rscript /opt/software/scripts/deseq2.R \
            ${raw_counts} \
            ${ann} \
            ${base_condition} \
            ${experimental_condition} \
            ${output_dge_filename} \
            ${nc_filename}
        """
}


process map_ensg_to_symbol {
    tag "Run ENSG to symbol gene mapping"
    publishDir "${output_dir}/${output_location}/${contrast}", mode:"copy"
    container "ghcr.io/xyonetx/tcga-pipeline/pandas"
    cpus 2
    memory '4 GB'

    input:
        tuple path(infile), val(output_location), val(contrast)
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
workflow deseq2_wf {

    take:
        raw_counts
        annotations
        contrasts
        output_dir
    main: 
        ann_ch = Channel.fromPath(annotations).collect()
        contrast_ch = Channel.fromPath(contrasts)
            .splitCsv(header: ['base_condition', 'experimental_condition'], skip: 1, sep: '\t')
            .map{
                row -> tuple(row.base_condition, row.experimental_condition)
            }

        (dge_ch, nc_ch, contrast_ch) = deseq2_dge(ann_ch, raw_counts, contrast_ch, output_dir)

        // since you cannot re-use processes like functions, the next few lines
        // create a single channel which we pass to the `map_ensg_to_symbol` process.
        dge_dir_ch = Channel.value(params.dge_results_dirname)
        nc_dir_ch = Channel.value(params.normalized_counts_dirname)

        // effectively copies the directory string multiple times to match the length
        // of the dge_ch (and nc_ch). 
        a_ch = dge_ch.combine(dge_dir_ch)
        b_ch = nc_ch.combine(nc_dir_ch)

        // tacks on the contrast string
        remap_ch1 = a_ch.merge(contrast_ch)
        remap_ch2 = b_ch.merge(contrast_ch)

        // concatenate so we have single channel
        remap_ch = remap_ch1.concat(remap_ch2)

        // finally, pass that channel to the process. The first
        // argument is a tuple of a path, a directory name, and the contrast ID
        map_ensg_to_symbol(remap_ch, output_dir)

    emit:
        dge_ch
}


// used when invoking as standalone
workflow {
    raw_counts_ch = Channel.fromPath(params.raw_counts)
    deseq2_wf(raw_counts_ch, params.annotations, params.contrasts, params.output_dir)
}