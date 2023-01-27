#############    Make all directories    ####################

rule make_folders:
    run:
        os.makedirs('data/processed/annotation/')

#############################################################

####################### Annotate genome #####################

rule run_bakta:
    input:
        'data/processed/assemblies/scaffolds_filtered.fasta'
    output:
        'data/processed/annotation/bakta_out/DSM25199.gbff',
        'data/processed/annotation/bakta_out/DSM25199.gff3'
        'data/processed/annotation/bakta_out/DSM25199.fna'
    params:
        bakta_db = config['bakta_path'],
        out_dir = 'data/processed/annotation/bakta_out/'
    conda:
        '../envs/bakta.yaml'
    threads:
        20
    shell:
        '''
        bakta --threads {threads} --db {params.bakta_db} -v --genus Legionella --species "pneumophila subsp. pneumophila" --strain "DSM 25199" --compliant --locus-tag PGH39 --prefix DSM25199 --output {params.out_dir} {input}
        '''

rule fix_bakta_gff:
    input:
        'data/processed/annotation/bakta_out/DSM25199.gff3'
    output:
        'data/processed/annotation/bakta_out/DSM25199_fixed.gff3'
    shell:
        '''
        sed 's/Name=gap (100 bp);product=gap (100 bp)/Name=gap (100 bp);product=gap (100 bp);estimated_length=unknown/g' {input} > {output}
        '''

#############################################################

############# convert annotation to sqn file ################

rule run_table2asn:
    input:
        template = 'data/raw/genbank_submission_template/template.sbt',
        assembly = 'data/processed/annotation/bakta_out/DSM25199.fna',
        gff = 'data/processed/annotation/bakta_out/DSM25199_fixed.gff3'
    output:
        'data/processed/annotation/DSM25199.sqn'
    shell:
        '''
        code/programs/linux64.table2asn -M n -J -c w -t {input.template} -V vbt -l paired-ends -i {input.assembly} -f {input.gff} -o {output} -Z -gaps-min 10 -gaps-unknown 100
        '''

#############################################################

################ check for prophages ########################

rule run_phispy:
    input:
        'data/processed/annotation/bakta_out/DSM25199.gbff'
    output:
        'data/processed/annotation/phispy_out/prophage_coordinates.tsv'
    params:
        'data/processed/annotation/phispy_out/'
    conda:
        '../envs/phispy.yaml'
    threads:
        20
    shell:
        '''
        phispy -o {params} --threads {threads} {input}
        '''

rule get_hafez_db:
    output:
        'code/dbs/hafez_db/phrogs_table_almostfinal_plusGO_wNA_utf8.tsv'
    conda:
        '../envs/hafez.yaml'
    shell:
        '''
        hafeZ.py -G code/dbs/hafez_db/ -T phrogs
        '''

rule run_hafez:
    input:
        fasta = 'data/processed/annotation/bakta_out/DSM25199.fna',
        r1 = 'data/processed/reads/gen_25199_1_final.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_final.fastq.gz',
        db = 'code/dbs/hafez_db/phrogs_table_almostfinal_plusGO_wNA_utf8.tsv'
    output:
        'data/processed/annotation/hafez_out/hafeZ_summary_all_rois.tsv'
    params:
        out_folder = 'data/processed/annotation/hafez_out/',
        db_path = 'code/dbs/hafez_db/'
    conda:
        '../envs/hafez.yaml'
    threads:
        20
    shell:
        '''
        hafeZ.py -f {input.fasta} -r1 {input.r1} -r2 {input.r2} -o {params.out_folder} -t {threads} -D {params.db_path} -T phrogs -Z
        '''

#############################################################

################### Check for plasmids ######################

# exit 0 is used in the initialze_rfplasmid rule as for some reason even when the initialize command works perfectly it exist with a non-0 code... if it doesnt work the output wont be found so will give an error anyway

rule initialise_rfplasmid:
    output:
        temp('data/plasmiddb_cge.dmnd')
    conda:
        '../envs/rfplasmid.yaml'
    shell:
        '''
        (rfplasmid --initialize; export RFPLASMID=$(which rfplasmid); echo ${{RFPLASMID%/*/*}}/lib/python3.7/site-packages/RFPlasmid/plasmiddb_cge.dmnd; cp ${{RFPLASMID%/*/*}}/lib/python3.7/site-packages/RFPlasmid/plasmiddb_cge.dmnd data/) || exit 0;
        '''

rule run_rfplasmid:
    input:
        fasta = 'data/processed/annotation/bakta_out/DSM25199.fna',
        initialised = 'data/plasmiddb_cge.dmnd'
    output:
        'data/processed/annotation/rfplasmid_out/prediction.csv'
    params:
        output_folder = 'data/processed/annotation/rfplasmid_out'
    conda:
        '../envs/rfplasmid.yaml'
    threads:
        20
    shell:
        '''
        cp {input.fasta} DSM25199.fasta;
        rfplasmid --species Generic --jelly --threads {threads} --out {params.output_folder} --input .;
        rm DSM25199.fasta;
        '''

##############################################################

#################### check taxa ##############################

rule run_gtdbtk:
    input:
        genomes = 'data/processed/annotation/bakta_out/DSM25199.fna'
    output:
        'data/processed/annotation/gtdbtk_out/gtdbtk.bac120.summary.tsv'
    params:
        db = config['gtdbtk_path'],
        genome_dir = 'data/processed/annotation/bakta_out/',
        out_dir = 'data/processed/annotation/gtdbtk_out/'
    threads:
        20
    conda:
        '../envs/gtdbtk.yaml'
    shell: 
        '''
        export GTDBTK_DATA_PATH={params.db};
        gtdbtk classify_wf --genome_dir {params.genome_dir} --out_dir {params.out_dir} --cpus {threads} --scratch_dir {params.out_dir} --extension fna
        '''

##############################################################