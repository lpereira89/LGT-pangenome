#!/bin/bash
#$ -l h_rt=96:00:00
#$ -t 1-152
#$ -l mem=8G
#$ -l rmem=8G
#$ -j y

#####################################################################################
#	Script Name: 	more_trees.sh
#	Description: 	use SMS to generate ML trees with best model and NO-bootstrap
#	Author:		LTDunning
#	Last updated:	05/05/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

i=$(expr $SGE_TASK_ID)

#### Directories and files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
sel_aln=${wd}/results_08_mark_dups/Fasta_mafft_alignments/aln-named
scriptname=PG_09_more_trees.sh
species_info=${wd}/ctrl_files/species-groups.txt
output_dir=${wd}/results_09_more_trees/combined

#### Scripts
# 'make' from this file /shared/dunning_lab/Shared/scripts/programs/sms-1.8.1.zip
# !!! sms fails to construct the tree if seq names are too long - first step to clean names
sms=/shared/dunning_lab/Shared/programs/sms-1.8.1/./sms.sh
fasta_to_phylip=${wd}/nested_scripts/Fasta2Phylip.pl

#### Parameters
rmname='evm.model'

#### Step 1: create directories and copy files
mkdir -p ${wd}/results_09_more_trees/aln
cd ${wd}/results_09_more_trees/aln
cp -dr ${sel_aln}/* .

#### Step 2: remove irrelevant information from seq ID and conflicting characters
# the portion to be removed has to be adjusted - in grasses, current genome database, this parameter works
sed -i 's/${rmname}//g' *
sed -i 's/:/_/g' *
sed -i 's/\//_/g' *

#### Step 3: remove clade and family names before constructing the tree
cat ${species_info} | while read line ; do species=$(echo "$line" | cut -f 1); subfam=$(echo "$line" | cut -f 2) ; clade=$(echo "$line" | cut -f 3) ;\
  ls | while read line2 ; do sed -i 's/'${subfam}''${clade}''${species}'/'${species}'/g' ${line2} ; done; done

#### Step 4: convert fasta to phylip
cd ${wd}/results_09_more_trees
ls aln > list_genes.txt
fasta_list=${wd}/results_09_more_trees/list_genes.txt
head -$i ${fasta_list} | tail -1 | while read line ; do mkdir -p ${wd}/results_09_more_trees/individual/"$line" ; \
  mkdir -p ${wd}/results_09_more_trees/combined ; mkdir -p ${wd}/results_09_more_trees/logs ; \
  cd ${wd}/results_09_more_trees/individual/"$line" ; perl ${fasta_to_phylip} ${fasta_dir}/"$line" "$line" ; done

#### Step 5: run sms and make a copy of the tree
head -$i ${fasta_list} | tail -1 | while read line ; do cd ${wd}/results_09_more_trees/individual/"$line" ; \
  ${sms} -i $line -d nt -t ; cp *phyml_tree.txt ${wd}/results_09_more_trees/combined ; done

#### Step 6: clean up by moving log files
mv ${scriptname}.o*.$i ${wd}/results_09_more_trees/logs
mv ${scriptname}.e*.$i ${wd}/results_09_more_trees/logs

#### Step 7: add subfamily and clade information
cat ${species_info} | while read line ; do species=$(echo "$line" | cut -f 1); subfam=$(echo "$line" | cut -f 2) ; clade=$(echo "$line" | cut -f 3) ;\
  ls ${output_dir} | while read line2 ; do sed -i 's/'${species}'/'${subfam}''${clade}''${species}'/g' ${output_dir}/${line2} ; done; done
