## Selecting appropriate probes (forward - 1st pass):
# Find 120 bp sequences within 80bp of restriction site | Find fragments with < 10 repetitive bases | Find fragments with >= 50 & =< 60% GC content. | Select probe closest to each restriction site. Concatenate result.
awk '{if ($4 <= 80) print $0}' /tmp/lure/fprobes.bed | grep -Evi 'AAAAAAAAAA|TTTTTTTTTT|GGGGGGGGGG|CCCCCCCCCC' > /tmp/lure/ftemp0.bed
awk -v OFS="\t" '{if ($10 >= 0.5 && $10 <= 0.6) print $0, 0}' /tmp/lure/ftemp0.bed | awk -F "\t" '!seen[$5, $6]++' > /tmp/lure/ftemp1.bed


## Forward - 1st pass (looser)
# Find 120 bp sequences within 80bp of restriction site | Find fragments with < 10 repetive bases | Find fragments with >= 40 & =< 70% GC content. | Select probe closest to each restriction site. Concatenate result.
awk -v OFS="\t" '{if ($10 >= 0.4 && $10 <= 0.7) print $0, 1}' /tmp/lure/ftemp0.bed | awk -F "\t" '!seen[$5, $6]++' > /tmp/lure/ftemp2.bed
