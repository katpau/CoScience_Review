# Add Name for Saving File
TaskName = "Flanker_Conflict"


# Scores that are used without change
Scored_Subscales = c("NFC_NeedForCognition",
                     "LE_Positiv")
# Intelligence IST!

# All Subscales that are added as Covariates
Covariates_Subscales = c(
  "Gender", 
  "Age", 
  "BDI_Depression",
  "BFI_Anxiety",
  "BFI_Extraversion", 
  "BFI_OpenMindedness", 
  "BFI_Conscientiousness",
  "BFI_Agreeableness", 
  "BFI_NegativeEmotionality")


# For Handling Routine
Do_ZScores = 0
Do_PCA = 1

################
# Create Lists for different operations, which are important for specific things
PCA_Subscales = c("NFC_NeedForCognition", "ATQ_EffortfulControl", "BSCS_SelfControl" , "TIF_Intellect")
# For this Check with Corinna and ask her to send her analysis script and add condition in Common then referring to TaskName


# Merge all Scales for Indexing
Maha_Subscales = unique(c(Scored_Subscales, Covariates_Subscales, PCA_Subscales)) # For exclusions, must be non-colinear!
Allrelevant_Subscales = unique(c(Scored_Subscales, Covariates_Subscales, Maha_Subscales,
                                 PCA_Subscales, unlist(Z_Scores_Sum), unlist(Z_Scores_Average))) # For indexing


# which Factors should be kept from Factor Analysis?
FactorsToKeep = c(1,1,1,1) 
# First Number is #Factor when Cutoffs and Outliers were applied, 
# Second Number is #Factor when Cutoffs but no Outliers were applied, 
# Third Number is #Factor when no Cutoffs but Outliers were applied, 
# Fourt Number is #Factor when no Cutoffs nor Outliers were applied


##########################################################
# check Packages
##########################################################
list.of.packages <- c("Hmisc", "psych", "stringr", "questionr", "matrixStats", "paran", "rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,  repos='http://cran.us.r-project.org')
suppress = lapply(list.of.packages, require, character.only = TRUE)
# Path of current project
Root = dirname(getSourceEditorContext()$path)


##########################################################
# Run Export
##########################################################
source(paste0(Root, "/Fork_Questionnaire_Common.R"))
