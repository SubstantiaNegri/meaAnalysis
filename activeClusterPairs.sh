#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 10                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority             # Partition (queue) to submit to
#SBATCH --mem=1G                # 1G memory needed
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

module load gcc/6.2.0 R/3.4.1

if [ "$1" != "" ]; then
    echo "clustered waveform file provided: ${1}"		
    wfClusterFile=$1
    srun -c 1 -t 10 -p priority --mem=1G ~/scripts/R-3.4.1/activeClusterPairs.R "$wfClusterFile" 
else
    echo "Error: Need to provide input file: revised clustered waveforms e.g. wf.metrics.clustered.revised.csv"
fi

