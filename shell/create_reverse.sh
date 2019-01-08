## Create potential reverse probes and get sequences
awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $3-i-120, $3-i, i, $4, "r", $2, $3}' /tmp/lure/fragments.bed | awk '{if ($2 >= $7) print $0}' > /tmp/lure/rint.bed
bedtools nuc -fi /tmp/lure/roi.fasta -bed /tmp/lure/rint.bed -seq > /tmp/lure/rprobes.bed