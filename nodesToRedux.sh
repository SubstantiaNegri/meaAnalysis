#!/bin/bash

#  nodesToRedux.sh
#  version 1.0
#
#  Created by Joseph Negri on 11/29/17.
#  copyright is maintained and must be perserved.
#  The work is provided as is; ; no warranty is provided, and users accept all liability.

#  This script will generate and compare two lists: clustered_nodes, a list of  
#  electrodes (nodes) from MEA recordings from which recording data was successfully 
#  analyzed using the MEA_node-MS-cluster script; and a list of all nodes. 
#  This script will identify which nodes were not clustered and copy the data file
#  to a new subdirectory nodeRedux, excluding those files corresponding to 'inactive'
#  nodes which did not record a minimum threshold of spike events

#  This script should be run within the directory of a given experiment containing
#  the /node subdirectory

# ***************************************************************************************

#define line count thresholds
minimum=10

# generate array containing all nodes
allNodes=($(ls node | grep -v 'MS' | grep -v 'sample' | grep 'csv'))

# modify array to eliminate extraneous text from each entry
allNodes=($(echo ${allNodes[@]%.csv}))

# create array with nodes successfully clustered
clusteredNodes=($(for i in node/*MS*; do echo ${i}; done))

# strip extraneous text from clustered nodes
clusteredNodes=($(echo ${clusteredNodes[@]} | sed 's/node\///g;s/sampled_//g;s/_MSclstr.csv//g'))

# identify lines (i.e. nodes) present within allNodes but not within clusteredNodes
# save to an array missedNodes
# comm requires sorted lists as input, hence printing arrays as lists and sorting output
# option -1 suppresses unique members of first list
# option -3 suppresses members common to both lists
missedNodes=($(comm -13 <(printf '%s\n' "${clusteredNodes[@]}" | sort) <(printf '%s\n' "${allNodes[@]}" | sort)))

# make directory nodesRedux
mkdir nodeRedux

# copy data from each missing node to nodesRedux directory
for i in ${missedNodes[@]}
		do 
		line_count=$(wc -l node/$i.csv | cut -f1 -d' ')
				if [ "$line_count" -gt "$minimum" ]
				then 
						cp node/$i.csv nodeRedux 
				fi
		done;