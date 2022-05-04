#!/bin/bash
#$ -j y
#$ -l h_rt=24:00:00

#####################################################################################
#	Script Name: 	midpoint_rooting.sh
#	Description: 	Midpoint root trees
#	Author:		LaraPereiraG
#	Last updated:	04/05/2022
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline
trees=${wd}/results_04_initial_trees/less_than_200seqs/combined
output=${wd}/results_05_rooted_trees

#### Scripts
root=/usr/local/extras/Genomics/apps/anaconda_python/bin/FastRoot.py

#### Step 1: create directories and list files
cd ${wd}
mkdir results_05_rooted_trees
cd ${output}

#### Step 2: run script to midpoint root trees
ls ${trees} | while read line; \
  do /usr/local/extras/Genomics/apps/anaconda_python/bin/python3 ${root} -m MP -i ${trees}/${line} -o ${output}/${line}; done
