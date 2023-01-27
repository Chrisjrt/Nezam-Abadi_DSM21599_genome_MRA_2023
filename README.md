# Nezam-Abadi_DSM21599_genome_MRA_2023

## Abstract

Here, we report the 3,426,844 bp draft genome sequence of *Legionella pneumophila* subsp. *pneumophila* strain DSM 25199, a serogroup 1 strain of *L. pneumophila*. The assembly consists of 24 contigs with an N50 of 300,843 bp. 

## Setup

To replicate our analysis workflow on your own machine there are a few alteration that need to be made before running the snakemake workflow:

    - 1) Download the required databases (corresponding config variable name shown in brackets) and programs:
      - a) illumina phix sequence (phix_path)
      - b) bakta database (bakta_path)
      - c) gtdbtk database (gtdbtk_path)
      - d) table2asn program
    - 2) Modify the values for each of the databases listed in the `code/smk/config/config.yaml` file to the appropriate paths on your system.
    - 3) Download the raw reads for this project from the SRA as outlined below.
    - 4) Create a an environment for running snakemake using the `code/envs/snakemake.yaml` environment file as outlined below.

### Download the databases

#### illumina phix sequence

I use another conda environment containing the bbmap suite as the source of this file. Can be done as follows:

```
mamba env create -n bbmap -f code/envs/bbmap.yaml;
mamba activate bbmap;
which bbmap.sh;

# after running this you can take the output path 
# e.g. /data/san/data0/users/chris/Programs/mambaforge/envs/bbmap/bin/bbmap.sh
# Then modify the output path it to remove the bin/bbmap.sh part and add opt/bbmap-39.01-0/resources/phix174_ill.ref.fa.gz
# i.e. to give the path in the above example 
# /data/san/data0/users/chris/Programs/mambaforge/envs/bbmap/opt/bbmap-39.01-0/resources/phix174_ill.ref.fa.gz 
# that can then be placed in the phix_path variable in the config.yaml
```

#### bakta database

The version used here is `v4.0` (2022-08-29, 10.5281/zenodo.7025248). Which we downloaded at the time of analysis as follows:

```
mamba env create -n bakta -f code/envs/bakta.yaml;
mamba activate bakta;
bakta_db download --output <path/to/desired/place/>
```

Then update the `config.yaml` with the path to the db.

The latest version of this database may have changed by the time of analysis so the commands above may not download the exact version we used, but manual install instructions for specific DB versions hosted on Zenodo can be found on the bakta github (https://github.com/oschwengers/bakta#database-download).

#### gtdbtk database

We used GTDB release 207 and downloaded as follows:

```
wget -P <path/to/desired/place> https://data.gtdb.ecogenomic.org/releases/release207/207.0/auxillary_files/gtdbtk_r207_data.tar.gz
tar -zxvf <path/to/desired/place>/gtdbtk_r207_data.tar.gz -C <path/to/desired/place>
```

Then update the `config.yaml` with the path to the db.

#### table2asn program

The table2asn v1.26.678 from the NCBI toolkit used to generate the `.sqn` file from the annotations was downloaded from the NCBI FTP (https://ftp.ncbi.nlm.nih.gov/asn1-converters/versions/2022-06-14/by_program/table2asn/). 

The program was downloaded as follows:

```
wget -P code/programs/ https://ftp.ncbi.nlm.nih.gov/asn1-converters/versions/2022-06-14/by_program/table2asn/linux64.table2asn.gz;
gunzip code/programs/linux64.table2asn.gz;
chmod +x code/programs/linux64.table2asn.gz
```

We used the linux compatible version of this executable. If using another OS you'll need to download that OS's version and change the annotation workflow accordingly. 

### Download the raw reads

To download the raw reads and get them to be recognised by the pipeline run the following command from the main repo directory:

```
mkdir data/raw/reads/;
wget -O data/raw/reads/gen_25199_EKDN220046530-1A_HLY7KDSX5_L4_1.fq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR230/007/SRR23071207/SRR23071207_1.fastq.gz;
wget -O data/raw/reads/gen_25199_EKDN220046530-1A_HLY7KDSX5_L4_2.fq.gz ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR230/007/SRR23071207/SRR23071207_2.fastq.gz
```

### Create snakemake environment

Create our snakemake environment using the below command. Change environment name (`-n`) as desired.

```
mamba env create -n snakemake -f code/envs/snakemake.yaml
```

## Run the workflow

The command used here to run the snakemake workflow was:

```
snakemake -j <no. of threads you want to use> --use-conda
```

## Overview

```
project
|- README          # General description of contents and requirements
|
|- data            # where raw and processed data live, are not changed once created
|  |- raw/         # where raw data is kept and is the required starting point for analysis
|  |- process/     # where outputs from processing data is kept, unaltered from creation;
|
|- code/           # code used for data generation/analysis
|  |- dbs/         # where small databases are stored
|  |- programs/    # where external programs are stored that cant be installed via conda
|  |- envs/        # holds the environment files
|  |- smk/         # holds the subworkflows used by snakemake
|     |- config/   # contains the config file used by snakemake
|
|- Snakefile       # snakefile used to run the whole workflow
```

