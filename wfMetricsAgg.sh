#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 60                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=100M        	#  memory requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

Date=$(date '+%Y-%m-%d')
currentPath=$(pwd)
currentDir=$(basename $currentPath)
Experiment=$(echo ${currentDir#*_})
wfMetricsFiles=($(find ./ -type f -name '*wfMetrics.csv'))
srun sed 1q ${wfMetricsFiles[0]} >> ${Date}_${Experiment}_wf.metrics.csv
for f in ${wfMetricsFiles[@]};
		do srun sed 1d $f >> ${Date}_${Experiment}_wf.metrics.csv;
done;
