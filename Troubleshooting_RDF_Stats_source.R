######################################################################################################################
# No Changes below!!


# Load Relevant Libraries
list.of.packages <- c("foreach", "dplyr", "tidyr", "stringr", "effectsize", "data.table", "doParallel", "rstudioapi", "lme4", "lmerTest")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)


if (AnalysisName == "Alpha_Context") {
  collumnNamesEEGData=c("ID", "Condition", "Hemisphere", "Electrode", "Localisation", "FrequencyBand", "FrequencyRange", "EEG_Signal", "SME", "Epochs")
} else if (AnalysisName == "Alpha_Resting") {
  collumnNamesEEGData=c("ID", "Task", "Hemisphere", "Electrode", "Localisation", "FrequencyBand", "FrequencyRange", "EEG_Signal", "SME", "Epochs", "Lab", "Experimenter")
} else if (AnalysisName == "GoNoGo_Conflict") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Condition", "Electrode", "TimeWindow",  "EEG_Signal", "SME", "Epochs", "Component", "ACC")
} else if (AnalysisName == "Flanker_Conflict") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Congruency", "Electrode", "TimeWindow",  "EEG_Signal", "SME", "Epochs", "Component", "ACC")
} else if (AnalysisName == "Ultimatum_Offer") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Offer", "Electrode", "TimeWindow",  "EEG_Signal", "SME", "Epochs", "Component")
} else if (AnalysisName == "Gambling_RewP") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Condition", "Electrode", "TimeWindow",  "EEG_Signal", "SME", "Epochs", "Component")
} else if (AnalysisName == "Gambling_N300H") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Condition", "Electrode", "TimeWindow",  "TimeWindowECG", "EEG_Signal", "SME", "Epochs", "Bin", "Component")
} else if (AnalysisName == "Error_MVPA") {
  collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Condition", "Task", "EEG_Signal", "SME",  "Component", "Epochs", "ACC")
} 


# Path of current project
Root = dirname(getSourceEditorContext()$path)


FORKS_File= paste0(Root, "/Only_ForGit_To_TestRun/ForkingFiles/", AnalysisName, "/StatFORKS.txt") # Usually there are more files and there is a loop here

RootPath = paste0(Root, "/Only_ForGit_To_TestRun/Preproc_forked/", AnalysisName , "/")
LogDir = paste0(Root, "/Only_ForGit_To_TestRun/Logs/", AnalysisName , "/Statistics/")
if (!dir.exists(LogDir)) {dir.create(LogDir)}
LogFile= paste0(LogDir , "Logs_", FORKS_File)
Path_to_Merged_Files = paste0(RootPath,"Group_Data/" )
Path_to_Export = paste0(RootPath,"Stats_Results/" )
if (!dir.exists(Path_to_Export)) {dir.create(Path_to_Export)}

# Add StepFunctions (these include the functions for each step to handle the forking)
ListOfStepFunctionFolders=c("Statistics_All", paste0("Statistics_", AnalysisName))
StepFunctionFolder = paste0(Root, "/Step_Functions/")
ListOfStepFunctionFolders = paste0(StepFunctionFolder, ListOfStepFunctionFolders, "/")

for (iFolder in ListOfStepFunctionFolders) {
  StepFunctions = list.files(iFolder, pattern = ".R", full.names=TRUE)
  for (iFile in StepFunctions) {
    source(iFile)
  }
}

# Add Function For Testing Hypotheses
StepFunctions = list.files(paste0(Root, "/Analysis_Functions/Forking_FunctionsR/"), pattern = ".R", full.names=TRUE)
for (iFile in StepFunctions) {
  source(iFile)
}

# Read Forking List
FORKS = read.table(FORKS_File,  sep = ";", header = TRUE)


# load data
filename_input = paste0(Path_to_Merged_Files, "/", FORKS[i_Fork, 1])
# For Windows Machines paths/file names have a maximum character limit
# For this test the real naming (including all forking choices) does not work and a shorter path is used.
filename_FORKS = paste0(Path_to_Export,
                        "Test_", unlist(strsplit(FORKS[i_Fork, 1], "_"))[1], "____",
                        #gsub(".txt", "", FORKS[i_Fork, 1]),
                        FORKS[i_Fork, 2],
                        ".txt")
input <- vector(mode = "list", length = 0)
Step_Names = colnames(FORKS)[3:ncol(FORKS)]
input$stephistory <- sapply(Step_Names, function(x) NULL)
input$stephistory["Inputfile"] = filename_input
input$stephistory["Final_File_Name"] = filename_FORKS
input$data = read.table(filename_input,  sep = ",", header = FALSE)
input$stephistory["Root_Behavior"] = paste0(Root, "/Only_ForGit_To_TestRun/BehaviouralData/")
input$stephistory["Root_Personality"] =  paste0(Root, "/Only_ForGit_To_TestRun/QuestionnaireData/", AnalysisName, "/")
colnames(input$data) = collumnNamesEEGData 



for (iFolder in ListOfStepFunctionFolders) {
  StepFunctions = list.files(iFolder, pattern = ".R", full.names=TRUE)
  for (iFile in StepFunctions) {
    source(iFile)
  }
}

Prepared_input = input
print("*********************")
print("All Steps that can be tested (in order):")
print(Step_Names)
print("*********************")