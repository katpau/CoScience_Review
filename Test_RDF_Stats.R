## File to test Forking Path Analysis of the Statistics for Review only
## this is only for testing, since the analysis is done on HUMMEL (UHH
## server) and SLURM (Job scheduler parallelizing across subjects)



# Load Relevant Libraries
list.of.packages <- c("foreach", "dplyr", "tidyr", "stringr", "effectsize", "data.table", "doParallel", "rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)

# Adjust Input here (for shared test only this input works, since other files do not exist)
AnalysisName="Alpha_Context"
ListOfStepFunctionFolders=c("Statistics_All", "Statistics_Alpha_Context")
collumnNamesEEGData=c("ID", "Condition", "Hemisphere", "Electrode", "Localisation", "FrequencyBand", "FrequencyRange", "EEG_Signal", "SME", "Epochs")

# Path of current project
Root = dirname(getSourceEditorContext()$path)
FORKS_File= paste0(Root, "/Only_ForGit_To_TestRun/ForkingFiles/Alpha_Context/StatFORKS.txt") # Usually there are more files and there is a loop here


# Set up Variables based  on Input
RootPath = paste0(Root, "/Only_ForGit_To_TestRun/", AnalysisName , "/")
LogDir = paste0(Root, "/Only_ForGit_To_TestRun/Logs/", AnalysisName , "/Statistics/")
dir.create(LogDir)
LogFile= paste0(LogDir , "Logs_", FORKS_File)
Path_to_Merged_Files = paste0(RootPath,"Group_Data/" )
Path_to_Export = paste0(RootPath,"Stats_Results/" )
if (!dir.exists(Path_to_Export)) {dir.create(Path_to_Export)}

# Add StepFunctions (these include the functions for each step to handle the forking)
ListOfStepFunctionFolders=c("Statistics_All", "Statistics_Alpha_Context")
StepFunctionFolder = paste0(Root, "/Step_Functions/")
ListOfStepFunctionFolders = paste0(StepFunctionFolder, ListOfStepFunctionFolders, "/")

for (iFolder in ListOfStepFunctionFolders) {
  StepFunctions = list.files(iFolder, pattern = ".R", full.names=TRUE)
  for (iFile in StepFunctions) {
    source(iFile)
  }
}



# Read Forking List
FORKS = read.table(FORKS_File,  sep = ";", header = TRUE)


# Create Function to run in Parallel
run_Steps_parallel = function (i_Fork, FORKS, Path_to_Merged_Files, Path_to_Export, Root){
  
    # Added here again so that it can be done in parallel on windows.... -.-
  ListOfStepFunctionFolders=c("Statistics_All", "Statistics_Alpha_Context")
  StepFunctionFolder = paste0(Root, "/Step_Functions/")
  ListOfStepFunctionFolders = paste0(StepFunctionFolder, ListOfStepFunctionFolders, "/")
  
  for (iFolder in ListOfStepFunctionFolders) {
    StepFunctions = list.files(iFolder, pattern = ".R", full.names=TRUE)
    for (iFile in StepFunctions) {
      source(iFile)
    }
  }
  
  
  # Paste Filenames to check if already existing
  filename_input = paste0(Path_to_Merged_Files, "/", FORKS[i_Fork, 1])
  # For Windows Machines paths/file names have a maximum character limit
  # For this test the real naming (including all forking choices) does not work and a shorter path is used.
  filename_FORKS = paste0(Path_to_Export,
                          "Test_", unlist(strsplit(FORKS[i_Fork, 1], "_"))[1], "____",
                          #gsub(".txt", "", FORKS[i_Fork, 1]),
                          FORKS[i_Fork, 2],
                          ".txt")
  
  # Only Run if not already Run before
  if (file.exists(filename_FORKS)) {
    return("Previously Completed") # added to Protocol, ParList, Logging 
  } else {
    # Initiate Data to be parsed to function
    input <- vector(mode = "list", length = 0)
    Step_Names = colnames(FORKS)[3:ncol(FORKS)]
    input$stephistory <- sapply(Step_Names, function(x) NULL)
    input$stephistory["Inputfile"] = filename_input
    input$stephistory["Final_File_Name"] = filename_FORKS
    input$data = read.table(filename_input,  sep = ",", header = FALSE)
    input$stephistory["Root_Behavior"] = paste0(Root, "/Only_ForGit_To_TestRun/BehaviouralData/")
    input$stephistory["Root_Personality"] =  paste0(Root, "/Only_ForGit_To_TestRun/QuestionnaireData/")
    colnames(input$data) = collumnNamesEEGData 
    
    # Run in Try Catch to parse Error Messages to Parloop
    Error_Subjects = tryCatch({
      
      for (iStep in Step_Names) {
        choice = as.character(FORKS[i_Fork, iStep])
        input = do.call(iStep, list(input, choice))
      }
      
      # Save completion status to ParList = Protocol
      return("Newly Completed")
      
    },  # if error ocurrs, save error to Parlist = Protocol
    error = function(e) {
      
      return(paste("Error with Step:", iStep, "and Choice:", FORKS[i_Fork, iStep], ". The error message was: ", e))
    })
    
  } 
}  


# start cluster to run in parallel THIS FORKS/COPIES THIS ENVIRONMENT AND ALL LIBRARIES TO EACH INSTANCE

# for LINUX
# nr_Cores = detectCores()-1
# myCluster  = parallel::makeForkCluster(nr_Cores) 
# registerDoParallel(myCluster)
# # Loop Through list in parallel way
# Protocol = NA
# Protocol = invisible(foreach(i_Fork = 1:nrow(FORKS),
#                              .errorhandling = 'pass',
#                              .combine = 'c') %dopar% run_Steps_parallel(i_Fork, FORKS, Path_to_Merged_Files,  Path_to_Export, Root))
# # Stop Cluster
#  on.exit(stopCluster(myCluster ))

# for WINDOWS 
nr_Cores = detectCores()-1
myCluster = makeCluster(nr_Cores)
registerDoParallel( myCluster)
Protocol = invisible(foreach(i_Fork = 1:nrow(FORKS),
                             .errorhandling = 'pass',
                             .packages = list.of.packages,
                             .combine = 'c') 
                     %dopar% run_Steps_parallel(i_Fork, FORKS, Path_to_Merged_Files,  Path_to_Export, Root))
on.exit(stopCluster(myCluster))



# Create Protocol 
Text_toWrite <- ""
# Get Input
Text_toWrite[1] = "Inputs to Run Forks on Statistic"
Text_toWrite[length(Text_toWrite) + 1] = sprintf('RootPath: %s', RootPath)
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Forking File: %s', FORKS_File)
Text_toWrite[length(Text_toWrite) + 1] = sprintf('RootPath: %s', RootPath)
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Calculation took : %s ', time_needed_forParallel)
Text_toWrite[length(Text_toWrite) + 1] = ""

# Summary
Text_toWrite[length(Text_toWrite) + 1] = "Summary Achievements"
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Number of Combinations to Run: %d', nrow(FORKS))
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Newly Completed : %d', sum(grepl("Newly Completed", Protocol)))
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Previously Completed: %d', sum(grepl("Previously Completed", Protocol)))
Text_toWrite[length(Text_toWrite) + 1] = sprintf('Encountered Errors: %d',sum(grepl("Error", Protocol)))
Text_toWrite[length(Text_toWrite) + 1] = ""
Text_toWrite[length(Text_toWrite) + 1] = ""
Text_toWrite[length(Text_toWrite) + 1] = ""


# Then List individual Errors
Text_toWrite[length(Text_toWrite) + 1] = "List of Errors encountered"
for (iError in 1:length(Protocol)) {
  if (grepl("Error", Protocol[iError]) ) {
    Text_toWrite[length(Text_toWrite) + 1] = sprintf("Path %d. Combination %s%s", iError,  gsub(".txt", "", FORKS[iError, 1]),  FORKS[iError, 2])
    Text_toWrite[length(Text_toWrite) + 1] = Protocol[iError]
  }}


# Save Protocol (this would be saved to file through job schedular. For testing purpose write to file)
# print(Text_toWrite, row.names = FALSE)


file_name = paste0(LogDir, "Test_Log_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S-%Z"), ".txt")
file.create(file_name)
con <- file(file_name, "w")
writeLines(Text_toWrite, con)
close(con)



