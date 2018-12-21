#!/bin/bash
#SBATCH -n 2                    # Number of cores requested
#SBATCH -t 90                           # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=64G                # 16 GB memory requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

module load matlab/2017a

matlab -nodisplay -r "spkParse96well; quit"
