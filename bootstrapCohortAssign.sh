#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 10                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=100M        		# 100M memory needed
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

module load gcc/6.2.0 R/3.4.1

if [ "$1" != "" ]; then
    echo "treatment list provided: ${1} \n well logHz data provided: ${2}"		
    
    treatmentSamples=$1
	wellLogHzLong=$2

	srun -c 1 -t 30 -p priority --mem=1G ~/scripts/R-3.4.1/bootstrapCohortAssign.R "$treatmentSamples" "$wellLogHzLong" 
else
    echo "Error: Need to provide 2 input files: treatment-samples.csv & well_logHz_long.csv"
fi

