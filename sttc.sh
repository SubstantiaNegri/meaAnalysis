#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 15                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority             # Partition (queue) to submit to
#SBATCH --mem=10M       	# 10M memory total requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line
#----------------------------------------------------------------

# upadate 2018-12-20
# * added clustered waveform file as input argument
# * changed order of arguments
# * updated error message to be more descriptive
# * moved srun command to within if statement, so not executed if 
#   command line arguments are not provided.

module load gcc/6.2.0 R/3.4.1

if [ "$5" != "" ]; then
	echo "
		active cluster pairs file provided: ${1}
		revised clustered waveforms file provided: ${2}
		Tinit provided: ${3}
		recDur provided: ${4}
		DeltaT provided: ${5}
		output file provided: ${6}"

	Date=$(date '+%Y-%m-%d')
	clusterPairFile=$1
	clusteredWFfile=$2	
	Tinit=$3
	recDur=$4
	DeltaT=$5

	if [ "$6" != "" ]; then
	outputFile=$6
        touch $outputFile
	else
	outputFile=${Date}_sttc.csv
	touch ${Date}_sttc.csv
	fi

	while read -r LINE;
 		do IFS=\, read -a cols <<< "$LINE";
 		sbatch -n 1 -t 3 -p short --mem=2G ~/scripts/R-3.4.1/sttc.R ${cols[@]} "$Tinit" "$recDur" "$DeltaT" "$clusteredWFfile" "$outputFile";
 		done < "$clusterPairFile"

else 
	echo "Error: Need to provide following inputs: 
		* active cluster pairs file
		* revised clustred waveform file
		* Tinit - timestamp (seconds) within recording to begin caclculating STTC
		* recDur - duration interval (seconds) of recording to assess STTC
		* DeltaT - time interval (seconds) around each firing event to use in calculation of STTC"
fi

#Date=$(date '+%Y-%m-%d')
#clusterPairFile=$1
#Tinit=$2
#recDur=$3
#DeltaT=$4
#outputFile=${Date}_sttc.csv

#touch ${Date}_sttc.csv

#while read -r LINE;
# do IFS=\, read -a cols <<< "$LINE";
# sbatch -n 1 -t 2 -p short --mem=200M ~/scripts/R-3.4.1/sttc.R ${cols[@]} "$Tinit" "$recDur" "$DeltaT" "$outputFile";
# done < "$clusterPairFile"
