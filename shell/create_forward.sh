## Create potential forward probes and get sequences
awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $2+i, $2+i+120, i, $4, "f", $2, $3}' /tmp/lure/fragments.bed | awk '{if ($3 <= $8) print $0}' > /tmp/lure/fint.bed
bedtools nuc -fi /tmp/lure/roi.fasta -bed /tmp/lure/fint.bed -seq > /tmp/lure/fprobes.bed