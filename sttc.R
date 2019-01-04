#!/n/app/R/3.4.1/bin/Rscript

# *****************************************************************************
# sttc.R
# version 1.0
# original version 2018-11-05
# calculation of spike time tiling coefficient (STTC)
# *****************************************************************************

#  Joseph Negri 
#  Original version 2018-11-03
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script calculates the spike time tiling coefficient (STTC)
#  between spike trains of single-unit/neurons in a pairwise fashion
#  from sorted waveforms of MEA recordings 

#  This script requires 9 arguments, 
#  * wellID in which
#  * clusterA id
#  * clusterB id
#  * recNum, recording instance from experiment
#  * Tinitial, initial time for assessing spike trains, value in seconds
#  * recDur, duration of recording that spike trains are being assessed, value in seconds
#  * DeltaT, interval around each spike event during which correlated spikes should occurr
#  * revised clusterd waveform file, file containing information of timing,
#    location, and cluster membership of each firing event. Revised from original
#    clustered waveform data to remove momentary voltage recordings
#  * outputFile, file to write calculated sttc for each pairwise comparison

# Update 2018-12-20
# * added revised (voltage data removed) clustered waveform file as argument

# Update 2019-01-03
# * corrected error in the sttc calculation, replaced Pa term with correct Ta term
# libraries----
library("data.table", lib.loc="~/R-3.4.1/library")

# variables----

args <- commandArgs(trailingOnly = TRUE)

wellID <- args[1]
clusterA <- args[2]
clusterB <- args[3]
recNum <- as.numeric(args[4])
Tinitial <- as.numeric(args[5])
recDur <- as.numeric(args[6])
DeltaT <- as.numeric(args[7])
clusteredWFfile <- as.character(args[8])
outputFile <- as.character(args[9])

# functions----

decimalplaces <- function(x) {
  smallestDecimal = .Machine$double.eps^0.5 #small decimal comp can calc 
  if (abs(x - round(x)) > smallestDecimal) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed = TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}

sttcCalc <- function(clusterA,clusterB,recNum,DeltaT){
  # determine number of cluster A events within
  # recording and time interval
  clusterA.N <- 
    # clusteredWFs[time>Tinitial & time<(Tinitial+recDur)][
    #   nodeCluster==clusterA & rec==recNum,.N]
    clusteredWFs[time>Tinitial & time<(Tinitial+recDur) & 
        nodeCluster==clusterA & rec==recNum,.N]
  # determine timing of cluster A events within
  # recording and time interval
  clusterA.time <- 
    clusteredWFs[time>Tinitial & time<(Tinitial+recDur) &
      nodeCluster==clusterA & rec==recNum,time]
  clusterA.time <- clusterA.time - Tinitial
  clusterA.tic <- clusterA.time - DeltaT
  clusterA.toc <- clusterA.time + DeltaT
  
  clusterA.ticToc <-
    rbindlist(
      list(
        data.table(
          time = clockTicks,
          stateChange = 0
        ),
        data.table(
          time = clusterA.tic,
          stateChange = 1
        ),
        data.table(
          time = clusterA.toc,
          stateChange = -1
        )
      ),
      use.names = TRUE
    )
  #round to 10X resolution of DeltaT
  clusterA.ticToc[,time:=round(time,DeltaTprecision+1)]
  clusterA.ticToc <-
    clusterA.ticToc[,.(stateChange=sum(stateChange)),time]
  
  setorder(clusterA.ticToc, time)
  
  clusterA.runSum <- c()
  for(i in 1:clockTicksN){
    clusterA.runSum[i] <-
      sum(clusterA.ticToc$stateChange[1:i])
  }
  
  clusterA.ticToc[,runSum:=clusterA.runSum]
  
  Ta <- clusterA.ticToc[runSum>0,.N]/clockTicksN
  
  # determine number of cluster B events within
  # recording and time interval
  clusterB.N <- 
    clusteredWFs[time>Tinitial & time<(Tinitial+recDur) &
      nodeCluster==clusterB & rec==recNum,.N]
  # determine timing of cluster B events within
  # recording and time interval
  clusterB.time <- 
    clusteredWFs[time>Tinitial & time<(Tinitial+recDur) &
      nodeCluster==clusterB & rec==recNum,time]
  clusterB.time <- clusterB.time - Tinitial
  clusterB.tic <- clusterB.time - DeltaT
  clusterB.toc <- clusterB.time + DeltaT
  
  clusterB.ticToc <-
    rbindlist(
      list(
        data.table(
          time = clockTicks,
          stateChange = 0
        ),
        data.table(
          time = clusterB.tic,
          stateChange = 1
        ),
        data.table(
          time = clusterB.toc,
          stateChange = -1
        )
      ),
      use.names = TRUE
    )
  #round to 10X resolution of DeltaT
  clusterB.ticToc[,time:=round(time,DeltaTprecision+1)]
  clusterB.ticToc <-
    clusterB.ticToc[,.(stateChange=sum(stateChange)),time]
  
  setorder(clusterB.ticToc, time)
  
  clusterB.runSum <- c()
  for(i in 1:clockTicksN){
    clusterB.runSum[i] <-
      sum(clusterB.ticToc$stateChange[1:i])
  }
  
  clusterB.ticToc[,runSum:=clusterB.runSum]
  
  Tb <- clusterB.ticToc[runSum>0,.N]/clockTicksN
  
  Pa <- sum(clusterA.time %in% clusterB.ticToc[runSum>0,time])/clusterA.N
  
  Pb <- sum(clusterB.time %in% clusterA.ticToc[runSum>0,time])/clusterB.N
  
  STTC <- 0.5*((Pa-Tb)/(1-Pa*Tb)+(Pb-Ta)/(1-Pb*Ta))
  return(STTC)
}

# main----

# determine number of decimal place in DeltaT
DeltaTprecision <- decimalplaces(DeltaT)

# generate clock ticks at 10X resolution of DeltaT
clockTicks <- seq(0,recDur,10^(-DeltaTprecision-1))
clockTicksN <- length(clockTicks)

# load data---

clusteredWFs <-
  fread(
    clusteredWFfile
  )

sttc <- sttcCalc(clusterA, clusterB, recNum, DeltaT)

sttcDT <-
  data.table(
    wellID,
    clusterA,
    clusterB,
    recNum,
    sttc
  )

fwrite(
  sttcDT,
  outputFile,
  append = TRUE
)
