#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  MEA spike-wf-metrics
#  Version 1.4
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2017-04-05
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script for compiling waveform metrics from MEA recording data
#  performed using Axion Biosciences instrumentation

#  This script inputs a volt.csv SD.csv per electrode and recording
#  the volt.csv is a [38,X] matrix where each row represent a voltage reading
#  and each column represents an individual spike event. SD.csv is a list
#  detailing the crossing-threshold voltage corresponding to 5.5 SD of the RMS
#  for each spike event

# This script will return:
#   - csv file detailing a single spike event per line
#   including the 38 momentary voltage recordings, the voltage corresponding to
#   the 5.5 SD crossing-threshold for spike detection, 
#   as well as recording meta-data 

# Update 2017-08-31

# script updated to incorporate an additional input time.csv per
# electrode. time.csv is a list of timestamps denoting the time in
# seconds when the spike event occurred within the recording.

# Update 2017-10-05

# **changed lib.loc to reflect R version 3.4
# **eliminated calls to unused libraries
# **enabled parallel processing using parallel::mclapply

# Update 2018-01-12

# Changed manner in which analyzed data is written to output file.
# Convert from write.csv to fwrite. Also, employ 'append' option
# in fwrite, so that data from each node is written out once completed
# and data from all nodes does not need to be held in memory to be
# written all at once.

# Update 2018-01-16

# Changes implemented 2018-01-12 recinded for the time being
# while addressing issues of duplication of outputs with writing 
# to output within mclapply loop
#
# instead code stripped down to run in 'embarrassingly parallel' fashion
# with a single job submitted for each electrode volt/SD/time file
# output is a wfMetrics.csv file for each electrode that will need to be
# aggregated

#  Load Essential Libraries----
library("data.table", lib.loc="~/R-3.4.1/library")
library("geepack", lib.loc="~/R-3.4.1/library")
library("geeM", lib.loc="~/R-3.4.1/library")
library("MESS", lib.loc="~/R-3.4.1/library")

#  Define Variables----
args <- commandArgs(trailingOnly = TRUE)

# set seed
set.seed(1)

#  Main----

# Generate dt of voltage array files, and parse filenames for 
# recording, plate, well, and node identifiers
files <- data.table(
  volt.file=args[1], # volt.csv file 
  SD.file=args[2],# SD.csv file 
  time.file=args[3]# time.csv file 
)

files[,plate.num:=strsplit(volt.file,"_")[[1]][1],by=volt.file]
files[,rec:=strsplit(volt.file,"_")[[1]][2],by=volt.file]
files[,well_row:=LETTERS[as.numeric(strsplit(volt.file[1],"_")[[1]][3])],by=volt.file]
files[,well_column:=as.numeric(strsplit(volt.file,"_")[[1]][4]),by=volt.file]
files[,array_x:=as.numeric(strsplit(volt.file,"_")[[1]][5]),by=volt.file]
files[,array_y:=as.numeric(strsplit(volt.file,"_")[[1]][6]),by=volt.file]
files[,rec.node:=paste0(rec,"_",plate.num,"_",well_row,well_column,"_",array_x,array_y),by=volt.file]

# name output file
outputFile <- paste(
  files$plate.num,
  files$rec,
  files$well_row,
  files$well_column,
  files$array_x,
  files$array_y,
  "wfMetrics.csv",
  sep = "_"
  )

    # capture plate and rec meta-data
    plate.num <- files$plate.num
    rec <- files$rec
    well_row <- files$well_row
    well_column <- files$well_column
    array_x <- files$array_x
    array_y <- files$array_y
    
    # import volt data
    volt.array <- as.matrix(read.csv(files$volt.file, header = FALSE))
    
    # Multiply this matrix by 10^6 to convert values from V to uV
    volt.array.uV <- volt.array*1000000
    
    # Save the number of rows in this large matrix as a variable
    # This should be equal to 38 for default Axis recording settings
    nrow.volt <- nrow(volt.array.uV)
    
    # Remove the original voltage matrix to conserve memory
    rm(volt.array)
    
    # Calculate waveform parameters for each spike
    peak <- apply(volt.array.uV,2,max)
    valley <- abs(apply(volt.array.uV,2,min))
    peak.valley <- peak+valley
    auc <- apply(volt.array.uV,2,
                 function(x){
                   auc(1:38,x, type = 'linear', absolutearea = TRUE)
                 }
    )
    pvi <- apply(volt.array.uV,2,
                 function(x){
                   abs(which.max(x)-which.min(x))
                 }
    )
    NLE.max <- apply(volt.array.uV,2,
                     function(x){
                       max(x[2:(nrow.volt-1)]^2-(x[1:(nrow.volt-2)]*x[3:nrow.volt]))
                     }
    )
    
    SD.array <- as.matrix(read.csv(files$SD.file, header = FALSE))
    
    time.array <- as.matrix(read.csv(files$time.file, header = FALSE))
    
    # Transpose the volt.array.uV matrix, so that voltage recordings from
    # each spike event are placed in adjacent columns
    volt.array.uV <- t(volt.array.uV)
    
    # Transpose SD.array and time.array so that each spike is represented 
    # as a row rather than column
    SD.array <- t(SD.array)
    time.array <- t(time.array)
    
    # combine calculated metrics, SD, and time into data.table
    array.metrics.dt <- data.table(cbind(peak,valley,peak.valley,pvi,auc,NLE.max,SD.array,time.array))
    colnames(array.metrics.dt) <- c("peak","valley","peak.valley","pvi","auc","NLE.max","SD","time")
    array.metrics.dt[,spike:=1:nrow(array.metrics.dt)]
    setkey(array.metrics.dt,spike)
    
    # convert volt.array.uV into data.table
    volt.array.uV <- data.table(volt.array.uV)
    volt.array.uV[,spike:=1:nrow(volt.array.uV)]
    setkey(volt.array.uV,spike)
    
    # combine waveform metrics and voltage data into single dt
    array.metrics.volt.dt <- array.metrics.dt[volt.array.uV]
    
    # add plate, rec meta-data
    array.metrics.volt.dt[,
                          `:=`(
                            plate.num=plate.num,
                            well_row=well_row,
                            well_column=well_column,
                            array_x=array_x,
                            array_y=array_y,
                            rec=rec
                          )]
    
    # write data to out to csv
    fwrite(
      array.metrics.volt.dt,
      file = outputFile,
      #append = TRUE,
      sep = ",",
      row.names = FALSE,
      col.names = TRUE
    )
