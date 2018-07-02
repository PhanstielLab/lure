## Create potential forward probes and get sequences
awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $2+i, $2+i+120, i, $4, "f", $2, $3}' output/fragments.bed | awk '{if ($3 <= $8) print $0}' > output/fint.bed
bedtools nuc -fi output/roi.fasta -bed output/fint.bed -seq > output/fprobes.bed