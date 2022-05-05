#!/bin/bash
#$ -j y
#$ -l mem=16G
#$ -l rmem=16G
#$ -l h_rt=96:00:00

#####################################################################################
#	Script Name: 	rename_aln.sh
#	Description: 	Add prefix to the seq identifier with the tribe name and mark LGT_CANDIDATE
#	Author:		LPereiraG
#	Last updated:	05/05/2022
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
aln_dir=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln-DUP
# species-groups.txt is a list of species including the ID in genome, group and subgroup. One species per row, tab-separated.
species_info=${wd}/ctrl_files/species-groups.txt
output_dir=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln-named

#### Step 1: generate a list of files
cd ${aln_dir}
ls > ../aln_DUP.txt
aln_list=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln_DUP.txt

#### Step 2: remove repeated genes from target genome and add LGT_CANDIDATE to the target gene
# !!!! The gene is already in the file but then it is blasted in the database from the same reference,
# so it will be present twice. We keep the original and remove the one from the database using the prefix DB_
mkdir ../aln-named
cat ${aln_list} | while read line; do gene=$(echo "$line" | cut -d "_" -f 3); \
  cat $line | bioawk -c fastx -v gene=DB_"$gene" '$name !~ gene { print ">"$name"\n"$seq }' \
  | sed 's/'${gene}'/LGT_CANDIDATE_'${gene}'/g' > ../aln-named/${line}; done

#### Step 3: add subfamily and clade information
cat ${species_info} | while read line ; do species=$(echo "$line" | cut -f 1); subfam=$(echo "$line" | cut -f 2) ; clade=$(echo "$line" | cut -f 3) ;\
  ls ${output_dir} | while read line2 ; do sed -i 's/'${species}'/'${subfam}''${clade}''${species}'/g' ${output_dir}/${line2} ; done; done
