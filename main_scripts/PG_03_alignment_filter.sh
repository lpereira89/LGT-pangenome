#!/bin/bash
#$ -j y
#$ -l mem=8G
#$ -l rmem=8G
#$ -l h_rt=96:00:00


#####################################################################################
#	Script Name: 	alignment_filter.sh
#	Description: 	classify alignments depending on # of taxa and seq
#	Author:		LTDunning
#	Last updated:	22/02/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
input=${wd}/results_02_blastn_to_aln
# Generic genome ID we attached to each CDS ID in script PG_00 - Zea_mays in maize, for example
ID="Zea_mays"

#### step 1: create directories
cd ${wd}
mkdir -p results_03_alignments_filtered
cd results_03_alignments_filtered

cp ${input}/*/Fasta_mafft_alignments/* .

mkdir 10_species_or_more
mkdir less_than_10
mkdir -p 10_species_or_more/less_than_200seqs
mkdir -p 10_species_or_more/more_than_200seqs

#### step 2: check number of species and move alignments with <10 taxa
ls * | while read line ; do grep ">" "$line" | cut -f 1,2 -d '_' | sort | uniq | wc -l | sed 's/^/'$line'\t/g' >> number_sp.txt ; done
cat number_sp.txt | awk '$2 < 10' | cut -f 1 | while read line ; do mv "$line" less_than_10 ; done
rm number_sp.txt

#### step 3: move alignments with >200 seq
grep -c ">" * | sed 's/:/\t/g' | awk '$2 >=200' | cut -f 1 | while read line ; do mv "$line" 10_species_or_more/more_than_200seqs/ ; done

#### step 4: move rest of the alignments
mv ${ID}* 10_species_or_more/less_than_200seqs/

#### step 5: create a list of files to make trees for
cd 10_species_or_more
ls less_than_200seqs > less_than_200seqs.txt
