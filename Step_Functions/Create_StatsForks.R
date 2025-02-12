# Information on Step Functions and Analysis
args=commandArgs(trailingOnly = TRUE)
AnalysisName = gsub("'", "", args[1])

# AnalysisName = "Error_Perfectionism"
ListOfStepFunctionFolders = c("Statistics_All", paste0("Statistics_", AnalysisName))
RootFolder_home = "/home/bay2875/"
RootFolder_work = "/work/bay2875/"



# Get Packages
list.of.packages <- c("foreach", "dplyr", "tidyr", "stringr", "effectsize", "data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
lapply(list.of.packages, require, character.only = TRUE)

# Get Last Step depending on input
if (AnalysisName =="GoNoGo_Conflict") {
  PreviousStep = 22 
  SeedCheck = 1
Other_Main = NA

} else if (AnalysisName == "Alpha_Resting") {
 PreviousStep = 21 
 SeedCheck = 2
Other_Main = c("_16.1", "_16.2")


} else if (AnalysisName == "Flanker_Conflict") {
  PreviousStep = 20
  SeedCheck = 3
Other_Main = NA

} else if (AnalysisName == "Ultimatum_Offer") {
  PreviousStep = 21 
  SeedCheck = 4
Other_Main = NA


} else if (AnalysisName == "Gambling_RewP") {
  PreviousStep = 21 
  SeedCheck = 5
Other_Main = NA

} else if (AnalysisName == "Gambling_N300H") {
  PreviousStep = 23
  SeedCheck = 6
Other_Main = NA

} else if (AnalysisName == "Error_MVPA") {
  PreviousStep = 16
  SeedCheck = 7
Other_Main = NA

} else if (AnalysisName == "Error_GMA") {
  PreviousStep = 20
  SeedCheck = 7
Other_Main = NA

} else if (AnalysisName == "Error_Perfectionism") {
  PreviousStep = 22
  SeedCheck = 7
Other_Main = NA
  
}  else if (AnalysisName == "Alpha_Context") {
  PreviousStep = 20
  SeedCheck = 8
 Other_Main = c("_15.1", "_15.2")

} else if (AnalysisName == "Flanker_Error") {
  PreviousStep = 22
  SeedCheck = 8
 Other_Main = NA}



#######################################################################

# Setup Folders
ForkingFunctions = paste0(RootFolder_home, "ForCompiling/Analysis_Functions/Forking_FunctionsR/Forking_Functions.R")
StepFunctionFolder = paste0(RootFolder_home, "ForCompiling/Step_Functions/")
ListOfStepFunctionFolders_full = paste0(StepFunctionFolder, ListOfStepFunctionFolders,"/")

ExportPath =paste0(RootFolder_home, "/ForkingFiles/", AnalysisName,"/")
PreprocGroupPath =paste0(RootFolder_work, AnalysisName, "/Group_Data/")
Combinations_Preproc = list.files(PreprocGroupPath)


# Get Functions
source(ForkingFunctions)

# Get Design from Step-Functions
design = source_Design(ListOfStepFunctionFolders_full)

# Combine All Possible Statistic Forks (add highest number of PreprocStep)
Forks_Table = combine_Choices(design, PreviousStep)

# Take Subset from StatCombinations to match Nr of PreprocCombinations
set.seed(SeedCheck)
Subset = sample(1:nrow(Forks_Table), length(Combinations_Preproc))
Subset  = sort(unique(c(1, Subset)))
Forks_Table = Forks_Table[Subset,]


# Prepare FileName
Combination_Name = apply(Forks_Table, 2, function(col)
    as.numeric(format(
      factor(
        col,
        levels = unique(col),
        labels = 1:length(unique(col))
      )
    )))



#Create Output Numbering
Forks_Nr = ""
for (i_Step in 1:ncol(Combination_Name)) {
Forks_Nr = paste0(Forks_Nr,
                              "_",
                               i_Step + PreviousStep,
                               ".",
                               Combination_Name[, i_Step])
 }





 

OUTPUT = cbind(c(Combinations_Preproc[1],
	             Combinations_Preproc),
               Forks_Nr,
               Forks_Table)
names(OUTPUT)[1:2] = c("InputNumber", "CombinationNumber")

Main_Forks_Nr = Forks_Nr[1]
Main_Forks_Table = Forks_Table[1,]

MainPath = cbind(Combinations_Preproc[1], Main_Forks_Nr, Main_Forks_Table)
colnames(MainPath) = colnames(OUTPUT)
if (all(!is.na(Other_Main))) {
MainPath2 = MainPath
MainPath2[,1] = gsub(Other_Main[1], Other_Main[2], MainPath[,1])
OUTPUT = rbind( MainPath2, OUTPUT )

} 




  filename = paste0(ExportPath, "/FORKS_Stat.txt")
  write.table(
    OUTPUT,
    filename,
    sep = ";",
    row.names = FALSE,
    col.names = TRUE
  )


  filename = paste0(ExportPath, "/FORKS_Stat_Main.txt")
  write.table(
    MainPath,
    filename,
    sep = ";",
    row.names = FALSE,
    col.names = TRUE
  )
if (all(!is.na(Other_Main))) {
  filename = paste0(ExportPath, "/FORKS_Stat_Main2.txt")
  write.table(
    MainPath,
    filename,
    sep = ";",
    row.names = FALSE,
    col.names = TRUE
  )
}

