## Reverse - 3rd pass
#Find 120 bp sequences within 110 bp of a restriction site | Find fragments with < 25 repetitive bases | Find fragments with >= 25 & =< 80% GC content. | Select probe closest to each restriction site. Concatenate result.
grep -Evi 'AAAAAAAAAAAAAAAAAAAAAAAAA|TTTTTTTTTTTTTTTTTTTTTTTTT|GGGGGGGGGGGGGGGGGGGGGGGGG|CCCCCCCCCCCCCCCCCCCCCCCCC' $output_folder/rprobes.bed | awk -v OFS="\t" '{if ($10 >= 0.25 && $10 <= 0.80) print $0, 3}' | awk -F "\t" '!seen[$5, $6]++' > $output_folder/rtemp4.bed