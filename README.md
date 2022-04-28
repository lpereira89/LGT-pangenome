# LGT-pangenome

This file describes the in-house pipeline used for de novo identification of lateral gene transfers in multiple reference genomes from the same species (pan-genome). It includes primarily bash scripts to be run in ShARC HPC from University of Sheffield (https://docs.hpc.shef.ac.uk/en/latest/sharc/index.html), and nested scripts in perl, python and R that are called by the bash scripts.

Most of the bash scripts need to be inspected and modified according to the user's folder structure, target pan-genome and genomes to be included in the analyses. These files, directories and parameters are defined **at the beginning** of the scripts, so the user can easily generate their own custom versions for each pan-genome.

## Preparing the genomes

**Script: PG_00_PrepareCDS.sh**

This script prepares the raw input files, fasta files containing the coding sequences for all gene models in the reference genomes from the target pan-genome. The script eliminates problematic characters and erroneous gene models, and adds a genome identifier to each coding sequence ID.

1. Create a directory `CDS` and one subdirectory `GenomeID` for each of the genomes to include in the analysis. **GenomeID has to be 'Genus_species_00n', e.g. 'Zea_mays_001' for the first Zea mays genome**
2. Download the fasta files into the directory. Whenever possible, include only primary transcripts.
3. Name the files as {GenomeID}.cds.fa.
4. Create a 'control files' directory `ctrl_files`.
5. Run script `PG_00_PrepareCDS.sh`.

## First BLAST filter

**Script: PG_01a_initial_blastn_filter.sh**

This script generates a database containing **all genomes** to be included in the analysis as possible LGT donors and blast each CDS from the target pan-genome to it. Then, it filters the CDS for which the best hit belongs to a distant relative.

1. Create a database directory `BlastDB-combined`.
2. Create a text file with a list of databases with format DB_NAME<\t>IDENTIFIER<\t>PATH_TO_FILE and save it into `ctrl_files`. The default is the file text *genomes-n67-screen.txt* containing 67 grass genomes.
3. Create the results folder `results_01_initial_blastn_filter`.
4. Modify the native group in the nested script `PG_01b_blastn_loop.sh`, according to the target pan-genome, e.g. Andropogoneae for maize pan-genome.
5. Run script `PG_01a_initial_blastn_filter.sh`.
