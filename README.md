# LGT-pangenome

This file describes the in-house pipeline used for de novo identification of lateral gene transfers in multiple reference genomes from the same species (pan-genome). It includes primarily bash scripts to be run in ShARC HPC from University of Sheffield (https://docs.hpc.shef.ac.uk/en/latest/sharc/index.html), and nested scripts in perl, python and R that are called by the bash scripts.

Most of the bash scripts need to be inspected and modified according to the user's folder structure, target pan-genome and genomes to be included in the analyses. These files, directories and parameters are defined **at the beginning** of the scripts, so the user can easily generate their own custom versions for each pan-genome. The nested scripts do not need to be edited.

## Preparing the genomes

**Script: PG_00_PrepareCDS.sh**

1. Create a directory (CDS) and one subdirectory (GenomeID) for each of the genomes to include in the analysis. **GenomeID has to be 'Genus_species_00n', e.g. 'Zea_mays_001' for the first Zea mays genome**
2. Download the fasta files into the directory. Whenever possible, include only primary transcripts.
3. Name the files as {GenomeID}.cds.fa.
4. Create a 'control files' directory (ctrl_files).
5. Run script PG_00_PrepareCDS.sh.

