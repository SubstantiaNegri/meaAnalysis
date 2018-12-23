#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 15                           # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=12G                #memory requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

# Update 2018-12-23
# changed name of R script called to wfNodeSubset.R
# to reflect new naming scheme

module load gcc/6.2.0 R/3.4.1

srun ~/scripts/R-3.4.1/wfNodeSubset.R 1
