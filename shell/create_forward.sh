## Create potential forward probes and get sequences
awk -v a="$length" -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $2+i, $2+i+a, i, $4, "f", $2, $3}' "$output_folder/fragments.bed" | awk '{if ($3 <= $8) print $0}' > "$output_folder/fint.bed"
#awk -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $2+i, $2+i+50, i, $4, "f", $2, $3}' "$output_folder/fragments.bed" | awk '{if ($3 <= $8) print $0}' > "$output_folder/fint.bed"
bedtools nuc -fi "$output_folder/roi.fasta" -bed "$output_folder/fint.bed" -seq > "$output_folder/fprobes.bed"