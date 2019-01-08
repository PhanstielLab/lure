## Reverse - 2nd pass
# Find 120 bp sequences within 110 bp of a restriction site | Find fragments with < 20 repetitive bases | Find fragments with >= 40 & =< 70% GC content. | Select probe closest to each restriction site. Concatenate result.
grep -Evi 'AAAAAAAAAAAAAAAAAAAA|TTTTTTTTTTTTTTTTTTTT|GGGGGGGGGGGGGGGGGGGG|CCCCCCCCCCCCCCCCCCCC' /tmp/lure/rprobes.bed | awk -v OFS="\t" '{if ($10 >= 0.4 && $10 <= 0.7) print $0, 2}' | awk -F "\t" '!seen[$5, $6]++' > /tmp/lure/rtemp3.bed
