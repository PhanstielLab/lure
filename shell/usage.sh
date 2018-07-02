#!/bin/bash

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


     Default:

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

'| less

}


while getopts c:b:e:r:h ARGS;
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
		h|*) 
		   usage
		   exit 1
		;;
	esac
done


if [ $# -eq 0 ]
then
	echo '
     Default:

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"
	'

	chr="chr8"
	start="133000000"
	stop="135000000"
	resenz="^GATC,MobI"
fi


if [ $stop -lt $start ]
then
	echo 'invalid option: -e must be greater than -b'
	usage
	exit 1
fi
shift $((OPTIND -1))