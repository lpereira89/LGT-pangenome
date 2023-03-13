#!/bin/bash
#$ -j y
#$ -l mem=24G
#$ -l rmem=24G
#$ -l h_rt=96:00:00

#####################################################################################
#	Script Name: 	blastn_loop.sh
#	Description: 	Run a loop of blastn and processing results, used in conjunction with Alien_index_blastn.sh
#	Author:		LTDunning
#	Last updated:	28/04/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files

wd=/mnt/fastdata/bo1lpg/pangenome-pipeline/
# Genome is defined by script PG_01_initial_blastn_filter.sh - sed function substitutes XXXX by each genome ID
Genome=XXXX
results=${wd}/results_01_initial_blastn_filter
CDS=${wd}/CDS
DB_Directory=${wd}/BlastDB-combined

#### Parameters
# !!! Group considered native for each pan-genome has to be adjusted - same identifiers as used in input_files_tab
# Andropogoneae is the example for Zea mays
native="Andropogoneae"

#### Step 1: run blastn
blastn -query ${CDS}/${Genome}/${Genome}_final.cds.fa -db ${DB_Directory}/Combined.fa -outfmt 6 > ${results}/${Genome}_1_Blastn_results_all.txt

#### Step 2: list of genes with blast result
cat ${results}/${Genome}_1_Blastn_results_all.txt | cut -f 1 | sort | uniq > ${results}/${Genome}_2_genes_with_Blastn_matches.txt

#### Step 3: top hit blastn result
cat ${results}/${Genome}_2_genes_with_Blastn_matches.txt | while read line ; do grep "$line" -m 1 \
  ${results}/${Genome}_1_Blastn_results_all.txt >> ${results}/${Genome}_3_Blastn_results_tophit.txt ; done

#### Step 4: top hit blastn result from a different group than the examined genome
cat ${results}/${Genome}_3_Blastn_results_tophit.txt | grep -v "$native" > ${results}/${Genome}_4_Blastn_results_tophit_nonNative.txt

#### Step 5: list of genes with non-native top hit blastn result
cat ${results}/${Genome}_4_Blastn_results_tophit_nonNative.txt | cut -f 1 > ${results}/${Genome}_5_genes_with_tophit_nonNative.txt

#### Step 6: get the best native match for genes with non-native top hit
cat ${results}/${Genome}_5_genes_with_tophit_nonNative.txt | while read line ; \
  do grep "$line" ${results}/${Genome}_1_Blastn_results_all.txt |  if ! grep -m 1 "$native" ; \
  then echo "$line no_match" >&2 >> ${results}/${Genome}_intermediate; fi >> ${results}/${Genome}_intermediate; done

paste ${results}/${Genome}_4_Blastn_results_tophit_nonNative.txt ${results}/${Genome}_intermediate \
  | grep -v "no_match" > ${results}/${Genome}_6_genes_with_tophit_nonNative_and_Native_match.txt

paste ${results}/${Genome}_4_Blastn_results_tophit_nonNative.txt ${results}/${Genome}_intermediate \
  | grep "no_match" > ${results}/${Genome}_7_genes_with_tophit_nonNative_and_no_Native_match.txt

rm ${results}/${Genome}_intermediate
