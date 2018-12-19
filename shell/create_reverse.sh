## Create potential reverse probes and get sequences
awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $3-i-120, $3-i, i, $4, "r", $2, $3}' /tmp/hicsq/fragments.bed | awk '{if ($2 >= $7) print $0}' > /tmp/hicsq/rint.bed
bedtools nuc -fi /tmp/hicsq/roi.fasta -bed /tmp/hicsq/rint.bed -seq > /tmp/hicsq/rprobes.bed