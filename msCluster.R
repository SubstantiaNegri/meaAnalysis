#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  msCluster
#  Version 1.5
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2017-07-05
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script for Mean-Shift clustering on all spike events detected by an 
#  by individual electrode 'node' from across all MEA recordings of a single experiment

#  this script accepts a single arugment, a .csv file containing all of the waveform data
#  from a given node. This file passed as argument is the output of the MEA_node-wf-subset.R script 

#  This script will return:
#  a single .csv file with the original data plus the calculated principle component values
#  and the corresponding cluster value for each spike event

#  Update 2017-08-31 (v1.1)
#  script modified to so that crossing threshold (uV) and 
#  spike timestamp data is included along with 
#  waveform parameters, cluster, recording, and voltage data

#  Update 2017-09-08 (v1.2)
#  made changes to the arguments passed to msClustering function
#  to take advantage of multi-core processing
#  the number of cores is specified as the second command line argument

#  Update 2017-10-11 (v1.3)
#  *eliminated calls to unused libraries
#  *updated library calls to reflect R 3.4.1 library versions

#  Update 2017-11-08 (v1.4)
#  *revision to how spike data is combined:
#     - metrics (peak, valley, NLE, etc.)
#     - principles components
#     - cluster indentifier
#     - voltage data (momentary volatages 1-38)
#     - meta-data (plate, well, node, recording, time, SD)

# Update 2018-08-03 (v1.5)
# * updated method of extracting waveform metrics data
#   to first identify columns by name, then determine column indexes.
#   rather than hard coding column indexes
# * Removed call to exclude first column ('spike') when combining data for 
#   output

# Update 2018-12-23
#  renamed script to msCluster.R from MEA_node-MS-cluster_v1.5.R for
#  clarity now that verison are being maintained with git 

#  Load Essential Libraries----
# Load the data.table package to enable extended dataframe functions
library("data.table", lib.loc="~/R-3.4.1/library")
# Load the multiple comparison 'multcomp' package 
#library("multcomp", lib.loc="~/R-3.4.1/library")
#library("MESS", lib.loc="~/R-3.4.1/library")
library("wavethresh", lib.loc="~/R-3.4.1/library")
library("MeanShift", lib.loc="~/R-3.4.1/library")

set.seed(1)

# define variables----

# write arguments to args vector
args <- commandArgs(trailingOnly = TRUE)

# save name of node being analyzed
node <- strsplit(args[1],".csv")[[1]][1]

# number of cores to use for processing
n.cores <- args[2]

# waveform  metrics
wfMetricNames <- c("peak","valley","peak.valley","pvi","auc","NLE.max")

# Main----
# read in wf data from individual node
node.wf.metrics <- read.csv(args[1])

# identify position of wfMetric columns
wfMetricCols <- match(wfMetricNames, colnames(node.wf.metrics))
# isolate wf metrics from voltage and node meta-data
array.metrics <- as.matrix(node.wf.metrics[,wfMetricCols])

# perform log transformtion on wf metrics
log.array.metrics <- log10(array.metrics) 

# calculate principle components across wf metrics
array.pc <- prcomp(log.array.metrics,
                   center = TRUE,
                   scale. = TRUE)

# transform PCs from columns to rows
spike.pc.data <- t(array.pc$x[,1:3])

# Perform Mean-Shift Clustering on PC1 & PC2
options(mc.cores=n.cores) # pass n.cores to mc.cores
spk.clustering <- msClustering(spike.pc.data[1:2,],
                               h=1.5,
                               kernel = "gaussianKernel",
                               multi.core = TRUE)

# Combine wf metric, PC, cluster, voltage, and metadata
node.wf.metrics.pca.clstr <- cbind(
  node.wf.metrics,
  cluster=spk.clustering$labels,
  array.pc$x[,1:3]
  )

# write data to csv
write.csv(node.wf.metrics.pca.clstr, paste0(node,"_","MSclstr.csv"),row.names = FALSE)
