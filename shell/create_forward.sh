## Create potential forward probes and get sequences
awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $2+i, $2+i+120, i, $4, "f", $2, $3}' /tmp/hicsq/fragments.bed | awk '{if ($3 <= $8) print $0}' > /tmp/hicsq/fint.bed
bedtools nuc -fi /tmp/hicsq/roi.fasta -bed /tmp/hicsq/fint.bed -seq > /tmp/hicsq/fprobes.bed