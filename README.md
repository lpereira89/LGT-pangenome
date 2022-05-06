# LGT-pangenome

This file describes the in-house pipeline used for de novo identification of lateral gene transfers in multiple reference genomes from the same species (pan-genome). It includes primarily bash scripts to be run in ShARC HPC from University of Sheffield (https://docs.hpc.shef.ac.uk/en/latest/sharc/index.html), and nested scripts in perl, python and R that are called by the bash scripts.

Most of the bash scripts need to be inspected and modified according to the user's folder structure, target pan-genome and genomes to be included in the analyses. These files, directories and parameters are defined **at the beginning** of the scripts, so the user can easily generate their own custom versions for each pan-genome.

## Prepare the genomes

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

## Generate multiple alignments

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

## Midpoint root the trees

**Script: PG_05_midpoint_rooting.sh**

This script roots the trees using midpoint rooting.

1. Run the script `PG_05_midpoint_rooting.sh`.

## Identify sister relationships

**Script: PG_06_IDsister.sh**

This script calls a nested script to identify the groups that are sister to the LGT candidate in the trees. Then the results are parsed to get a list of LGT candidates for which the LGT is nested in a group different from the target pan-genome, e.g. Andropogoneae in the example, and this nesting is supported by a minimum bootstrap, e.g. 50 in the example.

1. Change the parameter `target_group` according to the target pan-genome being analyzed.
2. Create/copy a *species_list* file in `ctrl_files` directory. The list must include all the species in the database, one per line, with the same exact name and the group to which they belong, separated by tabs.
3. Run the script `PG_06_IDsister.sh`.

## Blast target sequences and align the best hits

**Script: PG_07_blastn_to_align_step2.sh**

This script uses the list of LGT candidates to start a new iteration of blast-align-tree. At this step, not only genomes but also transcriptomes are included in the BlastDB. 

1. The minimum length of the blast hit to be included in the alignment can be defined as a parameter, e.g. 300 in the example.
2. Check the transcriptomes to be included in the database. Currently, there is a list from in a shared directory, but that can be easily customized in Step 2.
3. Run the script `PG_07_blastn_to_align_step2.sh`.
4. Check manually the file *missing_alignments.txt*. These two files must be empty, if there are gene IDs the log file needs to be inspected to identify the problem in each case. **Previous issues were that too many NNNs were in the sequences, that genes were too long, and that complex characters were part of the FASTA ID - these issues should be solved now in script PG_00_prepareCDS.sh. However, similar issues might arise when working with other genomes.**

## Mark duplicated LGT candidates

**Script: PG_08a_mark_dups.sh**

This script marks the duplicated LGT candidates. Since we performed LGT identification in several independent assemblies, LGT that are present in more than one assembly were likely identified in more than one assembly - but they are orthologous genes, meaning they likely represent the same LGT event. **Only one** orthologous LGT will be kept as a candidate for further analyses.

1. The nested script `sort_homologs_2.pl` works only when copying specific modules (Heap071 Graph Graph.pm) to the same folder where the script is run. There are two solutions: (1) copy the modules into the nested scripts folder *default in script* or (2) run the script from the shared drive (currently `/shared/dunning_lab/Shared/scripts/perl/sort_homologs_2.pl`) *need to change the code*. 
2. Run the script `PG_08a_mark_dups.sh`.

## Rename the FASTA IDs in alignments

**Script: PG_08b_rename_aln.sh**

This script renames the alignment to ease manual inspection. It adds *LGT_candidate_* prefix to the LGT candidate, and it adds the group ID to all other species.

1. Copy/create a tab-separated text file with one species per row, and three columns: species ID, group and subgroup. **The species ID in this file needs to match exactly the one contained in the FASTA ID in the alignment**, e.g. 'Oryza_sativa_Japonica_Group_GCA_001433935.1' for one of the rice genomes. The group and subgroup will be added as prefixes at the beginning of the FASTA ID.
2. Run the script `PG_08b_rename_aln.sh`.

## Select best alignment

**Script: PG_08c_select_dup.sh**

This script selects the best duplicate as representative for each LGT. The criteria are: (1) highest number of sequences in the alignment and (2) longest alignment.

1. Run the script `PG_08c_select_dup.sh`.

## Construct trees

**Script: PG_09_more_trees.sh**

This script uses SMS to construct maximum likelihood trees using the best model. It uses an array job to do it, meaning one script per tree will run, but there is only need to submit one script. 

1. Change the heading of the script to adjust the number of trees to construct in the line `#$ -t 1-152`. The number 152 is an example, it needs to be substituted by the number of alignments to be used. **Check this number by running `ls | wc -l` within the alignment's folder.**
2. The software used to construct trees, SMS, has a character limit for FASTA ID. If the names of the sequences are too long, it will give an error and exit without constructing the tree. To solve this, the FASTA IDs are cleaned before using SMS (Step 1). The parameters to be removed from those FASTA IDs can be adjusted, e.g. currently only 'evm.model' is removed, and that is enough for SMS to run. **This might change if new genomes are incorporated to the database**. If more genomes are included, check the FASTA IDs and if there are some long ones, identify a common pattern and include it into the Step 1 of the script.
3. Run the script `PG_09_more_trees.sh`.

## Inspect manually the selected alignments and trees

This step needs to be executed in the user local machine. The alignments need to be trimmed, corrected and cleaned to improve the quality of the phylogenetic trees in the following steps.

1. Download to local machine the selected alignments from the directory `${working_directory}/results_08_mark_dups/Fasta_mafft_alignments/selected-aln` and the corresponding trees from the directory `${wd}/results_09_more_trees/combined`. 
2. Install/gain access to Geneious or a similar software to inspect and edit sequences and trees.

### Inspect the trees
First, inspect the trees. The criteria to maintain a gene as LGT candidate are:
- The LGT candidate is nested within another clade, e.g. a maize candidate LGT nested in Paniceae.
- The tree must have >2 taxa within the donor clade and >2 taxa outside of the donor clade.
- Obvious paralogy problems in the tree.
The trees that comply with these three criteria are then selected for further inspection of their multiple alignments.

### Edit the alignments
Second, edit the alignment in Geneious. 
- Build a tree using GTR method.
- Frame the protein guided by the LGT candidate (full CDS). Since the other sequences are from blast hits, not complete CDS, the frame will not always be correct. Delete bases when needed to correct the frame, either at the start of the sequence or within the sequence around small indels.
- For the same species for which only transcriptomes are available, sometimes there are several small sequences that correspond to one unique transcript. In such cases, join the fragments of transcripts in one unique, longer sequence, making sure to keep the correct frame.
- Build a new tree using the translation mode.
- Check again the alignment and make sure that the frame is correct for all sequences. **If it is not, keep trimming bases until they are all correct**.
- Since the sequences are from blast hits, and not complete CDS, an artifact is caused at the end of the alignment. One or two bases are artificially aligned to the last codon, generating an 'artificial' long gap. Delete these one or two bases in all sequences.
- Once the alignments are trimmed, export and upload them to ShARC to `${working_directory}/results_08_mark_dups/Fasta_mafft_alignments/aln-clean`.

## Construct final trees

**Script: PG_10_final_trees.sh**

This script generates final trees using the polished alignments following the same approach used above (maximum likelihood trees with SMS).

1. Change the heading of the script to adjust the number of trees to construct in the line `#$ -t 1-120`. The number 120 is an example, it needs to be substituted by the number of alignments to be used. **Check this number by running `ls | wc -l` within the alignment's folder.**
2. The software used to construct trees, SMS, has a character limit for FASTA ID. If the names of the sequences are too long, it will give an error and exit without constructing the tree. To solve this, the FASTA IDs are cleaned before using SMS (Step 2). The parameters to be removed from those FASTA IDs can be adjusted, e.g. currently only 'evm.model' is removed, and that is enough for SMS to run. **This might change if new genomes are incorporated to the database**. If more genomes are included, check the FASTA IDs and if there are some long ones, identify a common pattern and include it into the Step 2 of the script.
3. Run the script `PG_10_final_trees.sh`.

## Final manual inspection

This step needs to be executed in the user local machine. The alignments need to be trimmed, corrected and cleaned to improve the quality of the phylogenetic trees in the following steps.

1. Download to local machine the trees from the directory `${wd}/results_10_final_trees/combined`.

Inspect the trees. The criteria to maintain a gene as LGT candidate are:
- The LGT candidate is nested within another clade, e.g. a maize candidate LGT nested in Paniceae.
- The tree must have >2 taxa within the donor clade and >2 taxa outside of the donor clade.
- Obvious paralogy problems in the tree.
- Bootstrap support >70 supporting the LGT within the donor clade.
The trees that comply with these criteria are considered **LGT**.

