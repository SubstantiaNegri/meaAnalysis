#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  activeClusterPairs
#  Version 1.0
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2018-12-18
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script determining spike clusters detected during MEA recordings that are
#  active within the same array and recording instances

#  this script accepts a one arugments:
#  * a 'wf.metrics.clustered.revised.csv' generated by the clusterFileRevision.R
#  script containing time and location data of firing events clustered by mean-shift
#  or similar technique. This clustering should have been done without
#  subsetting so all firing instances are present.

#  This script will return:
#  two .csv files 'allClusterPairs.csv' and  activeClusterPairs.csv.
#  The former contains all cluster pairs and is useful for graphing purposes,
#  the later contains pairs both active during a recording is useful for
#  calculating spike time tiling coefficients (STTC).

#  Update 2019-01-03:
#  *added functionality to exclude instances of wells represented by a 
#   single cluster, which was causing the script to fail.
#  *changed call to 'sapply' to 'lapply' to address separate error.

# libraries----
library("data.table", lib.loc="~/R-3.4.1/library")

# variables----

# write arguments to args vector
args <- commandArgs(trailingOnly = TRUE)

spikeThres <- 10

# load data---

clusteredWFs <-
  fread(
    args[1]
  )

# main----

# define vector of recodings
uniqueRec <- sort(unique(clusteredWFs$rec))

# table of clusters active within well and recording
activeClusters <-
  clusteredWFs[,.N,.(nodeCluster,wellID,rec)][N>=spikeThres]

setorder(activeClusters,wellID,nodeCluster,rec)

# exclude instances of wells with single cluster
singleClusterWell <- activeClusters[,uniqueN(nodeCluster),by=wellID][V1<2,wellID]
activeClusters <- activeClusters[!wellID %in% singleClusterWell]

# generate pairwise comparisons of all clusters within well
activeClustersPairwiseMatrix <-
  do.call(
    rbind,
    lapply(
      unique(activeClusters$wellID),
      function(x){
        return(
          cbind(
            x,
            t(
              combn(
                activeClusters[wellID==x,unique(nodeCluster)],
                2
              )
            )
          ) 
        ) 
      }
    )
  )

# generate pairwise comparisons of all clusters within well, with
# an instance for each recording
pairwiseWellClusterRec <-
  do.call(
    rbind.data.frame,
    lapply(
      uniqueRec,
      function(x){
        do.call(
          rbind.data.frame,
          lapply(
            1:nrow(activeClustersPairwiseMatrix),
            function(y){
              return(
                t(
                  c(
                    activeClustersPairwiseMatrix[y,],
                    x
                  )
                )
              )
            }
          )
        )
      }
    )
  )

colnames(pairwiseWellClusterRec) <-
  c(
    "wellID",
    "clusterA",
    "clusterB",
    "rec"
  )

pairwiseWellClusterRec$rec <-
  as.numeric(
    as.character(
      pairwiseWellClusterRec$rec
    )
  )

# generate vector representing rows of pairwiseWellClusterRec
# in which both clusters were 'active' during a given recording
instancesActiveClusterPairs <-
  sapply(
    1:nrow(pairwiseWellClusterRec),
    function(i){
      rec.i = pairwiseWellClusterRec[i,"rec"]
      cA.i = pairwiseWellClusterRec[i,"clusterA"]
      cB.i = pairwiseWellClusterRec[i,"clusterB"]
      line.i = ifelse(
        activeClusters[rec==rec.i,cA.i %in% nodeCluster],
        ifelse(
          activeClusters[rec==rec.i,cB.i %in% nodeCluster],
          i,
          0
        ),
        0
      )
      return(line.i)
    }
  )

# subset only those instances in which both clusters are active
activeClusterPairs <-
  pairwiseWellClusterRec[instancesActiveClusterPairs,]

fwrite(
  pairwiseWellClusterRec,
  file = paste0(Sys.Date(),"_allClusterPairs.csv"),
  col.names = TRUE
)

fwrite(
  activeClusterPairs,
  file = paste0(Sys.Date(),"_activeClusterPairs.csv"),
  col.names = FALSE
)
