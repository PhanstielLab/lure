#!/bin/bash
## Find overlaping sections

## Get number of probes for comparison
count=$(wc -l < output/final_probes.bed)

## Save start positions (except for the first one) as an array to variable start
start=( $(awk '{if (NR != 1) {print $2}}' output/final_probes.bed ) )

## Save stop position (except for the last one) as an array to variable stop
stop=( $(awk -v a="$count" '{if (NR != a) {print $3}}' output/final_probes.bed ) )

## Paste stop and start together and subtract them (positive values are overlaps)
paste <(printf "%d\n" "${start[@]}") <(printf "%d\n" "${stop[@]}") | awk '{print $2-$1}' > output/gaps


## paste unique restriction fragments to the gaps between the forward and reverse probes for them.
#awk '{print $5}' output/final_probes.bed | uniq > res.sites


## Get the start position for each reverse strand for each restriction site:

awk '{if($6 == "r") print $2}' output/final_probes.bed

awk '{if($6 == "f") print $3}' output/final_probes.bed