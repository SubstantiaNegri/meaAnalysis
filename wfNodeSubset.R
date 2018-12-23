#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  wfNodeSubset.R
#  Version 1.3
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2017-07-05
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script for subsetting waveform metrics from MEA recording data
#  by individual electrode 'node' across recordings from a single experiment

#  wf.metrics.csv file containing all of the waveform data from a given experiment
#  with each line representing a single spike event 

# This script will return:
#   n .csv files into a /node subdirectory with each file containing
#   waveform data from a unique node (by plate and well)

# Update 2017-08-31
# Revised waveform threshold to reflect value
# 3X SD background threshold values rather than
# a strict cutoff of >3µV

# Update 2017-10-11
# * eliminated calls to unused libraries
# * enabled parallel processing using parallel::mclapply
# * n.cores added as command line argument

# Update 2018-08-03
# * removed command calling for renaming of 1st column to 'spike'
#   this call is not always accurate

# Update 2018-12-23
# * changed name of the script to wfNodeSubset.R from 
#  MEA_node-wf-subset_v1.3.R  for clarity now
#  that version control is being maintained with git

#  Load Essential Libraries----
# Load the data.table package to enable extended dataframe functions
library("data.table", lib.loc="~/R-3.4.1/library")
library(parallel)

#  Define number of cores----
args <- commandArgs(trailingOnly = TRUE)

# number of logic cores available
n.cores <- args[1]

#  Create subdirectory----
mainDir <- getwd()
subDir <- "node"
dir.create(file.path(mainDir, subDir))

#  Import waveform data----
wf.metrics <- fread(dir(pattern="*wf.metrics.csv"))
#  Remove original spike column (inaccurate), name redundant "V1" column to spike
wf.metrics[,spike:=NULL]
# setnames(wf.metrics,1,"spike")

upper.lim <- wf.metrics[,mean(SD)]+(3*wf.metrics[,sd(SD)])
wf.metrics <- wf.metrics[SD<=upper.lim]

#  Add node id----
wf.metrics[,node_ID:=paste0(plate.num,"_",well_row,well_column,"_",array_x,array_y)]

unique.nodes <- unique(wf.metrics$node_ID)

#  subset wf.metrics based on unique node----
mclapply(unique.nodes,
       function(x){
         subset.wf <- wf.metrics[node_ID==x]
         fwrite(subset.wf,file = paste0("node/",x,".csv"),row.names = FALSE)
         return(NULL)
       },
       mc.cores = n.cores)
