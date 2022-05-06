#!/bin/bash
#$ -l h_rt=96:00:00
#$ -t 1-120
#$ -l mem=8G
#$ -l rmem=8G
#$ -j y

#####################################################################################
#	Script Name: 	final_trees.sh
#	Description: 	use SMS to generate ML trees with best model and 100 bootstrap reps
#	Author:		LTDunning
#	Last updated:	06/05/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

i=$(expr $SGE_TASK_ID)

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
sel_aln=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln-clean
output_dir=${wd}/results_10_final_trees
species_info=${wd}/ctrl_files/species-groups.txt
scriptname=PG_10_final_trees.sh

#### Scripts
# 'make' from this file /shared/dunning_lab/Shared/scripts/programs/sms-1.8.1.zip
# !!! sms fails to construct the tree if seq names are too long - first step to clean names
sms=/shared/dunning_lab/Shared/programs/sms-1.8.1/./sms.sh
fasta_to_phylip=${wd}/nested_scripts/Fasta2Phylip.pl

#### Parameters
rmname='evm.model'

#### Step 1: create directories and copy files
mkdir -p ${wd}/results_10_final_trees/aln
cd ${wd}/results_10_final_trees/aln
cp -dr ${sel_aln}/* .

#### Step 2: remove irrelevant information from seq ID and conflicting characters
# the portion to be removed has to be adjusted - in grasses, current genome database, this parameter works
sed -i 's/${rmname}//g' *
sed -i 's/:/_/g' *
sed -i 's/\//_/g' *

#### Step 3: remove clade and family names before constructing the tree
cat ${species_info} | while read line ; do species=$(echo "$line" | cut -f 1); subfam=$(echo "$line" | cut -f 2) ; clade=$(echo "$line" | cut -f 3) ;\
  ls | while read line2 ; do sed -i 's/'${subfam}''${clade}''${species}'/'${species}'/g' ${line2} ; done; done

#### Step 4: create directories and convert fasta to phylip
cd ${wd}/results_10_final_trees
ls aln > list_genes.txt
fasta_list=${wd}/results_10_final_trees/list_genes.txt
head -$i ${fasta_list} | tail -1 | while read line ; do mkdir -p ${output_dir}/individual/"$line" ; \
  mkdir -p ${output_dir}/combined ; mkdir -p ${output_dir}/logs ;  cd ${output_dir}/individual/"$line" ; \
  perl ${fasta_to_phylip} ${fasta_dir}/"$line" "$line" ; done

#### Step 5: run sms and make a copy of the tree
head -$i ${fasta_list} | tail -1 | while read line ; do cd ${output_dir}/individual/"$line" ; \
  ${sms} -i $line -d nt -t -b 100; cp *phyml_tree.txt ${output_dir}/combined ; done

#### Step 6: clean up by moving log files
mv ${scriptname}.o*.$i ${output_dir}/logs
mv ${scriptname}.e*.$i ${output_dir}/logs

#### Step 7: check that none of the tree files are empty
cd ${output_dir}/combined
ls | while read line; do echo ${line} >> ../check_empty.txt; \
  [ -s ${line} ] && echo "full" >> ../check_empty.txt;
  [ -s ${line} ] || echo "empty" >> ../check_empty.txt; done
