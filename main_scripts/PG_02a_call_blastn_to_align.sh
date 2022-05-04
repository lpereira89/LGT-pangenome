#!/bin/bash
#$ -j y
#$ -l mem=16G
#$ -l rmem=16G
#$ -l h_rt=96:00:00

#####################################################################################
#	Script Name: 	Call_bastn_to_align.sh
#	Description: 	Generate and submit one 02b_blastn_to_align script per genome
#	Author:		LPereiraG
#	Last updated:	15/02/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline/
results=${wd}/results_02_blastn_to_aln
genomes=${wd}/ctrl_files/list_genomes.txt

#### Scripts
loop=${wd}/nested_scripts/PG_02b_blastn_to_align.sh

#### step 1: generate and run separate blastn script for each genome
cd ${wd}
mkdir results_02_blastn_to_aln
cat ${genomes} | cut -f 1 | while read line ; do cat ${loop} | sed 's/XXXX/'$line'/g' > ${results}/$line.sh ; done
cd  ${results}

source /home/bo1lpg/.bashrc
ls *sh | while read line ; do qsub "$line" ; done
