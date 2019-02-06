#!/bin/bash

## Define usage function
usage () {
	echo '

     Description:

	 Lure is a probe design tool for Hi-C squared experiments. Use the options detailed below
	 to select a region of interest, choose a restriction enzyme,  and specify the maximum
	 number of probes to create.


     Usage:

	-g (genome): Path to the genome of interest (fasta format).

	-c (chromosome): Enter the chromosome of interest in the form "chr*" where * is an integer.

	-b (begin): Start position of your region of interest for probe design. -b must be less than -e.

	-e (end): Stop position on the chromosome. -e must be greater than -b.

	-r (restriction enzyme): Restriction enzyme to digest region of interest. (i.e. "^GATC,MobI")

	-n (number of probes desired): Defaults to maximum possible probes if not supplied.
	
	-o (output folder): Path where output files should go.


     Default:

	-g: "genomes/hg19/hg19.fasta"

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

	-n: (max number of probes)
	
	-o: "/tmp/lure"

' #| less

}

default () {
	echo '

	Default:

	-g: "genomes/hg19/hg19.fasta"

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

	-n: (max number of probes)
	
	-o: "/tmp/lure"

	'
}


## Define default values
genome_DEFAULT="genomes/hg19/hg19.fasta"
chr_DEFAULT="chr8"
start_DEFAULT="133000000"
stop_DEFAULT="135000000"
resenz_DEFAULT="^GATC,MobI"
max_probes_DEFAULT=""
output_folder_DEFAULT="/tmp/lure"


## Parse command-line arguments with getopts
while getopts g:c:b:e:r:n:o: ARGS;
do
	case "${ARGS}" in
		g)
		   genome=${OPTARG};;
		c)
		   chr=${OPTARG};;
		b)
		   start=${OPTARG};;
		e)
		   stop=${OPTARG};;
		r)
		   resenz=${OPTARG};;
		n)
		   max_probes=${OPTARG};;
		o)
		   output_folder=${OPTARG};;
		*)
		   usage
		   exit 1
		;;
	esac
done

# VARIABLE when it is returned
: ${genome=$genome_DEFAULT}
: ${chr=$chr_DEFAULT}
: ${start=$start_DEFAULT}
: ${stop=$stop_DEFAULT}
: ${resenz=$resenz_DEFAULT}
: ${max_probes=$max_probes_DEFAULT}
: ${output_folder=$output_folder_DEFAULT}

## Error checking
genome="${genome/#\~/$HOME}"
if [[ -f $genome ]]
	then
		:
	else
		echo 'invalid option: -g, Enter an existing fasta file'
		exit
fi

if [ $stop -lt $start ]
	then
		echo 'invalid option: -e must be greater than -b'
		usage
		exit 1
fi

## Display options used
if [ -z "$max_probes" ]; 
	then
		mpf="Maximum"

	else
		mpf="$max_probes"
fi

output_folder="${output_folder/#\~/$HOME}"

## Function to display settings for probe design
settings (){
	echo "Genome: " $genome
	echo "Chromosome: " $chr
	echo "Start: " $start
	echo "Stop: " $stop
	echo "Restriction Enzyme: " $resenz
	echo "Number of probes: " $mpf
	echo "Output folder: " $output_folder
	echo ""
}

## Prompt before running
while true; do
			settings
    		read -p "Run these settings? [Y/n] " yn
    		case $yn in
        		[Yy]* ) break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer yes or no.";;
    		esac
done

shift $((OPTIND -1))
