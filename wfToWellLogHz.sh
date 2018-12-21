#!/bin/bash
#SBATCH -n 4                    # Number of cores requested
#SBATCH -t 15                           # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=48G       	# 16 GB memory total requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

# Update 2018-04-12

# recording duration needs to be provided in seconds
# as a command line argument

module load gcc/6.2.0 R/3.4.1

if [ "$1" != "" ]; then
    echo "Recording Duration provided as ${1} seconds"
else
    echo "Error: Need to provide Recording Duration as integer in seconds"
fi

# bash command line argument passed to R script (e.g. 1800 second (30min) recordings)
srun ~/scripts/R-3.4.1/wfToWellLogHz.R $1
