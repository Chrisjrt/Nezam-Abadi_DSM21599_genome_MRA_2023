#############    Make all directories    ####################

rule make_folders:
    run:
        os.makedirs('data/processed/assemblies/')

#############################################################

############# Assemble per sample via spades ################

rule assemble_each_sample_spades:
    input:
        r1 = 'data/processed/reads/gen_25199_1_final.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_final.fastq.gz'
    output:
        'data/processed/assemblies/spades_gen_25199/scaffolds.fasta'
    params:
        'data/processed/assemblies/spades_gen_25199/'
    conda:
        '../envs/spades.yaml'
    threads:
        20
    shell:
        '''
        spades.py --meta -1 {input.r1} -2 {input.r2} -t {threads} -o {params}
        '''

#############################################################

########### Remove small contigs from assembly ##############

rule remove_small_contigs:
    input:
        'data/processed/assemblies/spades_gen_25199/scaffolds.fasta'
    output:
        'data/processed/assemblies/scaffolds_filtered.fasta'
    params:
        'data/processed/assemblies/'
    conda:
        '../envs/bbmap.yaml'
    shell:
        '''
        reformat.sh in={input} out={output} minlength=500
        '''

#############################################################

########### Check assembly quality via checkM ###############

rule run_checkm:
    input:
        'data/processed/assemblies/scaffolds_filtered.fasta'
    output:
        bins = 'data/processed/assemblies/checkm/storage/bin_stats_ext.tsv',
        tsv = 'data/processed/assemblies/checkm/results.tsv'
    params:
        in_dir = 'data/processed/assemblies/',
        out_dir = 'data/processed/assemblies/checkm'
    conda:
        '../envs/checkm.yaml'
    threads:
        20
    shell:
        '''
        checkm lineage_wf --tab_table -t {threads} -x fasta {params.in_dir} {params.out_dir} -f {output.tsv}    
        '''

#############################################################

################ estimate genome coverage ###################

rule estimated_coverage:
    input:
        r1 = 'data/processed/reads/gen_25199_1_final.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_final.fastq.gz',
        assembly = 'data/processed/assemblies/scaffolds_filtered.fasta'
    output:
        'data/processed/assemblies/estimated_coverage.txt'
    conda:
        '../envs/bbmap.yaml'
    threads:
        20
    shell:
        '''
        READCOUNT=$(reformat.sh in1={input.r1} in2={input.r2} 2>&1 >/dev/null | grep Output | awk '{{print $5}}');
        ASSEMBLYLENGTH=$(reformat.sh in={input.assembly} 2>&1 >/dev/null | grep Output | awk '{{print $5}}');
        echo "Estimated genome coverage = " $(( $READCOUNT / $ASSEMBLYLENGTH )) > {output} 
        '''

#############################################################
