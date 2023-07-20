## File to test Forking Path Analysis of the Statistics for Review only
## (1) Prepares all files, adds relevant functions
## (2) Section to run each step separately
# how to? Run Section 1 - no changes, then go to section (2)

######################################################################################################################
# Run as it is - only possible change => line 50 to test a different input
# (1) Prepares all files, adds relevant functions
AnalysisName="Flanker_Conflict"   

# Load Relevant Libraries
list.of.packages <- c("foreach", "dplyr", "tidyr", "stringr", "effectsize", "data.table", "doParallel", "rstudioapi", "lme4", "lmerTest")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)
collumnNamesEEGData=c("ID", "Lab", "Experimenter",  "Congruency", "Electrode", "TimeWindow",  "EEG_Signal", "SME", "Epochs", "Component", "ACC")

# Path of current project
Root = dirname(getSourceEditorContext()$path)
Root = gsub("Testing_Scripts", "", Root)

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

# Get Design of Forks
source(paste0(Root,"Analysis_Functions/Forking_FunctionsR/Forking_Functions.R"))
Design_Stats = source_Design(ListOfStepFunctionFolders)
                             
# Initiate Data to be parsed to function
input_init <- vector(mode = "list", length = 0)
Step_Names = names(Design_Stats)
input_init$stephistory <- sapply(Step_Names, function(x) NULL)
Prepared_Group_Files = list.files(paste0(Root, "/Only_ForGit_To_TestRun/Preproc_forked/", AnalysisName, "/Group_Data/"),
                                  full.names = TRUE)
input_init$stephistory["Inputfile"] = Prepared_Group_Files[1] ## <=== COULD BE CHANGED TO HAVE DIFFERENT TESTS
input_init$stephistory["Final_File_Name"] = paste0(Root, "/Only_ForGit_To_TestRun/Preproc_forked/", AnalysisName, "/Test.csv")
input_init$stephistory["Root_Behavior"] = paste0(Root, "/Only_ForGit_To_TestRun/BehaviouralData/")
input_init$stephistory["Root_Personality"] =  paste0(Root, "/Only_ForGit_To_TestRun/QuestionnaireData/", AnalysisName, "/")

input_init$data = read.csv(input_init$stephistory[["Inputfile"]],  sep = ",", header = FALSE)
colnames(input_init$data) = collumnNamesEEGData 


########################################################
# (2) Section to run each step separately

# The comments list all possible alternatives, with the first option being
#              the main path
# Each call represents one preprocessing step and can be run separately
# The lines call the respective "Step Function". These can be viewed by
#              entering >> View(Outliers_SME) etc.
# Each step function takes two inputs, input = list including data and information 
#              on analysis, and choice = the forking choice/option
# To Test, run all steps before the test of interest. Then go to that source code
# and let it run line by line
# Important: The Variable input is constantly overwritten in this example.
#            If you want to compare before and after, you need to rename
#            the variables or create a copy.
# The Data (and the final estimates) are in field input$data


choice = "Applied" #"Applied" "None"  
input = do.call(Attention_Checks_Personality, list(input_init, choice)) 

choice = "None" # "None"     "Excluded"
input = do.call(Outliers_Personality, list(input, choice)) 

choice = "None" # "None","Age_MF","Age","AGG_Anger","BDI_Depression", "BFI_Anxiety" ,
# "BFI_OpenMindedness"       "BFI_Conscientiousness"    "BFI_Agreeableness"        "BFI_Extraversion"         "BFI_NegativeEmotionality"  "Big5_OCEAN"    
# "BFI_Extraversion" "Big5_OCAE"  
input = do.call(Covariate, list(input, choice)) 

choice = "3.29 SD" # "3.29 SD" "3.29 IQ" "2.5 SD"  "2.5 IQ"  "None"   
input = do.call(Outliers_Threshold, list(input, choice)) 

choice = "Exclude" # "Exclude" "Replace" "None"   
input = do.call(Outliers_Treatment, list(input, choice)) 

choice = "Applied" # "Applied" "None"
input = do.call(Outliers_SME, list(input, choice)) 

choice = "Applied" # "Applied" "None"
input = do.call(Outliers_EEG, list(input, choice))  

choice = "RT_ACC" #"RT_ACC" "ACC"   
input = do.call(Select_Trials_RT, list(input, choice)) 

choice = "AV" #"AV"        "trimmedAV" "Median"  
input = do.call(RT, list(input, choice)) 

choice = "Applied" # "Applied" "None"
input = do.call(Outliers_RT, list(input, choice)) 

choice = "Applied" # "Applied" "None"
input = do.call(Outliers_ACC, list(input, choice)) 

choice = "Applied" # "Applied" "None"
input = do.call(Outliers_IQ, list(input, choice)) 

choice = "Rankit" #"Rankit" "Log"    "None"  
input = do.call(Normalize, list(input, choice)) 

choice = "Centered" # "Centered" "None"  
input = do.call(Center, list(input, choice)) 

choice = "Holm" # "Holm"       "Bonferroni" "None"      
input = do.call(Determine_Significance,list(input, choice)) 
