# LGT-pangenome

This file describes the in-house pipeline used for de novo identification of lateral gene transfers in multiple reference genomes from the same species (pan-genome). It includes primarily bash scripts to be run in ShARC HPC from University of Sheffield (https://docs.hpc.shef.ac.uk/en/latest/sharc/index.html), and nested scripts in perl, python and R that are called by the bash scripts.

Most of the bash scripts need to be inspected and modified according to the user's folder structure, target pan-genome and genomes to be included in the analyses. These files, directories and parameters are defined **at the beginning** of the scripts, so the user can easily generate their own custom versions for each pan-genome.

## Preparing the genomes

**Script: PG_00_PrepareCDS.sh**

This script prepares the raw input files, fasta files containing the coding sequences for all gene models in the reference genomes from the target pan-genome. The script eliminates problematic characters and erroneous gene models, and adds a genome identifier to each coding sequence ID.

1. Create a directory `CDS` and one subdirectory `GenomeID` for each of the genomes to include in the analysis. **GenomeID has to be 'Genus_species_00n', e.g. 'Zea_mays_001' for the first Zea mays genome**
2. Download the fasta files into the directory. Whenever possible, include only primary transcripts.
3. Name the files as {GenomeID}.cds.fa.
4. Create/copy a 'control files' directory `ctrl_files`.
5. Run script `PG_00_PrepareCDS.sh`.

## First BLAST filter

**Script: PG_01a_initial_blastn_filter.sh**

This script generates a database containing **all genomes** to be included in the analysis as possible LGT donors and blast each CDS from the target pan-genome to it. Then, it filters the CDS for which the best hit belongs to a distant relative --> LGT candidates.

1. Create a database directory `BlastDB-combined`.
2. Download all donor genomes to be included in the database, coding-sequences fasta files, in the desired location.
3. Create a text file with a list of donor genomes to be included in the database with format DB_NAME<\t>IDENTIFIER<\t>PATH_TO_FILE and save it into `ctrl_files`. The default is the file *genomes-n67-screen.txt* used for maize pan-genome containing 67 grass genomes. **Needs to be edited for each pan-genome, since the target species cannot be included**.
4. Modify the native group in the nested script `PG_01b_blastn_loop.sh`, according to the target pan-genome, e.g. Andropogoneae for maize pan-genome.
5. Run script `PG_01a_initial_blastn_filter.sh`.

## Generating multiple alignments

**Script: PG_02a_call_blastn_to_align.sh**

This script calls a nested script for each of the genomes conforming the target pan-genome. The nested script blasts the LGT candidates against multiple databases and generate MAFFT alignments of the blast matches.

1. Create/copy a database directory `BlastDB-separate`. This folder contains individual blast databases for each donor genome. **If the databases are not available, use `makeblastdb -in <donor.cds.fa> -dbtype nucl` for each donor.**
2. Create/copy a text file with a list of donor genomes to be included in the analyses in the folder `ctrl_files`. The default is the file *BlastDBs_n67.txt* used for maize pan-genome.
3. Change the minimum length required for the blast fragments. The default is min_blast_aln_length=300.
4. Run script `PG_02a_call_blastn_to_align.sh`.

## Classify alignments

**Script: PG_03_alignment_filter.sh**

This script classifies and moves the alignments according to the number of taxa and the number of sequences. The pipeline focuses on the alignments with <200 sequences and >10 species.

1. Modify the parameter ID according to the GenomeID used, e.g. ID="Zea_mays" for the maize pan-genome.
2. Run script `PG_03_alignment_filter.sh`.
3. Check if there are alignments with >200 sequences (unlikely) --> if there are some, consider if they have to be included in the analysis and modify the pipeline accordingly.

## Construct trees

**Script: PG_04_initial_trees.sh**

This script uses SMS to construct maximum likelihood trees using the best model (100 bootstraps). It uses an array job to do it, meaning one script per tree will run, but there is only need to submit one script. 

1. Change the heading of the script to adjust the number of trees to construct in the line `#$ -t 1-21680`. The number 21680 is an example, it needs to be substituted by the number of alignments to be used. **Check this number by running `ls | wc -l` within the alignment's folder, e.g. `${wd}/results_03_alignments_filtered/10_species_or_more/less_than_200seqs`.
2. The software used to construct trees, SMS, has a character limit for FASTA ID. If the names of the sequences are too long, it will give an error and exit without constructing the tree. To solve this, the FASTA IDs are cleaned before using SMS (Step 1). The parameters to be removed from those FASTA IDs can be adjusted, e.g. currently only 'evm.model' is removed, and that is enough for SMS to run. **This might change if new genomes are incorporated to the database**. If more genomes are included, check the FASTA IDs and if there are some long ones, identify a common pattern and include it into the Step 1 of the script.
3. Run the script `PG_04_initial_trees.sh`.
4. Check in the results folder whether some trees failed by using the code `grep -B 1 'empty' check_empty.txt`. If there are trees that failed, they will be listed as standard output after the grep command, and the log files will need to be inspected one by one to find the problem.
