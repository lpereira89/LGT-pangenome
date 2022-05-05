#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug 19 12:18:14 2021

@author: larapereiragarcia
"""

import pandas as pd
import numpy as np

#Read an info file that contains name of the alignment, number of sequences
#contained in the alignment and length of the alignment. This file generated
#by the script NAM_08b_rename_aln.sh.
aln = pd.read_table('info-aln.txt', header=None)
aln = aln.rename(columns={0 : "file", 1 : "numseq", 2 : "lenseq"})

#Add one column with the identifier of the duplicate
dup = []
for i in range(len(aln.file)):
    dup.append(aln.file[i][4:7])

aln.insert(loc=3, column='dup', value=dup)

#Record the number of duplicates we have
duplic = np.array(dup)
unique = np.unique(duplic)

#Initialize object that will contain the selected alignments
selected = pd.DataFrame(columns=['file', 'numseq', 'lenseq', 'dup'])

#For each duplicate, order by 1. number of seqs and 2. length of the alignment
#and select the top ranked
for value in unique:
    subset = aln[aln['dup']==value]
    subset = subset.sort_values(by=["numseq", "lenseq"], ascending=(False, False))
    selected = selected.append(subset[:1])

#Save this table into a file
selected.to_csv('selected-aln.csv')
