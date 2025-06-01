process concat_lanes {
    cpus 1
    memory '8 GB'
    container "ghcr.io/xyonetx/nextflow-scripts/star:2.7.11a"
    publishDir "${params.output_dir}/lane_merged_fastq", mode:"copy", pattern: "*.fastq.gz"

    input:
        val read_num
        tuple val(sampleID), path("reads_L?.fastq.gz")

    output:
        tuple val(sampleID), path("${outfile}")

    script:
        outfile = "${sampleID}_R${read_num}.fastq.gz"
        """
        cat reads_L* > ${outfile}
        """
}