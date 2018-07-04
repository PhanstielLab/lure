#!/bin/bash
#
# Script Name: hiscsq.sh
#
# Author: Eric S. Davis and Doug Phanstiel
# Date: 06/03/2018
#
# Description: The following script takes a chromosomal region and a restriction enzyme as input and returns HiC-squared probes for that region in bed file format (output/final_probes.bed)
#
# Output: output is returned in the output/ subdirectory
#
# Dependencies: Requires GNU Parallel (see citation below)
#
#  O. Tange (2018): GNU Parallel 2018, Mar 2018, ISBN 9781387509881,
#  DOI https://doi.org/10.5281/zenodo.1146014

## Source in usage and variable handling
source ./shell/usage.sh

## Remove output folder if it already exists and create new output/
if [ -d "output/" ]; then
  rm -r output/
fi
mkdir output/

############################################################################
## Digest ROI to get restricton Fragments

awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" 'BEGIN {print a, b, c}' > output/roi.bed

bedtools getfasta -fi genomes/hg19/hg19.fasta -bed output/roi.bed -fo output/roi.fasta

hicup/hicup_v0.6.1/hicup_digester --re1 $resenz output/roi.fasta --outdir output/

mv output/Digest* output/digest.bed

sed -i.bu '1,2d' output/digest.bed #add .bu on mac os

awk -v OFS="\t" '{$2-=1}; {print $0}' output/digest.bed > output/temp.bed # can't use -i inplace on mac os
mv output/temp.bed output/digest.bed

bedtools nuc -fi output/roi.fasta -bed output/digest.bed -seq > output/fragments.bed

sed -i.bu '1d' output/fragments.bed #add .bu on mac os

awk '{if ($3-$2 > 120) print $0}' output/fragments.bed > output/temp.bed # can't use -i inplace on mac os
mv output/temp.bed output/fragments.bed

echo 'Constructing Probes .....'

############################################################################
## Create potential forward/reverse probes and get sequences
parallel --bar ::: ./shell/create_forward.sh ./shell/create_reverse.sh

############################################################################
## Selecting appropriate probes over 3 passes for forward and reverse probes in parallel
parallel --bar ::: ./shell/select_forward_1.sh ./shell/select_forward_2.sh ./shell/select_forward_3.sh ./shell/select_reverse_1.sh ./shell/select_reverse_2.sh ./shell/select_reverse_3.sh


############################################################################
## Concatenate ftemp files in order of pass number
cat output/ftemp1.bed output/ftemp2.bed output/ftemp3.bed output/ftemp4.bed > output/final_forward.bed

## Remove duplicate restriction sites from forward probes
awk -F "\t" '!seen[$5, $6]++' output/final_forward.bed > output/temp.bed
mv output/temp.bed output/final_forward.bed

## Clean up temp files
rm output/ftemp1.bed output/ftemp2.bed output/ftemp3.bed output/ftemp4.bed


############################################################################
## Concatenate rtemp files in order of pass number
cat output/rtemp1.bed output/rtemp2.bed output/rtemp3.bed output/rtemp4.bed > output/final_reverse.bed

## Remove duplicate restriction sites from reverse probes
awk -F "\t" '!seen[$5, $6]++' output/final_reverse.bed > output/temp.bed
mv output/temp.bed output/final_reverse.bed

## Clean up temp files
rm output/rtemp1.bed output/rtemp2.bed output/rtemp3.bed output/rtemp4.bed


###########################################################################

## Concatenate forward & reverse probes, sort by restriction site. Header (not included) - chr, start, stop, shift, res.number, dir, pct_at pct_gc, seq, pass
cat output/final_forward.bed output/final_reverse.bed | awk -F "\t" '!seen[$5, $6]++' | sort -b -k5,5n -k6,6 | awk -v OFS="\t" '{print $1, $2, $3, $4, $5, $6, $9, $10, $18, $19}' > output/final_probes.bed

## Add back in genomic coordinates
awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" '{print $1=a, $2=$2+b, $3=$3+b, $4, $5, $6, $7, $8, $9, $10}' output/final_probes.bed > output/temp.bed
mv output/temp.bed output/final_probes.bed

## Clean-up unpaired probes and select desired number
Rscript --vanilla scripts/reduce_probes.R $max_probes

## Remove intermediate files, cat final output
mv output/probes.bed probes.bed
rm -r output/
mkdir output/
mv probes.bed output/probes.bed
cat output/probes.bed
