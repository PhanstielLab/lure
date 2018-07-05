#!/bin/bash

## Define usage function
usage () {
	echo '

     Description:

	 Hi-Csq is a probe design tool for Hi-C squared experiments. Use the options detailed below
	 to select a region of interest, choose a restriction enzyme,  and specify the maximum
	 number of probes to create.


     Usage:

	-c (chromosome): Enter the chromosome of interest in the form "chr*" where * is an integer.

	-b (begin): Start position of your region of interest for probe design. -b must be less than -e.

	-e (end): Stop position on the chromosome. -e must be greater than -b.

	-r (restriction enzyme): Restriction enzyme to digest region of interest. (i.e. "^GATC,MobI")

	-g (genome): Path to the genome of interest (fasta format).

	-n (number of probes desired): Defaults to maximum possible probes if not supplied.


     Default:

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

	-g: "genomes/hg19/hg19.fasta"

	-n: (max number of probes)

' #| less

}

default () {
	echo '

	Default:

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

	-g: "genomes/hg19/hg19.fasta"

	-n: (max number of probes)


	'
}


## Define default values
chr_DEFAULT="chr8"
start_DEFAULT="133000000"
stop_DEFAULT="135000000"
resenz_DEFAULT="^GATC,MobI"
genome_DEFAULT="genomes/hg19/hg19.fasta"
max_probes_DEFAULT=""


## Parse command-line arguments with getopts
while getopts c:b:e:r:g:n: ARGS;
do
	case "${ARGS}" in
		c)
		   chr=${OPTARG};;
		b)
		   start=${OPTARG};;
		e)
		   stop=${OPTARG};;
		r)
		   resenz=${OPTARG};;
		g)
		   genome=${OPTARG};;
		n)
		   max_probes=${OPTARG};;
		*)
		   usage
		   exit 1
		;;
	esac
done

# VARIABLE when it is returned
: ${chr=$chr_DEFAULT}
: ${start=$start_DEFAULT}
: ${stop=$stop_DEFAULT}
: ${resenz=$resenz_DEFAULT}
: ${genome=$genome_DEFAULT}
: ${max_probes=$max_probes_DEFAULT}

## Error checking
if [ $# -eq 0 ]
	then
		while true; do
			default
    		read -p "Run default settings? [Y/n]" yn
    		case $yn in
        		[Yy]* ) break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer yes or no.";;
    		esac
	done
fi


if [ $stop -lt $start ]
	then
		echo 'invalid option: -e must be greater than -b'
		usage
		exit 1
fi

if [ -e "$genome" ]
	then
		:
	else
		echo 'invalid option: -g, Enter an existing fasta file'
		exit
fi

## Display options used
if [ -z "$max_probes" ]; 
	then
		mpf="Maximum"
		awk -v chr="$chr" -v start="$start" -v stop="$stop" -v resenz="$resenz" -v mp="$mpf" 'BEGIN {printf "\n\nChromosome: %s\n\nStart: %i\n\nStop: %i\n\nRestriction Enzyme: %s\n\nNumber of probes: %s\n\n", chr, start, stop, resenz, mp}'
	else
		mpf="$max_probes"
		awk -v chr="$chr" -v start="$start" -v stop="$stop" -v resenz="$resenz" -v mp="$mpf" 'BEGIN {printf "\n\nChromosome: %s\n\nStart: %i\n\nStop: %i\n\nRestriction Enzyme: %s\n\nNumber of probes: %i\n\n", chr, start, stop, resenz, mp}'
fi




shift $((OPTIND -1))
