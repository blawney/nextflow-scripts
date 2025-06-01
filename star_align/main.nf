// This script aligns FASTQ files and creates a merged count matrix

include { concat_lanes as concat_r1} from './lane_merge.nf'
include { concat_lanes as concat_r2} from './lane_merge.nf'


process star_align {

    publishDir "${output_dir}/bams", mode:"copy", pattern: "*.bam"
    publishDir "${output_dir}/star_logs", mode:"copy", pattern: "*.out"
    publishDir "${output_dir}/quantifications", mode:"copy", pattern: "*.tsv"
    container "ghcr.io/xyonetx/nextflow-scripts/star:2.7.11a"
    cpus 16
    memory '55 GB'

    input:
        path star_index_tar
        tuple val(sampleID), val(condition), path("reads_R1.fastq.gz"), path("reads_R2.fastq.gz")
        val sjdb_overhang
        val output_dir

    output:
        path("*.sorted.bam")
        path("*.quantifications.tsv")
        path("*.Log.final.out")

    script:
        """
        # Params to match those of the GDC mRNA analysis pipeline:
        # https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/

        mkdir ./starIndex
        tar -xf ${star_index_tar} -C ./starIndex

        # Only single-pass alignment-- basic DGE pipeline 
        # does not need alignment over novel splicing, etc.
        /opt/software/STAR-2.7.11a/bin/Linux_x86_64_static/STAR \
            --runThreadN 8 \
            --genomeDir ./starIndex \
            --readFilesIn reads_R1.fastq.gz reads_R2.fastq.gz \
            --readFilesCommand zcat \
            --sjdbOverhang ${sjdb_overhang} \
            --outFilterMultimapScoreRange 1 \
            --outFilterMultimapNmax 20 \
            --outFilterMismatchNmax 10 \
            --alignIntronMax 500000 \
            --alignMatesGapMax 1000000 \
            --sjdbScore 2 \
            --alignSJDBoverhangMin 1 \
            --outFilterMatchNminOverLread 0.33 \
            --outFilterScoreMinOverLread 0.33 \
            --outSAMstrandField intronMotif \
            --outSAMunmapped Within \
            --outSAMtype BAM SortedByCoordinate \
            --quantMode GeneCounts

        mv Aligned.sortedByCoord.out.bam ${sampleID}.sorted.bam
        mv ReadsPerGene.out.tab ${sampleID}.quantifications.tsv
        mv Log.final.out ${sampleID}.Log.final.out
        """
}


process multiqc {

    cpus 2
    memory '4 GB'
    container "ghcr.io/xyonetx/nextflow-scripts/star:2.7.11a"
    publishDir "${output_dir}/multiqc", mode:"copy"

    input:
        path("*.Log.final.out")
        val output_dir

    output:
        path('multiqc_report.html')
        path('multiqc_data', type: 'dir')

    script:
        """
        multiqc .
        """
}


process merge_quantifications {

    cpus 2
    memory '8 GB'
    container "ghcr.io/xyonetx/nextflow-scripts/pandas:2.1.3"
    publishDir "${output_dir}/merged_quantifications", mode:"copy"

    input:
        path count_files
        val strandedness
        val output_dir

    output:
        path 'raw_counts.tsv'

    script:
        """
        /usr/bin/python3 /opt/software/concat_star_quants.py \
            -s ${strandedness} \
            -o raw_counts.tsv \
            ${count_files}
        """
}


// used when invoking this as a sub-workflow
workflow star_align_wf {

    take:
        fastq_dir
        r1_fastq_pattern
        r2_fastq_pattern
        annotations
        star_index_path
        sjdb_overhang
        strandedness
        output_dir

    main:
        r1_fq_channel = Channel.fromFilePairs(fastq_dir + '/' + r1_fastq_pattern, size:-1)
        r2_fq_channel = Channel.fromFilePairs(fastq_dir + '/' + r2_fastq_pattern, size:-1)

        merged_r1_channel = concat_r1("1", r1_fq_channel)
        merged_r2_channel = concat_r2("2", r2_fq_channel)
        merged_fq_channel = merged_r1_channel.join(merged_r2_channel)

        ann_ch = Channel.fromPath(annotations)
            .splitCsv(header: ['sample_id', 'condition'], skip: 1, sep: '\t')
            .map{
                row -> tuple(row.sample_id, row.condition)
            }

        // since the ann_ch and fq_channel both have the sample IDs as the first
        // item, we can use the `join` operator to filter out any other FASTQs
        // that happen to be in the folder, yet aren't reflected in the annotations.
        selected_samples_ch = ann_ch.join(merged_fq_channel)

        (bams_ch, quants_ch, logs_ch) = star_align(star_index_path, selected_samples_ch, sjdb_overhang, output_dir)
        multiqc(logs_ch.collect(), output_dir)
        merged_quants_ch = merge_quantifications(quants_ch.collect(), strandedness, output_dir)

    emit:
        merged_quants_ch
}


// used when invoking directly (i.e. NOT as part of a sub-workflow)
workflow {
    star_align_wf(params.fastq_dir, 
        params.r1_fastq_pattern, 
        params.r2_fastq_pattern, 
        params.annotations, 
        params.star_index_path, 
        params.sjdb_overhang,
        params.strandedness,
        params.output_dir)
}