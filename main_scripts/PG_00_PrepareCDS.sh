#!/bin/bash
#$ -j y
#$ -l mem=4G
#$ -l rmem=4G
#$ -l h_rt=6:00:00

#####################################################################################
#	Script Name: 	PrepareCDS.sh
#	Description: 	Polish the CDS fasta file/s used for de novo LGT identification
#	Author:		LPereiraG
#	Last updated:	28/04/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files

# Directory containing the CDS fasta files. One subdirectory for each genome.
# CDS fasta file named {GenomeID}.cds.fa. One subdirectory for each genome, named {GenomeID}
# GenomeID has to be 'Genus_species_00n', e.g. 'Zea_mays_001' for the first Zea mays genome
# !!! Whenever possible, include ONLY primary transcripts

CDS=/mnt/fastdata/bo1lpg/pangenome-pipeline/CDS
ctrl_files=/mnt/fastdata/bo1lpg/pangenome-pipeline/ctrl_files

cd ${CDS}

#### Step 1: get a list of GenomeIDs to go through
ls > ${ctrl_files}/list_genomes.txt

#### Step 2: unwrap sequences
cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; cat ${line}.cds.fa | \
  awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' > ${line}_clean.cds.fa ; cd ../ ; done

#### Step 3: remove unusual characters
cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; sed -i 's/\//_/g' ${line}_clean.cds.fa ; cd ../ ; done

#### Step 4: count Ns and remove isles of NNN, in triplets to keep the protein in frame
cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; cat ${line}_clean.cds.fa | \
  bioawk -c fastx -v subseq="N" '(gsub(subseq,subseq)>1){print ">"$name; print gsub(subseq,subseq)}' > N_stats.txt ; cd .. ; done

cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; sed -i 's/NNN//g' ${line}_clean.cds.fa ; cd ../ ; done

#### Step 5
## Option a: mark all sequences longer than 30 kb and copy them in a different file, check later long, problematic cds
#cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; cat ${line}_clean.cds.fa | \
#  bioawk -c fastx '{ if(length($seq) > 30000) { print ">"$name; print $seq }}' > ${line}_long.cds.fa ; \
#  cd .. ; done

## Option b: eliminate the long sequences
cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; cat ${line}_clean.cds.fa | \
  bioawk -c fastx '{ if(length($seq) < 30000) { print ">"$name; print $seq }}' > ${line}_final.cds.fa ; \
  cd .. ; done

#### Step 6: add a genome ID at the beginning of each sequence ID
cat ${ctrl_files}/list_genomes.txt | while read line ; do cd ${line} ; sed -i "s/>/>${line}_/g" ${line}_final.cds.fa ; cd ../ ; done
