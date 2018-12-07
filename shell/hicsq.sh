#!/bin/bash
#
# Script Name: hiscsq.sh
#
# Author: Eric S. Davis and Doug Phanstiel
# Date: 06/03/2018
#
# Description: The following script takes a chromosomal region and a restriction enzyme as input and returns HiC-squared probes for that region in bed file format (output/all_probes.bed)
#
# Output: output is returned in the output/ subdirectory
#
# Dependencies: Requires GNU Parallel (see citation below)
#
#  O. Tange (2018): GNU Parallel 2018, Mar 2018, ISBN 9781387509881,
#  DOI https://doi.org/10.5281/zenodo.1146014

## Setting path variables
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
cd ..

## Source in usage and variable handling
source ./shell/usage.sh

## Remove output folder if it already exists and create new output/
if [ -d "output/" ]; then
  rm -r output/
fi
mkdir output/

## Trap interrupt and remove temporary files
function int_function (){
	rm -r output/
	exit 1
}
trap int_function INT

############################################################################
## Digest ROI to get restricton Fragments

awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" 'BEGIN {print a, b, c}' > output/roi.bed

bedtools getfasta -fi "$genome" -bed output/roi.bed -fo output/roi.fasta 2> output/bedtools.err
if grep -q Skipping output/bedtools.err; then
	cat output/bedtools.err
	exit 1
fi

hicup_digester --re1 $resenz output/roi.fasta --outdir output/ --quiet

mv output/Digest* output/digest.bed

sed -i.bu '1,2d' output/digest.bed #add .bu on mac os

awk -v OFS="\t" '{$2-=1}; {print $0}' output/digest.bed > output/temp.bed # can't use -i inplace on mac os
mv output/temp.bed output/digest.bed

bedtools nuc -fi output/roi.fasta -bed output/digest.bed -seq > output/fragments.bed

sed -i.bu '1d' output/fragments.bed #add .bu on mac os

awk '{if ($3-$2 > 120) print $0}' output/fragments.bed > output/temp.bed # can't use -i inplace on mac os
mv output/temp.bed output/fragments.bed


############################################################################
echo 'Constructing Probes .....'
## Create potential forward/reverse probes and get sequences
parallel --bar ::: ./shell/create_forward.sh ./shell/create_reverse.sh

############################################################################

echo 'Selecting Probes ....'
## Selecting appropriate probes over 3 passes for forward and reverse probes in parallel
parallel --bar ::: ./shell/select_forward_1.sh ./shell/select_forward_2.sh ./shell/select_forward_3.sh ./shell/select_reverse_1.sh ./shell/select_reverse_2.sh ./shell/select_reverse_3.sh


############################################################################
## Concatenate ftemp files in order of pass number
cat output/ftemp1.bed output/ftemp2.bed output/ftemp3.bed output/ftemp4.bed > output/all_forward.bed

## Remove duplicate restriction sites from forward probes
awk -F "\t" '!seen[$5, $6]++' output/all_forward.bed > output/temp.bed
mv output/temp.bed output/all_forward.bed

## Clean up temp files
rm output/ftemp1.bed output/ftemp2.bed output/ftemp3.bed output/ftemp4.bed


############################################################################
## Concatenate rtemp files in order of pass number
cat output/rtemp1.bed output/rtemp2.bed output/rtemp3.bed output/rtemp4.bed > output/all_reverse.bed

## Remove duplicate restriction sites from reverse probes
awk -F "\t" '!seen[$5, $6]++' output/all_reverse.bed > output/temp.bed
mv output/temp.bed output/all_reverse.bed

## Clean up temp files
rm output/rtemp1.bed output/rtemp2.bed output/rtemp3.bed output/rtemp4.bed


###########################################################################

## Concatenate forward & reverse probes, sort by restriction site. Header (not included) - chr, start, stop, shift, res.number, dir, pct_at pct_gc, seq, pass
cat output/all_forward.bed output/all_reverse.bed | awk -F "\t" '!seen[$5, $6]++' | sort -b -k5,5n -k6,6 | awk -v OFS="\t" '{print $1, $2, $3, $4, $5, $6, $9, $10, $18, $19}' > output/all_probes.bed

## Add back in genomic coordinates
awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" '{print $1=a, $2=$2+b, $3=$3+b, $4, $5, $6, $7, $8, $9, $10}' output/all_probes.bed > output/temp.bed
mv output/temp.bed output/all_probes.bed

## Clean-up unpaired probes and select desired number
echo 'Optimizing Probes ...'
Rscript --vanilla scripts/reduce_probes.R $max_probes

## Remove intermediate files, cat final output
mv output/filtered_probes.bed filtered_probes.bed
mv output/all_probes.bed all_probes.bed
mv output/fragments.bed fragments.bed # For restriction site mapping
rm -r output/
mkdir output/
mv filtered_probes.bed output/filtered_probes.bed
mv all_probes.bed output/all_probes.bed
mv fragments.bed output/fragments.bed

echo 'Output:'
## Better formatted output than cat output/probes.bed
awk -v OFS="\t" 'BEGIN {print "chr", "start", "stop", "shift", "res.fragment", "dir", "pct_at", "pct_gc", "seq", "pass"}{printf "%s \t %i \t %i \t %i \t %i \t %s \t %0.6f \t %0.6f \t %s \t %i\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' output/filtered_probes.bed

