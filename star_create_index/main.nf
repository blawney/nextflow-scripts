// This script simply creates the STAR index.
// Since it is generally a process we only have to do once,
// we don't expose it as a potential sub-workflow.

process create_index {
    tag "idx"
    publishDir "${params.output_dir}/${params.genomeId}", mode:"copy"
    container "ghcr.io/xyonetx/nextflow-scripts/star:2.7.11a"
    cpus 8
    memory '64 GB'

    input:
        path fasta 
        path gtf 

    output:
        path "${params.genomeId}.sjdb${params.sjdb_overhang}.tar"

    script:
        unzipped_fasta = fasta.getBaseName()
        """
        mkdir starIndex
        gunzip -f ${fasta}
        /opt/software/STAR-2.7.11a/bin/Linux_x86_64_static/STAR \
            --runMode genomeGenerate \
            --runThreadN 8 \
            --genomeDir starIndex \
            --genomeFastaFiles ${unzipped_fasta} \
            --sjdbGTFfile ${gtf} \
            --sjdbOverhang ${params.sjdb_overhang} \
            --limitGenomeGenerateRAM=62000000000
        tar -cf ${params.genomeId}.sjdb${params.sjdb_overhang}.tar -C starIndex .
        """
}

workflow {    
    fasta_ch = Channel.fromPath(params.fasta)
    gtf_ch = Channel.fromPath(params.gtf)
    create_index(fasta_ch, gtf_ch)
}
