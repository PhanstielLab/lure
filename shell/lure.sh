#!/bin/bash
#
# Script Name: hiscsq.sh
#
# Author: Eric S. Davis and Doug Phanstiel
# Date: 06/03/2018
#
# Description: The following script takes a chromosomal region and a restriction enzyme as input and returns HiC-squared probes for that region in bed file format ([output folder]/all_probes.bed)
#
# Dependencies: Requires GNU Parallel (see citation below)
#
#  O. Tange (2018): GNU Parallel 2018, Mar 2018, ISBN 9781387509881,
#  DOI https://doi.org/10.5281/zenodo.1146014

## Setting path variables
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

## Source in usage and variable handling
source $parent_path/../shell/usage.sh

## Remove output folder if it already exists and create fresh
if [ -d $output_folder ]; then
  rm -r $output_folder/
fi
mkdir $output_folder

## Trap interrupt and remove temporary files
function int_function (){
	rm -r $output_folder/
	exit 1
}
trap int_function INT

############################################################################
## Digest ROI to get restricton Fragments

awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" 'BEGIN {print a, b, c}' > $output_folder/roi.bed

bedtools getfasta -fi "$genome" -bed $output_folder/roi.bed -fo $output_folder/roi.fasta 2> $output_folder/bedtools.err
if grep -e "Skipping\|Error" $output_folder/bedtools.err; then
	cat $output_folder/bedtools.err
	exit 1
fi

hicup_digester --re1 $resenz $output_folder/roi.fasta --outdir $output_folder/ --quiet

mv $output_folder/Digest* $output_folder/digest.bed

sed -i.bu '1,2d' $output_folder/digest.bed #add .bu on mac os

awk -v OFS="\t" '{$2-=1}; {print $0}' $output_folder/digest.bed > $output_folder/temp.bed # can't use -i inplace on mac os
mv $output_folder/temp.bed $output_folder/digest.bed

bedtools nuc -fi $output_folder/roi.fasta -bed $output_folder/digest.bed -seq > $output_folder/fragments.bed

sed -i.bu '1d' $output_folder/fragments.bed #add .bu on mac os

awk '{if ($3-$2 > 120) print $0}' $output_folder/fragments.bed > $output_folder/temp.bed # can't use -i inplace on mac os
mv $output_folder/temp.bed $output_folder/fragments.bed
if [ ! -s $output_folder/fragments.bed ] ; then
	echo 'Error: No digest sites found.'
	exit 1
fi

export output_folder=$output_folder

############################################################################
echo 'Constructing Probes .....'
## Create potential forward/reverse probes and get sequences
parallel --bar ::: $parent_path/../shell/create_forward.sh $parent_path/../shell/create_reverse.sh

############################################################################

echo 'Selecting Probes ....'
## Selecting appropriate probes over 3 passes for forward and reverse probes in parallel
parallel --bar ::: $parent_path/../shell/select_forward_1.sh $parent_path/../shell/select_forward_2.sh $parent_path/../shell/select_forward_3.sh $parent_path/../shell/select_reverse_1.sh $parent_path/../shell/select_reverse_2.sh $parent_path/../shell/select_reverse_3.sh


############################################################################
## Concatenate ftemp files in order of pass number
cat $output_folder/ftemp1.bed $output_folder/ftemp2.bed $output_folder/ftemp3.bed $output_folder/ftemp4.bed > $output_folder/all_forward.bed

## Remove duplicate restriction sites from forward probes
awk -F "\t" '!seen[$5, $6]++' $output_folder/all_forward.bed > $output_folder/temp.bed
mv $output_folder/temp.bed $output_folder/all_forward.bed

## Clean up temp files
rm $output_folder/ftemp1.bed $output_folder/ftemp2.bed $output_folder/ftemp3.bed $output_folder/ftemp4.bed


############################################################################
## Concatenate rtemp files in order of pass number
cat $output_folder/rtemp1.bed $output_folder/rtemp2.bed $output_folder/rtemp3.bed $output_folder/rtemp4.bed > $output_folder/all_reverse.bed

## Remove duplicate restriction sites from reverse probes
awk -F "\t" '!seen[$5, $6]++' $output_folder/all_reverse.bed > $output_folder/temp.bed
mv $output_folder/temp.bed $output_folder/all_reverse.bed

## Clean up temp files
rm $output_folder/rtemp1.bed $output_folder/rtemp2.bed $output_folder/rtemp3.bed $output_folder/rtemp4.bed


###########################################################################

## Concatenate forward & reverse probes, sort by restriction site. Header (not included) - chr, start, stop, shift, res.number, dir, pct_at pct_gc, seq, pass
cat $output_folder/all_forward.bed $output_folder/all_reverse.bed | awk -F "\t" '!seen[$5, $6]++' | sort -b -k5,5n -k6,6 | awk -v OFS="\t" '{print $1, $2, $3, $4, $5, $6, $9, $10, $18, $19}' > $output_folder/all_probes.bed

## Add back in genomic coordinates
awk -v OFS="\t" -v a="$chr" -v b="$start" -v c="$stop" '{print $1=a, $2=$2+b, $3=$3+b, $4, $5, $6, $7, $8, $9, $10}' $output_folder/all_probes.bed > $output_folder/temp.bed
mv $output_folder/temp.bed $output_folder/all_probes.bed

## Clean-up unpaired probes and select desired number
echo 'Optimizing Probes ...'
Rscript --vanilla $parent_path/../scripts/reduce_probes.R $output_folder $max_probes

## Remove intermediate files, cat final output
mv $output_folder/filtered_probes.bed filtered_probes.bed
mv $output_folder/all_probes.bed all_probes.bed
mv $output_folder/fragments.bed fragments.bed # For restriction site mapping
rm -r $output_folder/
mkdir $output_folder/
mv filtered_probes.bed $output_folder/filtered_probes.bed
mv all_probes.bed $output_folder/all_probes.bed
mv fragments.bed $output_folder/fragments.bed

echo 'Output:'
## Better formatted output than cat $output_folder/probes.bed
awk -v OFS="\t" 'BEGIN {print "chr", "start", "stop", "shift", "res.fragment", "dir", "pct_at", "pct_gc", "seq", "pass"}{printf "%s \t %i \t %i \t %i \t %i \t %s \t %0.6f \t %0.6f \t %s \t %i\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10}' $output_folder/filtered_probes.bed

