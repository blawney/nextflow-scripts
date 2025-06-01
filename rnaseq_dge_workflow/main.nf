include { star_align_wf } from '../star_align/main.nf'
include { deseq2_wf } from '../deseq2/main.nf'
include { deseq2_norm_wf } from '../deseq2_normalization/main.nf'
include { gsea_wf } from '../gsea/main.nf'

workflow {

    // align the samples and grab the merged raw counts
    merged_quants_ch = star_align_wf(
        params.fastq_dir, 
        params.r1_fastq_pattern, 
        params.r2_fastq_pattern, 
        params.annotations, 
        params.star_index_path,
        params.sjdb_overhang,
        params.strandedness,
        params.output_dir
    ).collect()

    // perform differential expression and grab the output tables of 
    // differentially expressed genes
    dge_ch = deseq2_wf(
        merged_quants_ch,
        params.annotations,
        params.contrasts,
        params.output_dir
    )

    // GSEA will need normalized quants for its classic algo, so we create a normalized
    // expression matrix for all the samples in the raw count matrix
    nc_ch = deseq2_norm_wf(merged_quants_ch, params.output_dir)

    gsea_wf(dge_ch, nc_ch, params.annotations, params.contrasts, params.output_dir)
}