#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 15                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority             # Partition (queue) to submit to
#SBATCH --mem=10M       	    # 10M memory total requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line
#----------------------------------------------------------------

# initial version 2019-01-09

module load gcc/6.2.0 R/3.4.1

if [ "$4" != "" ]; then
	echo "cluster count pairs file provided ${1}
		recDur provided: ${2}
		DeltaT provided: ${3}
		iterations provided: ${4}
		output file name provided: ${5}"

	Date=$(date '+%Y-%m-%d')
	clusterCountFile=$1
	recDur=$2	
	DeltaT=$3
	iterations=$4
	
	if [ "$5" != "" ]; then
        outputFile=$5
        else
        outputFile=${Date}_sttcSimulation.csv
        fi

	touch $outputFile

	while read -r LINE;
 		do IFS=\, read -a clusterCounts <<< "$LINE";
 		sbatch -n 1 -t 1 -p short --mem=100M ~/scripts/R-3.4.1/sttcSim.R ${clusterCounts[@]} "$recDur" "$DeltaT" "$iterations" "$outputFile";
 		done < "$clusterCountFile"

else 
	echo "Error: Need to provide following inputs: 
		* cluster count pairs file
		* recDur - duration interval (seconds) of recording to assess STTC
		* DeltaT - time interval (seconds) around each firing event to use in calculation of STTC
		* iterations - number of iterations of STTC calculation to simulate"
fi