import glob

def get_read_1():
    return glob.glob('data/raw/reads/*_1.fq.gz')

def get_read_2():
    return glob.glob('data/raw/reads/*_2.fq.gz')

#############    Make all directories    ####################

rule make_folders:
    run:
        os.makedirs('data/processed/read_qcs/initial/')
        os.makedirs('data/processed/read_qcs/trimmed_reads')
        os.makedirs('data/processed/read_qcs/trimmed_filtered/')
        os.makedirs('data/processed/read_qcs/phix_removed/')
        os.makedirs('data/processed/reads/')

#############################################################

############ create temporary read file for name ############

rule make_temp_file:
    input:
        r1 = get_read_1(),
        r2 = get_read_2()
    output:
        r1 = temp('data/processed/reads/gen_25199_1.fq.gz'),
        r2 = temp('data/processed/reads/gen_25199_2.fq.gz')
    shell:
        '''
        cp {input.r1} {output.r1}
        cp {input.r2} {output.r2}
        '''

#############################################################

############# get initial fastqc reports ####################

rule get_initial_fastqc:
    input:
        r1 = 'data/processed/reads/gen_25199_1.fq.gz',
        r2 = 'data/processed/reads/gen_25199_2.fq.gz',
    output:
        'data/processed/read_qcs/initial/gen_25199_1_fastqc.html',
        'data/processed/read_qcs/initial/gen_25199_2_fastqc.html'
    params:
        'data/processed/read_qcs/initial/'
    conda:
        '../envs/fastqc.yaml'
    threads:
        5
    shell:
        '''
        fastqc --extract -t {threads} -o {params} {input.r1} {input.r2}
        '''

#############################################################

########### trim/filter reads for quality ###################

rule trim_and_quality_filter_reads:
    input:
        r1 = 'data/processed/reads/gen_25199_1.fq.gz',
        r2 = 'data/processed/reads/gen_25199_2.fq.gz',
    output:
        r1 = temp('data/processed/reads/gen_25199_1_trimmed.fastq.gz'),
        r2 = temp('data/processed/reads/gen_25199_2_trimmed.fastq.gz'),
        json = 'data/processed/read_qcs/trimmed_reads/gen_25199_trimmed_fastp.json',
        html = 'data/processed/read_qcs/trimmed_reads/gen_25199_trimmed_fastp.html'
    threads:
        5
    conda:
        '../envs/fastp.yaml'
    shell:
        '''
        fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} -w {threads} -j {output.json} -h {output.html} --length_required 60 --detect_adapter_for_pe --cut_front --cut_tail --cut_window_size 4 --cut_mean_quality 20 --trim_front1 10
        '''

#############################################################

############# get trimmed fastqc reports ####################

rule get_trimmed_fastqc:
    input:
        r1 = 'data/processed/reads/gen_25199_1_trimmed.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_trimmed.fastq.gz'
    output:
        'data/processed/read_qcs/trimmed_reads/gen_25199_1_trimmed_fastqc.html',
        'data/processed/read_qcs/trimmed_reads/gen_25199_2_trimmed_fastqc.html'
    params:
        'data/processed/read_qcs/trimmed_reads'
    conda:
        '../envs/fastqc.yaml'
    threads:
        5
    shell:
        '''
        fastqc --extract -t {threads} -o {params} {input.r1} {input.r2}
        '''

#############################################################

############### remove phix174 reads ########################

rule remove_phix:
    input:
        r1 = 'data/processed/reads/gen_25199_1_trimmed.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_trimmed.fastq.gz'
    output:
        r1 = 'data/processed/reads/gen_25199_1_final.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_final.fastq.gz'
    params:
        phix = config['phix_path']
    conda:
        '../envs/bbmap.yaml'
    threads:
        20
    shell:
        '''
        bbduk.sh in={input.r1} in2={input.r2} out={output.r1} out2={output.r2} ref={params.phix} k=31 hdist=1
        '''

#############################################################

########## get fastqc repors for phix removed reads #########

rule get_phix_removed_whole_metagenome_fastqc:
    input:
        r1 = 'data/processed/reads/gen_25199_1_final.fastq.gz',
        r2 = 'data/processed/reads/gen_25199_2_final.fastq.gz'
    output:
        r1 = 'data/processed/read_qcs/phix_removal/gen_25199_1_final_fastqc.html',
        r2 = 'data/processed/read_qcs/phix_removal/gen_25199_2_final_fastqc.html'
    params:
        'data/processed/read_qcs/phix_removal/'
    conda:
        '../envs/fastqc.yaml'
    threads:
        5
    shell:
        '''
        fastqc --extract -t {threads} -o {params} {input.r1} {input.r2}
        '''

#############################################################

############### get multifastqc reports  ####################

rule get_final_multiqc:
    input:
        'data/processed/read_qcs/initial/gen_25199_1_fastqc.html',
        'data/processed/read_qcs/initial/gen_25199_2_fastqc.html',
        'data/processed/read_qcs/trimmed_reads/gen_25199_1_trimmed_fastqc.html',
        'data/processed/read_qcs/trimmed_reads/gen_25199_2_trimmed_fastqc.html',
        'data/processed/read_qcs/phix_removal/gen_25199_1_final_fastqc.html',
        'data/processed/read_qcs/phix_removal/gen_25199_2_final_fastqc.html',
        'data/processed/reads/gen_25199_1_trimmed.fastq.gz',
        'data/processed/reads/gen_25199_2_trimmed.fastq.gz'
    output:
        'data/processed/read_qcs/multiqc_out/multiqc_report.html'
    params:
        in_dir = 'data/processed/',
        out_dir = 'data/processed/read_qcs/multiqc_out/'
    conda:
        '../envs/multiqc.yaml'
    shell:
        '''
        multiqc --outdir {params.out_dir} {params.in_dir}
        '''

#############################################################
