## File to test Forking Path Analysis of the Statistics for Review only
## This script helps the user to run specific Steps for close following of what happens



# *******************************************************************************
## Necessary Input 1: Analysis Name to load correct Step_Functions
AnalysisName="Alpha_Context"  # <<<<============================================

# choose from
# * Alpha_Resting (Cassie)
# * Alpha_Context (Kat)
# * GoNoGo_Conflict (Andre)
# * Flanker_Conflict (Corinna)
# * Gambling_RewP (Anja)
# * Ultimatum_Offer (Jojo)
# * Gambling_N300H (Erik)
# * Error_MVPA (Elisa)

## Necessary Input 2: Which Forking path Combination should be run (row in the file Only_ForGit_To_TestRun/ForkingFiles/AnalysisName/StatFORKS.txt)
i_Fork = 16 # <<<<==================================================================

## Necessary Input 3: Path of current project
Root = dirname(rstudioapi::getSourceEditorContext()$path) # use this function or adjust here

# source input Function and prepare data to get correct file structure
source(paste0(Root, "/Troubleshooting_RDF_Stats_source.R"))



# *********************************************************************************
# For quick trouble shooting do the following 
# get the data that has been prepared above
input =  Prepared_input

## Necessary Input 3: Which Step do you want to Test?
Step_To_Test = "Determine_Significance"  # <<<<==============================================
idx_Step_To_Test = which(Step_Names == Step_To_Test)-1

# Run all Steps before that Step
for (iStep in Step_Names[1:idx_Step_To_Test]) {
  print(iStep)
  choice = as.character(FORKS[i_Fork, iStep])
  input = do.call(iStep, list(input, choice))
  print(colnames(input$data)[grepl("Gender", colnames(input$data))])
  print(ncol(input$data))
}

# Get choice of the Step you want to test
choice = as.character(FORKS[i_Fork, Step_To_Test])

# After this, you can go into the relevant Step Function and run the code 
# directly there
# do not forget the first line of the Stepfunction:
    output = input$data

# or Run it like this:
do.call(Step_To_Test, list(input, choice))

