## Create potential reverse probes and get sequences
#awk -v a="$length" -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $3-i-a, $3-i, i, $4, "r", $2, $3}' "$output_folder/fragments.bed" | awk '{if ($2 >= $7) print $0}' > "$output_folder/rint.bed"
#awk  -v OFS="\t" '{for (i = 0; i <= 110; ++i) print $1, $3-i-50, $3-i, i, $4, "r", $2, $3}' "$output_folder/fragments.bed" | awk '{if ($2 >= $7) print $0}' > "$output_folder/rint.bed"
#bedtools nuc -fi "$output_folder/roi.fasta" -bed "$output_folder/rint.bed" -seq > "$output_folder/rprobes.bed"


## Create potential forward probes and get sequences
awk -v a="$length" -v d="$reverse" -v e="rlength" -v OFS="\t" '{
	if (length(d) != 0) {
		if (toupper($17) ~ (d "$")) {
			for (i = e; i <= 110; ++i) {
				print $1, $3-i-a, $3-i, i, $4, "r", $2, $3
			}
		}
		else {
			for (i = 0; i <= 110; ++i) {
				print $1, $3-i-a, $3-i, i, $4, "r", $2, $3
			}
		}
	}
	else {
		for (i = 0; i <= 110; ++i) {
			print $1, $3-i-a, $3-i, i, $4, "r", $2, $3
		}
	}
}' "$output_folder/fragments.bed" | awk '{if ($2 >= $7) print $0}' > "$output_folder/rint.bed"


bedtools nuc -fi "$output_folder/roi.fasta" -bed "$output_folder/rint.bed" -seq > "$output_folder/rprobes.bed"