configfile:
    'code/smk/config/config.yaml'

subworkflow clean_reads:
    snakefile:
        'code/smk/clean_reads.smk'
    configfile: 'code/smk/config/config.yaml'

subworkflow assemble_genomes:
    snakefile:
        'code/smk/assemble_genomes.smk'
    configfile: 'code/smk/config/config.yaml'

subworkflow annotate_genome:
    snakefile:
        'code/smk/annotate_genome.smk'
    configfile: 'code/smk/config/config.yaml'

rule all:
    input:
        clean_reads([
            'data/processed/reads/gen_25199_1_final.fastq.gz',
            'data/processed/reads/gen_25199_2_final.fastq.gz', 
            'data/processed/read_qcs/multiqc_out/multiqc_report.html'
            ]), 
        assemble_genomes([
            'data/processed/assemblies/scaffolds_filtered.fasta',
            'data/processed/assemblies/checkm/results.tsv',
            'data/processed/assemblies/estimated_coverage.txt'
        ]),
        annotate_genome([
            'data/processed/annotation/bakta_out/DSM25199.gbff',
            'data/processed/annotation/DSM25199.sqn',
            'data/processed/annotation/gtdbtk_out/gtdbtk.bac120.summary.tsv',
            'data/processed/annotation/rfplasmid_out/prediction.csv',
            'data/processed/annotation/phispy_out/prophage_coordinates.tsv',
            'data/processed/annotation/hafez_out/hafeZ_summary_all_rois.tsv'
            ])