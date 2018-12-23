#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 5                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=1GB        		# 1 GB memory needed
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when job ends  
#write command-line commands below this line

module load gcc/6.2.0 R/3.4.1

for f in $(ls *volt.csv)
	do 
	sbatch -c 1 -t 10 -p short --mem=1G --mail-type=FAIL --wrap="echo $f; ~/scripts/R-3.4.1/wfMetrics.R $f ${f%volt.csv}SD.csv ${f%volt.csv}time.csv"
done

