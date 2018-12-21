#!/n/app/R/3.4.1/bin/Rscript

#  ****************************************************************************
#  bootstrapCohortAssign
#  Version 1.0
#  ****************************************************************************

#  Joseph Negri 
#  Original version 2018-12-18
#  Copyright is retained and must be preserved. 
#  The work is provided as is; no warranty is provided, and users accept all liability.

#  Script for assigning multiwell MEAs to treatment cohorts based on baseline logHz activity

#  this script accepts a two arugments:
#  * a .csv file 'treatment-samples.csv' containing containing two columns: 'treatment' and 'replicates'
#  detailing the treatment conditions and desired number of replicates.
#  * a .csv file *well_logHz_long.csv, containing the baseline activity. This
#  file is produced by the wfToWellLogHz.R script

#  This script will return:
#  a .csv file 'treatment-map.csv' containing the resulting treatment assignments
#  a .pdf file depicting the spatial layout of the treatment groups across the MEA plate(s)
#  This outputs will be written to the current working directory

#----Load Required Libraries-----
library("data.table", lib.loc="~/R-3.4.1/library")
library("ggplot2", lib.loc="~/R-3.4.1/library")
library("broom", lib.loc = "~/R-3.4.1/library")

#Set seed, this sets the origin of the random number generator, so that random
#samples are reproducible over successive executions of the script
set.seed(1)

# define variables----

# write arguments to args vector
args <- commandArgs(trailingOnly = TRUE)

# number of iterations
bootstrapIterations <- 10000

# exclusion threshold (SD)
exclusionThres <- 2

# define functions----

# population mode
pop.mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# per plate treatment map
per.plate.treat.map <- function(p){
  #Generate figure of treatment_map, called treatment_map_layout, using ggplot
  treatment_map_layout <- ggplot(data=treatment_map[plate.num==p],
                                 aes(x=well_column,y=well_row,
                                     fill=treatment_group)) +
    geom_tile()+
    ggtitle(p)+
    #Define colours to be used in heatmap, ranging from low to high
    scale_fill_grey()+
    #Reverse the order of the y axis, so that A1 appears top-left
    scale_y_discrete(limits=c("H","G","F","E",
                              "D","C","B","A"))+
    scale_x_discrete(limits=c(1:12))+
    theme_bw()
  
  #Call the value 'treatment_map_layout' so that the figure is rendered
  treatment_map_layout
  
  #Save a copy of 'treatment_map_layout' as a pdf in the source directory
  ggsave(
    filename=paste0(Sys.Date(),"_",p,"_treatment-map.pdf"),
    width = 8,
    height = 5,
    units = "in"
    )
  
  return(NULL)
}

# load data----
# load well level data
well.level.all <- (
  fread(
    args[2],
    stringsAsFactors = FALSE)
)

treatment.samples <- 
  fread(
    args[1],
    stringsAsFactors = FALSE
  )

# determine mode of well logHz distribution----
mode.logHz <- pop.mode(round(well.level.all$logHz,1)) # calc mode
sd.logHz <- sd(well.level.all$logHz) # calc SD

# subset active well by SD threshold
well.level.active.all <- well.level.all[logHz>=(mode.logHz-(exclusionThres*sd.logHz))]

# determine treatment groups---- 
treatments <- treatment.samples$treatment

#  define treament groups
num.groups <- uniqueN(treatments)

treatment_group <- 1:num.groups

#  append treatment groups to samples
treatment.samples <- cbind(treatment_group,treatment.samples)

#  define number of replicates per treatment group
num.reps <- treatment.samples$replicates

#  determine number of wells
num.wells <- sum(num.reps)

# Sort well.level dt by descending MFR.well.log.trans
setorder(well.level.active.all,-logHz)

# Select most active num.wells based on MFR.well.log.trans 
exp.wells <- well.level.active.all[,head(.SD,num.wells)]

#Generate a vector containing the number of treatment groups and number of replicates for each treatment group
groups <- Reduce(
  c,lapply(1:length(treatment_group),
           function(x){rep(treatment_group[x],num.reps[x])})
)

#Generate an empty martrix, exp_assignments, to be populated with random assortments of the treatment groups and replicates
#Excute a for loop to generate 10,000 random assignments of the treatment groups, and use these samples to populate the
#exp_assignments matrix
exp_assignments <- replicate(bootstrapIterations,sample(groups),simplify = "array")

#Generate an empty vector, assignment_names, to be populated with assignment column names
#Execute a for loop to generate assignment names for each of the random assortments of the treatment groups
#Assign these assignment names with the formate assignment_XX, as the column names of the matrix exp_assignments
assignment_names <- NULL
for(i in 1:ncol(exp_assignments)) assignment_names[i] <- paste("assignment", i, sep='_')
colnames(exp_assignments) <- assignment_names

#Convert the matrix exp_assignments to a data.table
exp_assignments <- as.data.table(exp_assignments)

exp_assignments <- cbind(exp.wells,exp_assignments)

#  Generate an empty matrix, assignment_Fvalue, to be populated with F-values from generated
#  from one-way ANOVA assessing logHz as a function of treatment group assignment
#  generated from each instance of the random assignment of wells to the prospective cohorts
#  Execute a for loop to perform one-way ANOVA for each of the random assignments. 
assignment_Fvalue <- c()
for (i in 1:length(assignment_names)){
  assignment_Fvalue[i] <-
    tidy(
      aov(
        logHz ~ factor(exp_assignments[[assignment_names[i]]]),
        exp_assignments
      )
    )$statistic[1]
}

# determine the index of the minimum F-value, this number will correspond to the 
# the number of the random assignment
min_variance <- which.min(assignment_Fvalue)

# generation of treatment map----

# compile well data along with assignment (treatment groups) determined to have minimal variance
treatment_map <- exp_assignments[
  ,.(
    well_row,
    well_column,
    plate.num,
    logHz,
    treatment_group=exp_assignments[[assignment_names[min_variance]]]
  )
  ]

# reclassify treatment_group as factor
treatment_map[,treatment_group:=as.factor(treatment_group)]

# generate plate map for each plate
lapply(treatment_map[,unique(plate.num)], per.plate.treat.map)

treatment_map <- merge(treatment_map,
                       treatment.samples[,.(treatment,treatment_group)],
                       by="treatment_group")

#Export the details of the treatment_map as a csv file
write.csv(
  treatment_map,
  file=paste0(Sys.Date(),"_treatment-map.csv"),
  row.names = FALSE
  )
