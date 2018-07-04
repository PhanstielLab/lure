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

	-n (number of probes desired): Defaults to maximum possible probes if not supplied.


     Default:

	-c: "chr8"

	-b: "133000000"

	-e: "135000000"

	-r: "^GATC,MboI"

	-n: (max number of probes)

' #| less

}


while getopts c:b:e:r:n:h ARGS;
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
		n)
			 max_probes=${OPTARG};;
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
	max_probes=""
fi


if [ $stop -lt $start ]
then
	echo 'invalid option: -e must be greater than -b'
	usage
	exit 1
fi
shift $((OPTIND -1))
