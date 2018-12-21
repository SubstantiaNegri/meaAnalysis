#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  wfToWellLogHz
#  Version 1.0
#  Original version 2018-01-03
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2018-01-03
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script processes waveform level data to calculate well level spike frequencies
#  the script should be executed with a directory contaning a exp.wf.metrics.csv file
#  with is the output of the spkWaveform script

#  This script requires 1 argument, the duration of the recordings in seconds (e.g. 1800 for 30min)
#  assumptions for the script are: 
#  * the exp.wf.metrics.csv file contains all of the waveforms from a given experiment
#  * all recordings are of same duration, provided as trailing argument in seconds

#  The will return two .csv files containing a single line for each well containing:
#  * plate.num
#  * well row
#  * well column
#  * wellID (concatenation plate number, well row, and well colum)
#  * rec (recording)
#  * logHz (spikes/sec or recording)
#  the two files will be in either long-form, or wide-form with respect to recordings


#  Load Essential Libraries----
library("data.table", lib.loc="~/R-3.4.1/library")

args <- commandArgs(trailingOnly = TRUE)

durationSec <- as.numeric(args[1])

#  Global functions----
#  fuction to convert NA values to min MFR
dt.na.to.min <- function(DT){
  #by name :
  for (j in names(DT))
    set(DT,which(is.na(DT[[j]])),j,log10(1/durationSec))
}

#  Import waveform data----
wfMetrics <- fread(
  dir(pattern="wf.metrics.csv"),
  stringsAsFactors = FALSE)
#  Remove original spike column (inaccurate)
wfMetrics[,spike:=NULL]

#  Filter for spikes recorded by low-background electrodes----
#  Calculate logHz for each well and recording
#  if statement catch for if rec 00 is encoded as character or numeric
upperLimit <- wfMetrics[rec=="00"][,mean(SD)]+(3*wfMetrics[,sd(SD)])

if(is.na(upperLimit)){
  (upperLimit <- wfMetrics[rec==0][,mean(SD)]+(3*wfMetrics[,sd(SD)]))
  }

#  If dataset does not include rec 00, calculate upperLimit
#  from entire recording set
if(is.na(upperLimit)){
  (upperLimit <- wfMetrics[,mean(SD)]+(3*wfMetrics[,sd(SD)]))
}

wellLevelData <- wfMetrics[SD<=upperLimit,.(totalSpikes=length(V1)),
                               by=.(plate.num,well_row,well_column,rec)]

wellLevelData[,`:=`(
  #MFR.well=(totalSpikes/durationSec), calc. of MFR.well (linear scale), not used at this time
  logHz=log10((totalSpikes+1)/durationSec)
  )]
wellLevelData[,wellID:=paste0(plate.num,"_",well_row,well_column)]

#  Generate wide-form of logHz data ----
#  exposes 'gaps' in well-level data, for wells included in treatment
#  but for whom there is no activity (no spikes) in a subsequent recording

wellLogHzWide <- dcast.data.table(
  wellLevelData,
  plate.num + well_row + well_column + wellID ~ rec,
  value.var = "logHz")

# apply dt.na.to.min to apply nominal activity (equivalent of 1 spike) to those wells
dt.na.to.min(wellLogHzWide)

#  write wellLevelData.logHz.wide to csv----
write.csv(
  wellLogHzWide,
  paste(Sys.Date(),"well_logHz_wide.csv", sep = "_")
)

#  Covert wide-form back to long-form----
#  now with any 'gaps' filled
wellLogHzLong <- melt.data.table(
  wellLogHzWide,
  id.vars = c("plate.num", "well_row", "well_column", "wellID"),
  variable.name = "rec",
  variable.factor = FALSE,
  value.name = "logHz"
)

#  write wellLogHzLong to csv----
write.csv(
  wellLogHzLong,
  file = paste(Sys.Date(),"well_logHz_long.csv",sep = "_"),
  row.names = FALSE
)
