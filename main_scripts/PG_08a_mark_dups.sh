#!/bin/bash
#$ -j y
#$ -l mem=8G
#$ -l rmem=8G
#$ -l h_rt=96:00:00

#####################################################################################
#	Script Name:    mark_dups.sh
#	Description:    Mark all the alignments that contain duplicates
#	Author:         LTDunning
#	Last updated:   05/05/2022, LPG
#####################################################################################

source /usr/local/extras/Genomics/.bashrc

#### Directories and input files
wd=/mnt/fastdata/bo1lpg/pangenome-pipeline

#### Scripts
consensus=${wd}/nested_scripts/consensus.pl
# !!!! This nested script works only when copying specific modules to the same folder (Heap071 Graph Graph.pm)
# where the script is run and by using an old version of perl
# Alternatively, it can be run from /shared/dunning_lab/Shared/scripts/perl/sort_homologs_2.pl
sort_hom=${wd}/nested_scripts/sort_homologs_2.pl

#### Step 1: create directories, copy alignments and generate list of alignments
cd ${wd}
mkdir -p results_08_mark_dups/Fasta_mafft_alignments
cd results_08_mark_dups/Fasta_mafft_alignments
cp -dr ${wd}/results_07_blastn_to_aln/Fasta_mafft_alignments/* .
ls > ../query.txt

#### Step 2: Identify blastn matches represented by only one sequence fragment and move these to their own folder
mkdir unique duplicated aln-dups-removed consensus
cat ../query.txt | while read line ; do grep ">" "$line" | cut -f 2 -d ">" | sort | awk '{count[$1]++} END {for (word in count) print word, count[word]}' | \
    grep "\s1$" | cut -f 1 -d ' '  | while read line2 ; do grep "$line2$" -A 1 "$line" >> unique/"$line" ; done; done

#### Step 3: Identify blastn matches represented by more than one sequence fragment and move these to their own folder
cat ../query.txt | while read line ; do grep ">" "$line" | cut -f 2 -d ">" | sort | awk '{count[$1]++} END {for (word in count) print word, count[word]}' | \
grep -v "\s1$" | cut -f 1 -d ' '  | while read line2 ; do grep "$line2$" -A 1 "$line" >> duplicated/"$line"_"$line2" ; done; done
sed -i '/^--$/d' duplicated/*

#### Step 4: generate a single consensus sequence for blastn matches represented by more than one sequence
ls duplicated/ | while read line ; do perl ${consensus} -in duplicated/"$line"  -out consensus/"$line" -iupac ; done
ls consensus  | while read line ; do sed -i '/>/c\>'$line'' consensus/"$line" ; done
cat ../query.txt | while read line ; do sed -i 's/>'$line'_/>/g' consensus/"$line"_*  ; done

#### Step 5: merge the consensus and unique sequences into a single alignment
cat ../query.txt | while read line ; do cat unique/"$line" consensus/"$line"_* > aln-dups-removed/"$line" ; done
cat ../query.txt | while read line ; do awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < aln-dups-removed/"$line" > aln-dups-removed/"$line"_unwrap ; done
cat ../query.txt | while read line ; do tail -n +2 aln-dups-removed/"$line"_unwrap > aln-dups-removed/"$line" ; rm aln-dups-removed/"$line"_unwrap ; done

#### Step 6: clean up the results folder
rm -r unique duplicated consensus
rm *
mv aln-dups-removed/* .
rm -r aln-dups-removed

#### Step 7: identify duplicated sequences
ls * > list
cat list | while read line ;do grep "$line" * | grep -v "list" | sed 's/:>/\t/g' | cut -f 1 | sed 's/^/'$line'\t/g' | grep -v "potential_duplicates" >> potential_duplicates.txt ; done

#### Step 8: mark duplicated sequences
# !!!! This line below works only when copying specific modules to the same folder (Heap071 Graph Graph.pm) where the script is run
# and by using an old version of perl
perl5.16.3  ${sort_hom} potential_duplicates.txt > out

#### Step 9: generate list of duplicates
rm potential_duplicates.txt list
mkdir Check-DUPS/
split -a 3 -d -l 1 out Check-DUPS/DUP_
for filename in Check-DUPS/* ; do sed -i 's/\s/\n/g' "$filename" ; done
mkdir aln-DUP
cd  Check-DUPS/
for filename in * ; do cat "$filename" | sed 's/\s/\n/g' | while read line ; do cp ../"$line" ../aln-DUP/"$filename"_"$line" ; done ; done
