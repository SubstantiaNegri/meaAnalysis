#!/n/app/R/3.4.1/bin/Rscript

# *****************************************************************************
# sttcSim.R
# version 1.0
# original version 2019-01-09
# simulation of spike time tiling coefficient (STTC) calculation
# *****************************************************************************

#  Joseph Negri 
#  Original version 2019-01-09
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script calculates the spike time tiling coefficient (STTC)
#  between simulated spike trains of single-unit/neurons in a pairwise fashion
#  from sorted waveforms of MEA recordings 
#  The output of this script can be used to determine thresholds of 
#  emperically determined STTC values that are likely to respond
#  to functional network edges

#  This script requires 6 arguments
#  * clusterA - number of events in the A cluster
#  * clusterB - number of events in the A cluster
#  * recDur - duration of recording being simulated, value in seconds
#  * recNum, recording instance from experiment
#  * DeltaT, interval around each spike event during which correlated spikes should occur
#  * iterations, number of iterations of STTC calculation to perform
#  * outputFile, file to write calculated sttc for each pairwise comparison

# libraries----
library("data.table", lib.loc="~/R-3.4.1/library")

# variables----

args <- commandArgs(trailingOnly = TRUE)

clusterA <- as.numeric(args[1])
clusterB <- as.numeric(args[2])
recDur <- as.numeric(args[3])
DeltaT <- as.numeric(args[4])
iterations <- as.numeric(args[5])
outputFile <- args[6]

# functions----
decimalplaces <- function(x) {
  smallestDecimal = .Machine$double.eps^0.5 #small decimal comp can calc 
  if (abs(x - round(x)) > smallestDecimal) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed = TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}

sttcSimCalc <- function(clusterA,clusterB,DeltaT){
  # determine number of cluster A events
  clusterA.N <- 
    clusterA
  # generate timing of cluster A events 
  # by sampling clockTicks
  clusterA.time <- 
    sample(clockTicks,clusterA.N,replace = FALSE)
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
  
  clusterA.ticToc[,runSum:=cumsum(stateChange)]
  
  Ta <- clusterA.ticToc[runSum>0,.N]/clockTicksN
  
  # determine number of cluster B events=
  clusterB.N <- 
    clusterB
  # generate timing of cluster B events events
  # by sampling clockTicks
  clusterB.time <- 
    sample(clockTicks,clusterB.N,replace = FALSE)
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
  
  clusterB.ticToc[,runSum:=cumsum(stateChange)]
  
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

# generate table to populate
sttcSim <- 
  data.table(
    clusterA=rep(clusterA,iterations),
    clusterB=rep(clusterB,iterations),
    DeltaT=rep(DeltaT,iterations),
    sttc=rep(0,iterations)
    )

# run iterations of STTC simulations
for(i in 1:iterations){
  sttcSimValue = sttcSimCalc(clusterA,clusterB,DeltaT)
  sttcSim[i,sttc:=sttcSimValue]
}

# append to output file
fwrite(
  sttcSim,
  outputFile,
  append = TRUE
)
