#!/bin/bash
#SBATCH -n 2                    # Number of cores requested
#SBATCH -t 60                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority             # Partition (queue) to submit to
#SBATCH --mem=32G       	# 32 GB memory total requested
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

# Update 2018-04-02 
# changed version of MEA_spk-cluster-metrics to v1.1

# Update 2018-04-12
# changed version MEA_spk_cluster_metrics to v1.2
# recording duration needs to be provided in seconds

# Update 2018-12-23
# changed name of R script to spkClusterMetrics.R to
# reflect new naming scheme

module load gcc/6.2.0 R/3.4.1

if [ "$1" != "" ]; then
    echo "Recording Duration provided as ${1} seconds"
    srun ~/scripts/R-3.4.1/spkClusterMetrics.R $1
else
    echo "Error: Need to provide Recording Duration as integer in seconds"
fi


