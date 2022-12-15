# Add Name for Saving File
TaskName = "Gambling_RewP"


# Scores that are used without change
Scored_Subscales = c("RSTPQ_RewardInterest", "MPQPE_PositiveEmotionality", 
                     "BISBAS_BAS", "BDI_Depression", "WHO5_Depression",
                     "PDI5_Anhedonia" )

# All Subscales that are added as Covariates
Covariates_Subscales = c(
  "Gender", 
  "Age", 
  "BFI_Anxiety",
  "BFI_OpenMindedness", 
  "BFI_Extraversion",
  "BFI_Conscientiousness",
  "BFI_Agreeableness")
# State Sadness!!


# For Handling Routine
Do_ZScores = 1
Do_PCA = 1

################
# Create Lists for different operations, which are important for specific things
PCA_Subscales = c("RSTPQ_RewardInterest", "MPQPE_PositiveEmotionality", "BISBAS_BAS") # must be non-colinear!


# Which scales should be merged as sum of z-score
Z_Scores_Sum  = vector(mode = "list", length = 0)
Z_Scores_Average  = vector(mode = "list", length = 0)


Z_Scores_Average$Depression = c("BDI_Depression", "WHO5_Depression")
Z_Scores_Average$RewardSensitivity = c("RSTPQ_RewardInterest", "MPQPE_PositiveEmotionality", "BISBAS_BAS")

Z_Scores_Sum$Depression = c("BDI_Depression", "WHO5_Depression")
Z_Scores_Sum$RewardSensitivity = c("RSTPQ_RewardInterest", "MPQPE_PositiveEmotionality", "BISBAS_BAS")




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
