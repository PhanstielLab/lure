#!/bin/bash
#
# Script Name: hiscsq.sh
#
# Author: Eric S. Davis and Doug Phanstiel
# Date: 06/03/2018
#
# Description: The following script takes a chromosomal region and a restriction enzyme as input and returns HiC-squared probes for that region in bed file format (/tmp/lure/all_probes.bed)
#
# Output: output is returned in the /tmp/lure/ subdirectory
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

## Remove output folder if it already exists and create new /tmp/lure/
if [ -d "/tmp/lure/" ]; then
  rm -r /tmp/lure/
fi
mkdir /tmp/lure/

## Trap interrupt and remove temporary files
function int_function (){
	rm -r /tmp/lure/
	exit 1
}
trap int_function INT

############################################################################
## Digest ROI to get restricton Fragments

awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" 'BEGIN {print a, b, c}' > /tmp/lure/roi.bed

bedtools getfasta -fi "$genome" -bed /tmp/lure/roi.bed -fo /tmp/lure/roi.fasta 2> /tmp/lure/bedtools.err
if grep -e "Skipping\|Error" /tmp/lure/bedtools.err; then
	cat /tmp/lure/bedtools.err
	exit 1
fi

hicup_digester --re1 $resenz /tmp/lure/roi.fasta --outdir /tmp/lure/ --quiet

mv /tmp/lure/Digest* /tmp/lure/digest.bed

sed -i.bu '1,2d' /tmp/lure/digest.bed #add .bu on mac os

awk -v OFS="\t" '{$2-=1}; {print $0}' /tmp/lure/digest.bed > /tmp/lure/temp.bed # can't use -i inplace on mac os
mv /tmp/lure/temp.bed /tmp/lure/digest.bed

bedtools nuc -fi /tmp/lure/roi.fasta -bed /tmp/lure/digest.bed -seq > /tmp/lure/fragments.bed

sed -i.bu '1d' /tmp/lure/fragments.bed #add .bu on mac os

awk '{if ($3-$2 > 120) print $0}' /tmp/lure/fragments.bed > /tmp/lure/temp.bed # can't use -i inplace on mac os
mv /tmp/lure/temp.bed /tmp/lure/fragments.bed
if [ ! -s /tmp/lure/fragments.bed ] ; then
	echo 'Error: No digest sites found.'
	exit 1
fi


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
cat /tmp/lure/ftemp1.bed /tmp/lure/ftemp2.bed /tmp/lure/ftemp3.bed /tmp/lure/ftemp4.bed > /tmp/lure/all_forward.bed

## Remove duplicate restriction sites from forward probes
awk -F "\t" '!seen[$5, $6]++' /tmp/lure/all_forward.bed > /tmp/lure/temp.bed
mv /tmp/lure/temp.bed /tmp/lure/all_forward.bed

## Clean up temp files
rm /tmp/lure/ftemp1.bed /tmp/lure/ftemp2.bed /tmp/lure/ftemp3.bed /tmp/lure/ftemp4.bed


############################################################################
## Concatenate rtemp files in order of pass number
cat /tmp/lure/rtemp1.bed /tmp/lure/rtemp2.bed /tmp/lure/rtemp3.bed /tmp/lure/rtemp4.bed > /tmp/lure/all_reverse.bed

## Remove duplicate restriction sites from reverse probes
awk -F "\t" '!seen[$5, $6]++' /tmp/lure/all_reverse.bed > /tmp/lure/temp.bed
mv /tmp/lure/temp.bed /tmp/lure/all_reverse.bed

## Clean up temp files
rm /tmp/lure/rtemp1.bed /tmp/lure/rtemp2.bed /tmp/lure/rtemp3.bed /tmp/lure/rtemp4.bed


###########################################################################

## Concatenate forward & reverse probes, sort by restriction site. Header (not included) - chr, start, stop, shift, res.number, dir, pct_at pct_gc, seq, pass
cat /tmp/lure/all_forward.bed /tmp/lure/all_reverse.bed | awk -F "\t" '!seen[$5, $6]++' | sort -b -k5,5n -k6,6 | awk -v OFS="\t" '{print $1, $2, $3, $4, $5, $6, $9, $10, $18, $19}' > /tmp/lure/all_probes.bed

## Add back in genomic coordinates
awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" '{print $1=a, $2=$2+b, $3=$3+b, $4, $5, $6, $7, $8, $9, $10}' /tmp/lure/all_probes.bed > /tmp/lure/temp.bed
mv /tmp/lure/temp.bed /tmp/lure/all_probes.bed

## Clean-up unpaired probes and select desired number
echo 'Optimizing Probes ...'
Rscript --vanilla scripts/reduce_probes.R $max_probes

## Remove intermediate files, cat final output
mv /tmp/lure/filtered_probes.bed filtered_probes.bed
mv /tmp/lure/all_probes.bed all_probes.bed
mv /tmp/lure/fragments.bed fragments.bed # For restriction site mapping
rm -r /tmp/lure/
mkdir /tmp/lure/
mv filtered_probes.bed /tmp/lure/filtered_probes.bed
mv all_probes.bed /tmp/lure/all_probes.bed
mv fragments.bed /tmp/lure/fragments.bed

echo 'Output:'
## Better formatted output than cat /tmp/lure/probes.bed
awk -v OFS="\t" 'BEGIN {print "chr", "start", "stop", "shift", "res.fragment", "dir", "pct_at", "pct_gc", "seq", "pass"}{printf "%s \t %i \t %i \t %i \t %i \t %s \t %0.6f \t %0.6f \t %s \t %i\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' /tmp/lure/filtered_probes.bed

