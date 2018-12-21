#!/bin/bash
#SBATCH -n 1                    # Number of cores requested
#SBATCH -t 10                   # Runtime in minutes
                                # Or use HH:MM:SS or D-HH:MM:SS, instead of just number of minutes
#SBATCH -p priority                # Partition (queue) to submit to
#SBATCH --mem=100M                # memory requested for execuiting sbactch script
#SBATCH --open-mode=append      # append adds to outfile, truncate deletes first
### In filenames, %j=jobid, %a=index in job array
#SBATCH -o %j.out               # Standard out goes to this file
#SBATCH -e %j.err               # Standard err goes to this file
#SBATCH --mail-type=END         # Mail when the job ends  
#write command-line commands below this line

#  wf.cluster.number.triage.sh
#  version 1.7
#
#  Created by Joseph Negri on 8/28/17.
#  copyright is maintained and must be perserved.
#  The work is provided as is; ; no warranty is provided, and users accept all liability.

#  This script is for the purpose of submitting MSclstr.R jobs to LSF Orchestra 
#  queues based on number of spike events (lines) within each node file

#  Update 2017-08-31
#  edited to reflect new version of MEA_node-MS-cluster_v1.1.R

#  Update 2017-10-11
#  * converted into S-Batch script for running on O2
#  * edited job submission calls to reflect O2 syntax
#  * edited to reflect new version of MEA_node-MS-cluster_v1.3.R

# Update 2017-10-16
#  * added new level to line count thresholds 'minimum'
#  * adjusted submissions to partitions such that >5K lines sent to medium

# Update 2017-10-17
#  * changed method for samling files >10K lines
#  * increased time for jobs w/>10K lines to 100hrs (4-4:00:00) in slurm format

# Update 2017-11-08
#  * updated version of MEA_node-MS-cluster called from v1.3 to v1.4

# Update 2017-11-29
#  * decreased time for jobs in medium queue to 36hrs (1-12:00:00) in slurm format
# meta analysis of clustering nodes with >10K events found that MEA_node-MS-cluster script
# rarely (<0.1%) of jobs took longer than 24hrs to complete. All those taking longer
# where stalled and eventually timed out. Decreasing time threshold prevents jobs destine
# to time out from clogging slurm queue

# Update 2017-12-01
#  * decreased requested memory, changing option from --mem-per-cpu to --mem
#  to stipulate total memory per job and not memory per node
#  --mem-per-cpu=2G across 12 nodes means 24G are being requested
#  request decreased to 4G total

# Update 2018-01-03
#  * decreased time limit on jobs submitted to medium queue down to 18hrs
#  ammendment to update 2017-11-29, the average clustering time in the 
#  medium queue for 10K spikes is ~2hrs any job requiring >12hrs is likely
#  hung up and destined to eventually time out. 

# Update 2018-01-12
# * further refinement of memory and time requests
# for all jobs, memory request decreased to 2GB from 4GB, retrospective analysis
# shows that jobs rarely require more than 1GB
# for small clustering jobs (<1000 spks), time decreased to 15min from 30min
# for medium jobs (1000-5000 spks), time decreased to 3hrs from 12hrs
# for large jobs (5000-10000 spks), time decreased to 12hrs, allowing all 
# jobs to be run in short queue.
# For jobs that fail due to memory or time limits, will be resubmitted with
# alternative script requesting additional time/memory. 

# Update 2018-07-30
# * further refinement of memory and time requests
# recent performance of >3000 clustering jobs showed
# none required >50% of requested  memory (i.e.  <1GB)
# and on average only require ~10% of requested time.
# mem request for all jobs reduced to 1GB
# time requests for medium jobs (1000-5000 spks) decreased to 1hr from 3hr
# time requests for large jobs (5000-10000 spks) decreased to 3hr from 12hr

# Update 2018-08-03
# * updated version of MEA_node-MS-cluster called from v1.4 to v1.5

# Update 2018-09-27
# * version of script without subsetting of highly active nodes by sampling.
#  required for input into network analysis in which timing of all spikes is required

# Update 2018-12-07
# * reduced time request for 'mid' jobs to 1hr from 3hr,
#     'high' jobs to 6hr from 12hr, and 'superhigh' jobs from 24hr to 48hr

# Update 2018-12-18
# * increased 'mid' jobs to 3hr, 'high' to 12hr, and 'super-high' to 96hr
###########################################################################################

#define line count thresholds
minimum=10
low_count=1000
mid_count=5000
high_count=10000

#define requested times
low_count_time=15
mid_count_time=3:00:00
high_count_time=12:00:00
super_count_time=96:00:00

echo 'node' 'line_count' > inactive_nodes.txt
echo 'node' 'line_count' > superactive_nodes.txt

for f in $(ls *.csv) 
	do
	line_count=$(wc -l $f | cut -f1 -d' ')
		if [ "$line_count" -le "$minimum" ]
		then
			echo "${f%.csv}" $line_count >> inactive_nodes.txt
		elif [ "$line_count" -le "$low_count" ]
		then
			echo $f
			sbatch -p short -t $low_count_time -n 12 --mem=1G ~/scripts/R-3.4.1/MEA_node-MS-cluster_v1.5.R $f 12
		elif [ "$line_count" -le "$mid_count" ]
		then
			echo $f
			sbatch -p short -t $mid_count_time -n 12 --mem=1G ~/scripts/R-3.4.1/MEA_node-MS-cluster_v1.5.R $f 12
		elif [ "$line_count" -le "$high_count"  ]
		then
			echo $f
			sbatch -p short -t $high_count_time -n 12 --mem=1G ~/scripts/R-3.4.1/MEA_node-MS-cluster_v1.5.R $f 12
		else
			echo "${f%.csv}" $line_count >> superactive_nodes.txt
			sbatch -p medium -t $super_count_time -n 12 --mem=2G ~/scripts/R-3.4.1/MEA_node-MS-cluster_v1.5.R $f 12
		fi
	done; 

