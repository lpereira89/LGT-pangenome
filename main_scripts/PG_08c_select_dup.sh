#!/bin/bash
#$ -j y
#$ -l mem=16G
#$ -l rmem=16G
#$ -l h_rt=96:00:00

#####################################################################################
#	Script Name:    select_dup.sh
#	Description:    Select the best DUP aln to construct the trees
#	Author:         LPereiraG
#	Last updated:   22/02/2021
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
aln_dir=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln-named

#### Scripts
script=${wd}/nested_scripts/FilterBestDup.py

#### Step 1: generate info for each aln: number of seq, length of the aln
cd ${aln_dir}
ls | while read line; do cat $line | bioawk -c fastx -v file=$line 'END {print file, NR, length($seq)}' >> info-aln.txt; done

#### Step 2: run python script that selects the best alignment for each duplicate according to total length and number of sequences
# !!!! if it cannot differentiate which one is the best, it will copy all aln for that specific duplicate
python $script
mkdir ../selected-aln
cat selected-aln.csv | cut -d ',' -f 2 | while read line; do cp $line ../selected-aln/${line}; done

#### !!!! these alignments need to be manually inspected
# more instructions in readme file/tutorial
